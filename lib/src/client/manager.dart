import 'dart:async';
import 'dart:collection';

import 'package:engine_io_client/engine_io_client.dart' as eng;
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/src/backoff/backoff.dart';
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/client/socket_io_error.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/models/packet_type.dart';
import 'package:socket_io_client/src/parser/io_parser.dart';

class Manager extends eng.Emitter {
  static const String eventOpen = 'open';
  static const String eventClose = 'close';
  static const String eventPacket = 'packet';
  static const String eventError = 'error';
  static const String eventConnectError = 'connect_error';
  static const String eventConnectTimeout = 'connect_timeout';
  static const String eventReconnect = 'reconnect';
  static const String eventReconnectError = 'reconnect_error';
  static const String eventReconnectFailed = 'reconnect_failed';
  static const String eventReconnectAttempt = 'reconnect_attempt';
  static const String eventReconnecting = 'reconnecting';
  static const String eventPing = 'ping';
  static const String eventPong = 'pong';
  static const String eventTransport = 'transport';

  static const String stateClosed = 'closed';
  static const String stateOpening = 'opening';
  static const String stateOpen = 'open';

  static final eng.Log log = new eng.Log('SocketIo.Manager');

  Map<String, Socket> namespaces = <String, Socket>{};
  HashSet<Socket> connecting = new HashSet<Socket>();

  final StreamController<Packet> _packetEncoderStream = new StreamController<Packet>.broadcast();
  final StreamController<eng.Event> _timeoutStream = new StreamController<eng.Event>.broadcast();

  StreamSubscription<eng.Event> _packetEncoderSubscription;
  StreamSubscription<eng.Event> _timeoutSubscription;

  eng.Socket engine;

  ManagerOptions options;
  Backoff backoff;
  String readyState;
  Uri url;
  bool encoding;
  IoEncoder encoder;
  IoDecoder decoder;

  bool _reconnecting = false;
  bool _skipReconnect;
  int _reconnectionDelay = 0;
  int _reconnectionDelayMax = 0;
  double _randomizationFactor = 0.0;
  int timeout;

  DateTime _lastPing;

  Manager({@required String url, this.options = const ManagerOptions()}) : assert(url != null) {
    encoder = options.encoder ?? new IoEncoder();
    decoder = options.decoder ?? new IoDecoder();

    timeout = options.timeout;
    reconnectionDelay = options.reconnectionDelay;
    reconnectionDelayMax = options.reconnectionDelayMax;
    randomizationFactor = options.randomizationFactor;

    backoff = new Backoff()
      ..ms = _reconnectionDelay
      ..max = _reconnectionDelayMax
      ..jitter = _randomizationFactor;

    readyState = Manager.stateClosed;
    this.url = Uri.parse(url);
    encoding = false;
  }

  Observable<eng.Event> get buffer$ => new Observable<Packet>(_packetEncoderStream.stream)
      .bufferTest((Packet packet) => !encoding)
      .expand((_) => _)
      .map((Packet packet) => encoder.encode(packet))
      .doOnData((_) => encoding = false)
      .expand<dynamic>((List<dynamic> values) => values)
      .flatMap((dynamic value) => engine.write$(value));

  double get randomizationFactor => _randomizationFactor;

  set randomizationFactor(double value) {
    _randomizationFactor = value;
    backoff?.jitter = value;
  }

  int get reconnectionDelayMax => _reconnectionDelayMax;

  set reconnectionDelayMax(int value) {
    _reconnectionDelayMax = value;
    backoff?.max = value;
  }

  int get reconnectionDelay => _reconnectionDelay;

  set reconnectionDelay(int value) {
    _reconnectionDelay = value;
    backoff?.ms = value;
  }

  void _emitAll(String event, [List<dynamic> args]) {
    emit(event, args);
    namespaces.values.forEach((Socket socket) => socket.emit(event, args));
  }

  ///Update `socket.id` of all sockets
  void _updateSocketIds() => namespaces.forEach((String key, Socket socket) => socket.id = generateId(key));

  String generateId(String namespace) {
    final String nsp = namespace == '/' ? '' : '$namespace#';
    return '$nsp${engine.id}';
  }

  void maybeReconnectOnOpen() {
    // Only try to reconnect if it's the first time we're connecting
    if (!_reconnecting && options.reconnection && backoff.attempts == 0) reconnect();
  }

  void open() {
    log.d('readyState $readyState');

    if (readyState == Manager.stateOpen || readyState == Manager.stateOpening) return;

    log.d('opening $url');
    engine = new eng.Socket(new eng.SocketOptions.fromUri(url, options));

    readyState = Manager.stateOpening;
    _skipReconnect = false;

    decoder.onDecoded(onDecoded);
    engine.on(eng.Socket.eventData).listen((eng.Event event) => decoder.add(event.args[0]));
    engine.on(eng.Socket.eventTransport).listen((eng.Event event) => emit(Manager.eventTransport, event.args));
    engine.on(eng.Socket.eventOpen).doOnData((eng.Event event) => log.d('openSub')).listen((eng.Event event) => _onOpen());
    engine.on(eng.Socket.eventError).doOnData((eng.Event event) => log.d('connect_error')).listen(connectError);

    engine.open();
    log.d('engine state: ${engine.readyState}');
  }

  void connectTimeout() {
    engine.off(eng.Socket.eventOpen);
    engine.close();
    engine.emit(eng.Socket.eventError, <Error>[new SocketIOError('timeout')]);
    _emitAll(Manager.eventConnectTimeout, <int>[timeout]);
  }

  void connectError(eng.Event event) {
    //cleanUp();
    readyState = Manager.stateClosed;
    _emitAll(Manager.eventConnectError, event.args);
    maybeReconnectOnOpen();
  }

  void _onOpen() {
    log.d('_onOpen');

    //cleanUp();
    readyState = Manager.stateOpen;
    emit(Manager.eventOpen);

    engine.on(eng.Socket.eventPing).listen((eng.Event event) => onPing());
    engine.on(eng.Socket.eventPong).listen((eng.Event event) => onPong());
    engine.on(eng.Socket.eventError).listen((eng.Event event) => onError(event.args));
    engine.on(eng.Socket.eventClose).listen((eng.Event event) => onClose(event.args));

    decoder.onDecoded(onDecoded);
    _packetEncoderSubscription ??= buffer$.listen(null);

    if (timeout >= 0) {
      final int timeout = this.timeout;
      log.d('connection attempt will timeout after $timeout');

      _timeoutSubscription ??= new Observable<eng.Event>(_timeoutStream.stream)
          .flatMap((eng.Event event) => new Observable<eng.Event>.timer(event, new Duration(milliseconds: timeout)))
          .doOnData((eng.Event event) => log.d('connect attempt timed out after $timeout'))
          .listen((eng.Event event) => connectTimeout());
    }
  }

  void onPing() {
    _lastPing = new DateTime.now();
    _emitAll(Manager.eventPing);
  }

  void onPong() {
    _emitAll(Manager.eventPong, <int>[_lastPing != null ? new DateTime.now().difference(_lastPing).inMilliseconds : 0]);
  }

  void onDecoded(Packet packet) => emit(Manager.eventPacket, <Packet>[packet]);

  void onError(List<dynamic> args) {
    log.d('onError');
    _emitAll(Manager.eventError, args);
  }

  /// Initializes [Socket] instances for each namespaces.
  ///
  /// return a [Socket] instance for the namespace.
  Socket socket(final String namespace, [ManagerOptions opts]) {
    log.d('socket namespace: $namespace');
    Socket socket = namespaces[namespace];
    if (socket == null) {
      socket = new Socket(this, namespace, opts);
      namespaces[namespace] = socket;

      socket.on(Socket.eventConnecting).listen((eng.Event event) {
        log.d('connecting: ${event.args}');
        connecting.add(socket);
      });

      socket.on(Socket.eventConnect).listen((eng.Event event) {
        log.d('connect: ${event.args}');
        socket.id = generateId(namespace);
        log.d('socketId: ${socket.id}');
      });
    }
    return socket;
  }

  void destroy(Socket socket) {
    connecting.remove(socket);
    if (connecting.isNotEmpty) return;
    close();
  }

  void packet(Packet packet) {
    log.d('writing packet $packet');
    if (packet.query != null && packet.query.isNotEmpty && packet.type == PacketType.connect) {
      packet = packet.copyWith(namespace: '${packet.namespace}?${packet.query}');
    }

    _packetEncoderStream.add(packet);
  }

  void cleanUp() {
    log.d('cleanup');
    engine.off();
    _timeoutSubscription?.cancel();
    _timeoutSubscription = null;
    _packetEncoderSubscription?.cancel();
    _packetEncoderSubscription = null;

    decoder.onDecoded(null);

    encoding = false;
    _lastPing = null;
    decoder.destroy();
  }

  void close() {
    log.d('close');
    _skipReconnect = true;
    _reconnecting = false;
    // [onClose] will not fire because an open event never happened
    if (readyState != Manager.stateOpen) cleanUp();

    backoff.reset();
    readyState = Manager.stateClosed;
    engine?.close();
  }

  void onClose(List<dynamic> reason) {
    log.d('onClose');
    cleanUp();
    backoff.reset();
    readyState = Manager.stateClosed;
    emit(Manager.eventClose, reason);

    if (options.reconnection && !_skipReconnect) reconnect();
  }

  void reconnect() {
    if (_reconnecting || _skipReconnect) return;

    if (backoff.attempts >= options.reconnectionAttempts) {
      log.d('reconnect failed');
      backoff.reset();
      _emitAll(Manager.eventReconnectFailed);
      _reconnecting = false;
    } else {
      final int delay = backoff.duration();
      log.d('Will wait $delay before attempt to reconnect.');

      _reconnecting = true;
      new Observable<int>.timer(delay, new Duration(milliseconds: delay))
          .where((int _) => !_skipReconnect)
          .doOnData((int _) => log.d('attempting reconnect'))
          .flatMap((int i) {
        final int attempts = backoff.attempts;
        _emitAll(Manager.eventReconnectAttempt, <int>[attempts]);
        _emitAll(Manager.eventReconnecting, <int>[attempts]);

        final Observable<eng.Event> openOnce = engine.once(eng.Socket.eventOpen);
        open();
        return openOnce;
      }).listen((eng.Event event) {
        if (event.args != null) {
          log.d('reconnect attempt error');
          _reconnecting = false;
          reconnect();
          _emitAll(Manager.eventReconnectError, event.args);
        } else {
          log.d('reconnect success');
          onReconnect();
        }
      });
    }
  }

  void onReconnect() {
    log.d('onReconnect');
    final int attempts = backoff.attempts;
    _reconnecting = false;
    backoff.reset();
    _updateSocketIds();
    _emitAll(Manager.eventReconnect, <int>[attempts]);
  }

  @override
  String toString() {
    return (new eng.ToStringHelper('Manager')
          ..add('namespaces', '$namespaces')
          ..add('connecting', '$connecting')
          ..add('_packetEncoderStream', '$_packetEncoderStream')
          ..add('_timeoutStream', '$_timeoutStream')
          ..add('_packetEncoderSubscription', '$_packetEncoderSubscription')
          ..add('_timeoutSubscription', '$_timeoutSubscription')
          ..add('engine', '$engine')
          ..add('options', '$options')
          ..add('backoff', '$backoff')
          ..add('url', '$url')
          ..add('encoding', '$encoding')
          ..add('encoder', '$encoder')
          ..add('decoder', '$decoder')
          ..add('_reconnecting', '$_reconnecting')
          ..add('_skipReconnect', '$_skipReconnect')
          ..add('_reconnectionDelay', '$_reconnectionDelay')
          ..add('_reconnectionDelayMax', '$_reconnectionDelayMax')
          ..add('_randomizationFactor', '$_randomizationFactor')
          ..add('timeout', '$timeout')
          ..add('_lastPing', '$_lastPing'))
        .toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Manager &&
          runtimeType == other.runtimeType &&
          namespaces == other.namespaces &&
          connecting == other.connecting &&
          _packetEncoderStream == other._packetEncoderStream &&
          _timeoutStream == other._timeoutStream &&
          _packetEncoderSubscription == other._packetEncoderSubscription &&
          _timeoutSubscription == other._timeoutSubscription &&
          engine == other.engine &&
          options == other.options &&
          backoff == other.backoff &&
          readyState == other.readyState &&
          url == other.url &&
          encoding == other.encoding &&
          encoder == other.encoder &&
          decoder == other.decoder &&
          _reconnecting == other._reconnecting &&
          _skipReconnect == other._skipReconnect &&
          _reconnectionDelay == other._reconnectionDelay &&
          _reconnectionDelayMax == other._reconnectionDelayMax &&
          _randomizationFactor == other._randomizationFactor &&
          timeout == other.timeout &&
          _lastPing == other._lastPing;

  @override
  int get hashCode =>
      namespaces.hashCode ^
      connecting.hashCode ^
      _packetEncoderStream.hashCode ^
      _timeoutStream.hashCode ^
      _packetEncoderSubscription.hashCode ^
      _timeoutSubscription.hashCode ^
      engine.hashCode ^
      options.hashCode ^
      backoff.hashCode ^
      readyState.hashCode ^
      url.hashCode ^
      encoding.hashCode ^
      encoder.hashCode ^
      decoder.hashCode ^
      _reconnecting.hashCode ^
      _skipReconnect.hashCode ^
      _reconnectionDelay.hashCode ^
      _reconnectionDelayMax.hashCode ^
      _randomizationFactor.hashCode ^
      timeout.hashCode ^
      _lastPing.hashCode;
}

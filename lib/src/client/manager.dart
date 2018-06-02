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

  StreamSubscription<eng.Event> _packetEncoderSubscription;
  StreamSubscription<eng.Event> _timeoutSubscription;

  String readyState;

  bool reconnection;
  bool _reconnecting = false;
  bool _skipReconnect;
  bool _encoding;

  int reconnectionAttempts = 0;
  int _reconnectionDelay = 0;
  int _reconnectionDelayMax = 0;
  double _randomizationFactor = 0.0;
  Backoff backoff;
  int timeout;
  DateTime _lastPing;
  Uri _url;
  ManagerOptions options;
  eng.Socket engine;

  IoEncoder encoder;
  IoDecoder decoder;

  Manager({@required String url, this.options = const ManagerOptions()}) : assert(url != null) {
    encoder = options.encoder ?? new IoEncoder();
    decoder = options.decoder ?? new IoDecoder();

    timeout = options.timeout;
    reconnection = options.reconnection;
    log.w('reconnection is $reconnection');
    reconnectionAttempts = options.reconnectionAttempts;
    reconnectionDelay = options.reconnectionDelay;
    reconnectionDelayMax = options.reconnectionDelayMax;
    randomizationFactor = options.randomizationFactor;

    backoff = new Backoff()
      ..ms = _reconnectionDelay
      ..max = _reconnectionDelayMax
      ..jitter = _randomizationFactor;

    readyState = Manager.stateClosed;
    _url = Uri.parse(url);
    _encoding = false;
  }

  void _emitAll(String event, [List<dynamic> args]) {
    emit(event, args);
    namespaces.values.forEach((Socket socket) => socket.emit(event, args));
  }

  ///Update `socket.id` of all sockets
  void _updateSocketIds() => namespaces.forEach((String key, Socket socket) => socket.id = _generateId(key));

  String _generateId(String namespace) {
    final String nsp = namespace == '/' ? '' : '$namespace#';
    return '$nsp${engine.id}';
  }

  Observable<eng.Event> get buffer$ => new Observable<Packet>(_packetEncoderStream.stream)
      .map((Packet packet) => encoder.encode(packet))
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

  void maybeReconnectOnOpen() {
    log.d('maybeReconnectOnOpen');
    // Only try to reconnect if it's the first time we're connecting
    if (!_reconnecting && reconnection && backoff.attempts == 0) reconnect();
  }

  Observable<eng.Event> open([bool handleOnError = false]) {
    log.d('readyState: $readyState');

    if (readyState == Manager.stateOpen || readyState == Manager.stateOpening) {
      return new Observable<eng.Event>.just(new eng.Event(eng.Socket.eventOpen));
    }

    log.d('opening $_url');
    engine = new eng.Socket(new eng.SocketOptions.fromUri(_url, options));

    readyState = Manager.stateOpening;
    _skipReconnect = false;

    decoder.onDecoded(onDecoded);
    engine.on(eng.Socket.eventData).listen((eng.Event event) => decoder.add(event.args[0]));
    engine.on(eng.Socket.eventTransport).listen((eng.Event event) => emit(Manager.eventTransport, event.args));
    engine.on(eng.Socket.eventOpen).listen((eng.Event event) => _onOpen());
    engine.on(eng.Socket.eventError).listen((eng.Event event) {
      //cleanUp();
      log.d('connect_error');
      log.d('isListened: $handleOnError');
      readyState = Manager.stateClosed;
      _emitAll(Manager.eventConnectError, event.args);

      if (!handleOnError) {
        // Only do this if there is no one to handle the error
        maybeReconnectOnOpen();
      }
    });

    if (timeout >= 0) {
      final int timeout = this.timeout;
      log.d('connection attempt will timeout after $timeout');

      _timeoutSubscription?.cancel();
      _timeoutSubscription = new Observable<eng.Event>.race(<Observable<eng.Event>>[
        engine.once(eng.Socket.eventOpen),
        new Observable<eng.Event>.timer(new eng.Event(''), new Duration(milliseconds: timeout))
            .doOnData((eng.Event event) => log.d('connect attempt timed out after $timeout'))
            .doOnData((eng.Event event) => connectTimeout()),
      ]).listen(null);
    }

    engine.open();
    log.d('engine state: ${engine.readyState}');

    return handleOnError
        ? engine.once(eng.Socket.eventOpen).mergeWith(<Observable<eng.Event>>[engine.once(eng.Socket.eventError)])
        : engine.once(eng.Socket.eventOpen);
  }

  void connectTimeout() {
    log.d('connectTimeout called');
    engine.off(eng.Socket.eventOpen);
    engine.close();
    engine.once(eng.Socket.eventClose).listen((eng.Event event) {
      engine.emit(eng.Socket.eventError, <Error>[new SocketIOError('timeout')]);
      _emitAll(Manager.eventConnectTimeout, <int>[timeout]);
    });
  }

  void _onOpen() {
    log.d('_onOpen');

    readyState = Manager.stateOpen;
    emit(Manager.eventOpen);

    engine.on(eng.Socket.eventPing).listen((eng.Event event) => onPing());
    engine.on(eng.Socket.eventPong).listen((eng.Event event) => onPong());
    engine.on(eng.Socket.eventError).listen((eng.Event event) => onError(event.args));
    engine.on(eng.Socket.eventClose).listen((eng.Event event) => onClose(event.args));

    _packetEncoderSubscription ??= buffer$.listen(null);
  }

  void onPing() {
    _lastPing = new DateTime.now();
    _emitAll(Manager.eventPing);
  }

  void onPong() {
    _emitAll(Manager.eventPong, <int>[_lastPing != null ? new DateTime.now().difference(_lastPing).inMilliseconds : 0]);
  }

  void onDecoded(Packet packet) {
    log.d('onDecoded called with: packet:[$packet]');
    emit(Manager.eventPacket, <Packet>[packet]);
  }

  void onError(List<dynamic> args) {
    log.d('onError');
    _emitAll(Manager.eventError, args);
  }

  /// Initializes [Socket] instances for each namespaces and returns a [Socket] instance for the namespace.
  Socket socket(final String namespace, [ManagerOptions opts]) {
    log.d('socket namespace: $namespace');
    Socket socket = namespaces[namespace];
    if (socket == null) {
      socket = new Socket(this, namespace, opts);
      namespaces[namespace] = socket;

      /*
      We do this in [Socket._connecting] because we don't have time to wait for this to happen
      socket.on(Socket.eventConnecting).listen((eng.Event event) {
        log.d('eventConnecting for ${socket.namespace}');
        connecting.add(socket);
      });
      */

      socket.on(Socket.eventConnect).listen((eng.Event event) {
        socket.id = _generateId(namespace);
        log.d('socketId: ${socket.id}');
      });
    }
    return socket;
  }

  void destroy(Socket socket) {
    connecting.remove(socket);
    log.d('connecting: ${connecting.length}');
    if (connecting.isNotEmpty) {
      return;
    }
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

    _encoding = false;
    _lastPing = null;
    decoder.destroy();
  }

  void close() {
    log.d('close');
    _skipReconnect = true;
    _reconnecting = false;
    // [onClose] will not fire because an open event never happened
    if (readyState != Manager.stateOpen) {
      //cleanUp();
    }

    backoff.reset();
    readyState = Manager.stateClosed;
    engine?.close();
  }

  void onClose(List<dynamic> reason) {
    log.d('onClose');
    //cleanUp();
    backoff.reset();
    readyState = Manager.stateClosed;
    emit(Manager.eventClose, reason);

    if (options.reconnection && !_skipReconnect) reconnect();
  }

  void reconnect() {
    log.d('reconnect');
    if (_reconnecting || _skipReconnect) return;

    if (backoff.attempts >= options.reconnectionAttempts) {
      log.d('reconnect failed');
      backoff.reset();
      _emitAll(Manager.eventReconnectFailed, <int>[backoff.attempts]);
      _reconnecting = false;
    } else {
      final int delay = backoff.duration();
      log.d('Will wait $delay before attempt to reconnect.');

      _reconnecting = true;
      new Observable<int>.timer(delay, new Duration(milliseconds: delay))
          .doOnData((int _) => log.d('skipReconnect: $_skipReconnect'))
          .where((int _) => !_skipReconnect)
          .doOnData((int _) => log.d('attempting reconnect'))
          .switchMap((int i) {
        final int attempts = backoff.attempts;
        _emitAll(Manager.eventReconnectAttempt, <int>[attempts]);
        _emitAll(Manager.eventReconnecting, <int>[attempts]);

        return open(true);
      }).listen((eng.Event event) {
        log.d('reconnect called $event');

        if (event.name == eng.Socket.eventOpen) {
          log.d('reconnect success');
          onReconnect();
        } else if (event.name == eng.Socket.eventError) {
          log.d('reconnect attempt error');
          _reconnecting = false;
          reconnect();
          _emitAll(Manager.eventReconnectError, event.args);
        } else
          // ignore: only_throw_errors
          throw 'open mited a diffrent event $event';
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
          ..add('engine', '$engine')
          ..add('options', '$options')
          ..add('backoff', '$backoff')
          ..add('url', '$_url')
          ..add('encoding', '$_encoding')
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
          engine == other.engine &&
          options == other.options &&
          backoff == other.backoff &&
          readyState == other.readyState &&
          _url == other._url &&
          _encoding == other._encoding &&
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
      engine.hashCode ^
      options.hashCode ^
      backoff.hashCode ^
      readyState.hashCode ^
      _url.hashCode ^
      _encoding.hashCode ^
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

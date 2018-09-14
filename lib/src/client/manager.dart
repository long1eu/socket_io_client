import 'dart:async';
import 'dart:collection';

import 'package:engine_io_client/engine_io_client.dart' as eng;
import 'package:meta/meta.dart';
import 'package:socket_io_client/src/backoff/backoff.dart';
import 'package:socket_io_client/src/client/on.dart';
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/client/socket_io_exception.dart';
import 'package:socket_io_client/src/models/manager_event.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:socket_io_client/src/models/manager_state.dart';
import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/models/packet_type.dart';
import 'package:socket_io_client/src/models/socket_event.dart';
import 'package:socket_io_client/src/parser/io_parser.dart';

class Manager extends eng.Emitter {
  static final eng.Log log = new eng.Log('Manager');
  Map<String, Socket> namespaces = <String, Socket>{};
  HashSet<Socket> connecting = new HashSet<Socket>();
  List<OnDestroy> subscriptions = <OnDestroy>[];

  eng.Socket engine;

  final ManagerOptions options;
  Backoff backoff;
  ManagerState readyState;
  Uri url;
  bool encoding;
  List<Packet> packetBuffer;
  IoEncoder encoder;
  IoDecoder decoder;
  bool _reconnection;
  bool _reconnecting = false;
  bool _skipReconnect;
  int reconnectionAttempts;
  int _reconnectionDelay = 0;
  int _reconnectionDelayMax = 0;
  double _randomizationFactor = 0.0;
  int timeout;

  DateTime _lastPing;

  Manager({@required String url, this.options = const ManagerOptions()}) : assert(url != null) {
    _reconnection = options.reconnection;
    reconnectionAttempts = options.reconnectionAttempts;
    reconnectionDelay = options.reconnectionDelay;
    reconnectionDelayMax = options.reconnectionDelayMax;
    randomizationFactor = options.randomizationFactor;

    backoff = new Backoff()
      ..ms = _reconnectionDelay
      ..max = _reconnectionDelayMax
      ..jitter = _randomizationFactor;

    timeout = options.timeout;
    readyState = ManagerState.closed;
    this.url = Uri.parse(url);
    encoding = false;
    packetBuffer = <Packet>[];
    encoder = options.encoder != null ? options.encoder : new IoEncoder();
    decoder = options.decoder != null ? options.decoder : new IoDecoder();
  }

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

  Future<void> _emitAll(String event, [List<dynamic> args]) async {
    await emit(event, args);
    for (String key in namespaces.keys) await namespaces[key].emit(event, args);
  }

  ///Update `socket.id` of all sockets
  void _updateSocketIds() => namespaces.forEach((String key, Socket socket) => socket.id = generateId(key));

  String generateId(String namespace) {
    final String nsp = namespace == '/' ? '' : '$namespace#';
    return '$nsp${engine.id}';
  }

  Future<void> maybeReconnectOnOpen() async {
    // Only try to reconnect if it's the first time we're connecting
    if (!_reconnecting && _reconnection && backoff.attempts == 0) await reconnect();
  }

  Future<Manager> open({eng.Listener listener}) async {
    log.d('readyState $readyState');

    if (readyState == ManagerState.open || readyState == ManagerState.opening) return this;

    log.d('opening $url');
    engine = new eng.Socket(new eng.SocketOptions.fromUri(url, options));

    readyState = ManagerState.opening;
    _skipReconnect = false;

    // propagate transport event.
    engine.on(eng.SocketEvent.transport, (List<dynamic> args) async => await emit(ManagerEvent.transport, args));

    final On openSub = new On(engine, eng.SocketEvent.open, (List<dynamic> args) async {
      log.d('openSub');
      await _onOpen();
      if (listener != null) await listener(null);
    });

    final On errorSub = new On(engine, eng.SocketEvent.error, (List<dynamic> objects) async {
      log.d('connect_error');
      cleanUp();
      readyState = ManagerState.closed;
      await _emitAll(ManagerEvent.connectError, objects);
      if (listener != null) {
        await listener(<Error>[new SocketIOException('Connection error', objects is Error ? objects : null)]);
      } else {
        // Only do this if there is no fn to handle the error
        await maybeReconnectOnOpen();
      }
    });

    if (timeout >= 0) {
      final int timeout = this.timeout;
      log.d('connection attempt will timeout after $timeout');

      final Timer timer = new Timer(new Duration(milliseconds: timeout), () async {
        log.d('connect attempt timed out after $timeout');
        openSub.destroy();
        engine.close();
        await engine.emit(eng.SocketEvent.error, <Error>[new SocketIOException('timeout')]);
        await _emitAll(ManagerEvent.connectTimeout, <int>[timeout]);
      });

      subscriptions.add(() {
        timer.cancel();
        return true;
      });
    }

    decoder.onDecoded(onDecoded);
    subscriptions
      ..add(openSub.destroy)
      ..add(errorSub.destroy)
      ..add(new On(engine, eng.SocketEvent.data, (List<dynamic> args) async => decoder.add(args[0])).destroy);

    engine.open();

    log.d('engine state: ${engine.readyState}');
    return this;
  }

  Future<void> _onOpen() async {
    log.d('_onOpen');

    cleanUp();
    readyState = ManagerState.open;
    await emit(ManagerEvent.open);
    log.d('readyState: $readyState');

    subscriptions
      ..add(new On(engine, eng.SocketEvent.ping, (List<dynamic> args) async => await onPing(args)).destroy)
      ..add(new On(engine, eng.SocketEvent.pong, (List<dynamic> args) async => await onPong(args)).destroy)
      ..add(new On(engine, eng.SocketEvent.error, (List<dynamic> args) async => await onError(args)).destroy)
      ..add(new On(engine, eng.SocketEvent.close, (List<dynamic> args) async => await onClose(args)).destroy)
      ..add(new On(engine, eng.SocketEvent.data, (List<dynamic> args) {
        log.d('data $args');
        decoder.add(args[0]);
      }).destroy);
    decoder.onDecoded(onDecoded);
  }

  Future<void> onPing(List<dynamic> _) async {
    _lastPing = new DateTime.now();
    await _emitAll(ManagerEvent.ping);
  }

  Future<void> onPong(List<dynamic> _) async {
    await _emitAll(ManagerEvent.pong, <int>[_lastPing != null ? new DateTime.now().difference(_lastPing).inMilliseconds : 0]);
  }

  Future<void> onDecoded(Packet packet) async => await emit(ManagerEvent.packet, <Packet>[packet]);

  Future<void> onError(List<dynamic> args) async {
    log.d('error');
    await _emitAll(ManagerEvent.error, args);
    try {
      throw args[0];
    } catch (e) {
      print(StackTrace.current.toString());
    }
  }

  /// Initializes [Socket] instances for each namespaces.
  ///
  /// @return a socket instance for the namespace.
  Socket socket(final String namespace, [ManagerOptions opts]) {
    log.d('socket namespace: $namespace');
    Socket socket = namespaces[namespace];
    if (socket == null) {
      socket = new Socket(this, namespace, opts);
      namespaces[namespace] = socket;

      socket
        ..on(SocketEvent.connecting, (List<dynamic> args) {
          log.d('connecting: $args');
          connecting.add(socket);
        })
        ..on(SocketEvent.connect, (List<dynamic> args) {
          log.d('connect: $args');
          socket.id = generateId(namespace);
          log.d('socketId: ${socket.id}');
        });
    }
    return socket;
  }

  Future<void> destroy(Socket socket) async {
    connecting.remove(socket);
    if (connecting.isNotEmpty) return;
    await close();
  }

  Future<void> packet(Packet packet) async {
    log.d('writing packet $packet');

    if (packet.query != null && packet.query.isNotEmpty && packet.type == PacketType.connect) {
      packet = packet.copyWith(namespace: '${packet.namespace}?${packet.query}');
    }

    log.d('writing packet $packet');

    if (!encoding) {
      encoding = true;
      for (dynamic value in encoder.encode(packet)) {
        await engine.write(value);
      }
      encoding = false;
      await _processPacketQueue();
    } else {
      packetBuffer.add(packet);
    }
  }

  Future<void> _processPacketQueue() async {
    log.d('packetBuffer: $packetBuffer');
    if (packetBuffer.isNotEmpty && !encoding) {
      await packet(packetBuffer.removeAt(0));
    }
  }

  void cleanUp() {
    log.d('cleanup');

    subscriptions.removeWhere((OnDestroy onDestroy) => onDestroy());
    decoder.onDecoded(null);
    packetBuffer.clear();
    encoding = false;
    _lastPing = null;
    decoder.destroy();
  }

  Future<void> close() async {
    log.d('disconnect');
    _skipReconnect = true;
    _reconnecting = false;
    // [onClose] will not fire because an open event never happened
    if (readyState != ManagerState.open) cleanUp();

    backoff.reset();
    readyState = ManagerState.closed;
    engine?.close();
  }

  Future<void> onClose(List<dynamic> reason) async {
    log.d('onClose');
    cleanUp();
    backoff.reset();
    readyState = ManagerState.closed;
    await emit(ManagerEvent.close, reason);

    if (_reconnection && !_skipReconnect) await reconnect();
  }

  Future<void> reconnect() async {
    if (_reconnecting || _skipReconnect) return;

    if (backoff.attempts >= reconnectionAttempts) {
      log.d('reconnect failed');
      backoff.reset();
      await _emitAll(ManagerEvent.reconnectFailed);
      _reconnecting = false;
    } else {
      final int delay = backoff.duration();
      log.d('will wait $delay before reconnect attempt');

      _reconnecting = true;
      final Timer timer = new Timer(new Duration(milliseconds: delay), () async {
        if (_skipReconnect) return;

        log.d('attempting reconnect');
        final int attempts = backoff.attempts;
        await _emitAll(ManagerEvent.reconnectAttempt, <int>[attempts]);
        await _emitAll(ManagerEvent.reconnecting, <int>[attempts]);

        // check again for the case socket closed in above events
        if (_skipReconnect) return;

        await open(listener: (List<dynamic> err) async {
          if (err != null) {
            log.d('reconnect attempt error');
            _reconnecting = false;
            await reconnect();
            await _emitAll(ManagerEvent.reconnectError, err);
          } else {
            log.d('reconnect success');
            await onReconnect();
          }
        });
      });

      subscriptions.add(() {
        timer.cancel();
        return true;
      });
    }
  }

  Future<void> onReconnect() async {
    final int attempts = backoff.attempts;
    _reconnecting = false;
    backoff.reset();
    _updateSocketIds();
    await _emitAll(ManagerEvent.reconnect, <int>[attempts]);
  }
}

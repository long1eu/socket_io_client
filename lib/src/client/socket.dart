import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart' as eng;
import 'package:engine_io_client/src/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/src/client/manager.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/models/packet_type.dart';

typedef void Ack([List<dynamic> args]);

class Socket extends eng.Emitter {
  static const String eventConnect = 'connect';
  static const String eventConnecting = 'connecting';
  static const String eventDisconnect = 'disconnect';
  static const String eventError = 'error';
  static const String eventMessage = 'message';
  static const String eventConnectError = Manager.eventConnectError;
  static const String eventConnectTimeout = Manager.eventConnectTimeout;
  static const String eventReconnect = Manager.eventReconnect;
  static const String eventReconnectError = Manager.eventReconnectError;
  static const String eventReconnectFailed = Manager.eventReconnectFailed;
  static const String eventReconnectAttempt = Manager.eventReconnectAttempt;
  static const String eventReconnecting = Manager.eventReconnecting;
  static const String eventPing = Manager.eventPing;
  static const String eventPong = Manager.eventPong;

  static const List<String> eventValues = const <String>[
    eventConnect,
    eventConnecting,
    eventDisconnect,
    eventError,
    eventMessage,
    eventConnectError,
    eventConnectTimeout,
    eventReconnect,
    eventReconnectError,
    eventReconnectFailed,
    eventReconnectAttempt,
    eventReconnecting,
    eventPing,
    eventPong
  ];

  static final Log log = new Log('SocketIo.Socket');

  final StreamController<List<dynamic>> _receiveController = new StreamController<List<dynamic>>.broadcast();
  final StreamController<Packet> _sendController = new StreamController<Packet>.broadcast();

  StreamSubscription<void> _receiveSub;
  StreamSubscription<void> _sendSub;

  /// A property on the socket instance that is equal to the underlying engine.io socket id.
  ///
  /// The value is present once the socket has connected, is removed when the socket disconnects
  /// and is updated if the socket reconnects.
  String id;

  bool connected = false;
  int ids = 0;
  String namespace;
  Manager io;
  String query;
  Map<int, StreamController<List<dynamic>>> acks = <int, StreamController<List<dynamic>>>{};

  Socket(this.io, this.namespace, ManagerOptions opts) : query = opts?.rawQuery;

  Observable<void> get _send$ => new Observable<Packet>(_sendController.stream)
      .bufferTest((Packet _) => connected)
      .expand((_) => _)
      .forEach((Packet p) => packet(p))
      .asObservable();

  Observable<void> get _receive$ => new Observable<List<dynamic>>(_receiveController.stream)
      .where((List<dynamic> args) => args.isNotEmpty)
      .bufferTest((List<dynamic> _) => connected)
      .expand((_) => _)
      .forEach((List<dynamic> args) => super.emit(args[0], args.sublist(1)))
      .asObservable();

  /// Connects the socket.
  void open() {
    log.d('open: $connected');
    if (connected) return;

    io.on(Manager.eventOpen).listen((eng.Event event) => onOpen());
    io.on(Manager.eventPacket).listen((eng.Event event) => onPacket(event.args[0]));
    io.on(Manager.eventClose).listen((eng.Event event) => onClose(event.args.isEmpty ? null : event.args[0]));

    if (io.readyState == Manager.stateOpen || io.readyState == Manager.stateOpening) {
      _connecting();
    } else {
      io.open().where((eng.Event event) => event.name == eng.Socket.eventOpen).listen((eng.Event event) => _connecting());
    }
  }

  void _connecting() {
    log.d('socket $namespace is open, manager state is ${io.readyState}');
    io.connecting.add(this);
    emit(Socket.eventConnecting);
    if (io.readyState == Manager.stateOpen) {
      onOpen();
    }
  }

  /// Connects the socket.
  void connect() => open();

  /// Send messages.
  ///
  /// [args] data to send;
  /// return a reference of this object.
  void send(List<dynamic> args) {
    log.d(connected);
    emit(Socket.eventMessage, args);
  }

  /// Emits an event with an acknowledge.
  ///
  /// [event] the name if the event
  /// [args] data to be sent
  /// returns a [Stream] that will receive the ack event and then close is [receiveAck] is true, else it will return an empty
  /// [Stream].
  @override
  Observable<List<dynamic>> emit(String event, [List<dynamic> args = const <dynamic>[], bool receiveAck = false]) {
    log.d('emit with: event:$event, args:$args');
    if (Socket.eventValues.contains(event)) {
      super.emit(event, args);
      return new Observable<List<dynamic>>.empty();
    }

    final List<dynamic> list = <dynamic>[event];
    if (args != null) list.addAll(args);

    Packet packet = new Packet(type: PacketType.event, data: list);

    int id;
    // ignore: close_sinks
    StreamController<List<dynamic>> streamController;
    if (receiveAck) {
      id = ids++;
      log.d('emitting packet with ack id $id');
      streamController = new StreamController<List<dynamic>>();
      acks[id] = streamController;
      packet = packet.copyWith(id: id);
    }
    log.d('emit id: $id connected: $connected packet: $packet');

    _sendController.add(packet);

    if (id != null) {
      return new Observable<List<dynamic>>(streamController.stream);
    } else {
      return new Observable<List<dynamic>>.empty();
    }
  }

  void packet(Packet packet) => io.packet(packet.copyWith(namespace: namespace));

  void onOpen() {
    log.d('transport is open - connecting');
    log.d('namespace: $namespace');

    _sendSub ??= _send$.listen(null);
    _receiveSub ??= _receive$.listen(null);

    if (namespace != '/') {
      Packet connectPacket = const Packet(type: PacketType.connect);
      if (query != null && query.isNotEmpty) connectPacket = connectPacket.copyWith(query: query);
      packet(connectPacket);
    }
  }

  void onClose(String reason) {
    log.d('close ($reason)');
    connected = false;
    id = null;
    emit(Socket.eventDisconnect, <String>[reason]);
  }

  void onPacket(Packet packet) {
    log.d('onPacket: $packet');

    if (packet.namespace != namespace) {
      return;
    }

    switch (packet.type) {
      case PacketType.connect:
        _onConnect();
        break;

      case PacketType.event:
      case PacketType.binaryEvent:
        onEvent(packet);
        break;

      case PacketType.ack:
      case PacketType.binaryAck:
        _onAck(packet);
        break;

      case PacketType.disconnect:
        log.d('Received Packet.disconnect');
        _onDisconnect();
        break;

      case PacketType.error:
        emit(Socket.eventError, <String>[packet.data]);
        break;
    }
  }

  void onEvent(Packet packet) {
    final List<dynamic> args = packet.data;
    log.d('emitting event $args');

    if (packet.id >= 0) {
      log.d('attaching ack callback to event');
      args.add(_ack(packet.id));
    }

    _receiveController.add(args);
  }

  Function _ack(int id) {
    bool sent = false;
    return ([List<dynamic> args = const <dynamic>[]]) {
      if (sent) return;
      sent = true;
      log.d('sending ack $args');

      packet(new Packet(id: id, type: PacketType.ack, data: args));
    };
  }

  void _onAck(Packet packet) {
    final StreamController<List<dynamic>> ack = acks.remove(packet.id);
    log.w('onAck: $ack');
    if (ack != null) {
      log.d('calling ack ${packet.id} with ${packet.data}/${packet.data.runtimeType}');
      ack.add(packet.data is List ? packet.data : <dynamic>[packet.data]);
      ack.close();
    } else {
      log.d('bad ack ${packet.id}');
    }
  }

  void _onConnect() {
    log.d('onConnect $namespace');
    connected = true;

    emit(Socket.eventConnect);
  }

  void _onDisconnect() {
    log.d('server disconnect ($namespace)');
    _destroy();
    onClose('io server disconnect');
  }

  void _destroy() {
    _receiveSub?.cancel();
    _receiveSub = null;
    _sendSub?.cancel();
    _sendSub = null;

    io.destroy(this);
  }

  /// Disconnects the socket.
  void close() {
    log.d('close method');
    if (connected) {
      log.d('performing disconnect ($namespace)');
      packet(const Packet(type: PacketType.disconnect));
    }
    _destroy();
    if (connected) {
      onClose('io client disconnect');
    }
  }

  /// Disconnects the socket.
  void disconnect() => close();

  @override
  String toString() {
    return (new ToStringHelper(log.tag)
          ..add('id', '$id')
          ..add('connected', '$connected')
          ..add('ids', '$ids')
          ..add('namespace', '$namespace')
          ..add('io', '$io')
          ..add('query', '$query')
          ..add('acks', '$acks'))
        .toString();
  }
}

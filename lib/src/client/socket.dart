import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart' as eng;
import 'package:socket_io_client/src/client/manager.dart';
import 'package:socket_io_client/src/client/on.dart';
import 'package:socket_io_client/src/models/manager_event.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:socket_io_client/src/models/manager_state.dart';
import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/models/packet_type.dart';
import 'package:socket_io_client/src/models/socket_event.dart';

typedef Future<Null> Ack([List<dynamic> args]);

class Socket extends eng.Emitter {
  static final eng.Log log = new eng.Log('Socket');
  final List<List<dynamic>> receiveBuffer = <List<dynamic>>[];
  final List<Packet> sendBuffer = <Packet>[];
  List<OnDestroy> subs;

  ///  A property on the socket instance that is equal to the underlying engine.io socket id.
  String id;
  bool connected = false;
  int ids = 0;
  String namespace;
  Manager io;
  String query;
  Map<int, Ack> acks = <int, Ack>{};

  Socket(this.io, this.namespace, ManagerOptions opts) : query = opts?.rawQuery;

  void subEvents() {
    if (subs != null) return;
    subs = <OnDestroy>[]
      ..add(new On(io, ManagerEvent.open, (List<dynamic> args) async => await onOpen(args)).destroy)
      ..add(new On(io, ManagerEvent.packet, (List<dynamic> args) async => await onPacket(args[0])).destroy)
      ..add(new On(io, ManagerEvent.close, (List<dynamic> args) async {
        return await onClose(args.isNotEmpty ? args[0] : null);
      }).destroy);
  }

  /// Connects the socket.
  Future<Null> open() async {
    log.d('open: $connected');
    if (connected) return;

    subEvents();
    await io.open(); // ensure open
    log.d(io.readyState);
    if (io.readyState == ManagerState.open) await onOpen(null);
    await emit(SocketEvent.connecting);
  }

  /// Connects the socket.
  Future<Socket> connect() => open();

  /// Send messages.
  ///
  /// [args] data to send;
  /// return a reference of this object.
  Future<Null> send(dynamic args) async {
    await emit(SocketEvent.message, args);
  }

  @override
  Future<Null> emit(String event, [List<dynamic> args = const <dynamic>[]]) async {
    log.d('emit called with: $event, args:$args');
    if (SocketEvent.values.contains(event)) return await super.emit(event, args);

    Ack ack;
    List<dynamic> _args;
    final int lastIndex = args.length - 1;

    if (args.isNotEmpty && args[lastIndex] is Ack) {
      _args = <dynamic>[]..length = lastIndex;
      for (int i = 0; i < lastIndex; i++) {
        _args[i] = args[i];
      }
      ack = args[lastIndex];
    } else {
      _args = args;
      ack = null;
    }

    await emitAck(event, _args, ack);
  }

  /// Emits an event with an acknowledge.
  ///
  /// [event] the name if the event
  /// [args] data to be sent
  /// return a reference of this object.
  Future<Null> emitAck(String event, List<dynamic> args, Ack ack) async {
    log.d('emitAck called with: event:$event, args:$args, ack:$ack');

    final List<dynamic> list = <dynamic>[];
    list.add(event);
    if (args != null) args.forEach(list.add);

    Packet builder = Packet(type: PacketType.event, data: list);

    if (ack != null) {
      log.d('emitting packet with ack id $ids');
      acks[ids] = ack;
      builder = builder.copyWith(id: ids++);
    }
    log.d('emitAck-Connected: $connected packet: $builder');
    if (connected) {
      await packet(builder);
    } else {
      sendBuffer.add(builder);
    }
  }

  Future<Null> packet(Packet builder) async {
    builder = builder.copyWith(namespace: namespace);
    await io.packet(builder);
  }

  Future<Null> onOpen(List<dynamic> args) async {
    log.d('transport is open - connecting $args');

    if (namespace != '/') {
      Packet builder = const Packet(type: PacketType.connect);
      if (query != null && query.isNotEmpty) {
        builder = builder.copyWith(query: query);
      }
      log.d(builder);
      await packet(builder);
    }
  }

  Future<Null> onClose(String reason) async {
    log.d('close ($reason)');
    connected = false;
    id = null;
    await emit(SocketEvent.disconnect, <String>[reason]);
  }

  Future<Null> onPacket(Packet packet) async {
    log.d('onPacket: $packet');

    if (packet.namespace != namespace) return;

    switch (packet.type) {
      case PacketType.connect:
        await onConnect();
        break;

      case PacketType.event:
      case PacketType.binaryEvent:
        await onEvent(packet);
        break;

      case PacketType.ack:
      case PacketType.binaryAck:
        await onAck(packet);
        break;

      case PacketType.disconnect:
        await onDisconnect();
        break;

      case PacketType.error:
        await emit(SocketEvent.error, <String>[packet.data]);
        break;
    }
  }

  Future<Null> onEvent(Packet packet) async {
    final List<dynamic> args = packet.data;
    log.d('emitting event $args');

    if (packet.id >= 0) {
      log.d('attaching ack callback to event');
      final Ack a = await ack(packet.id);
      args.add(a);
    }

    if (connected) {
      if (args.isEmpty) return;
      final String event = args.removeAt(0).toString();
      log.d('args: onEvent: $args');
      await super.emit(event, args);
    } else {
      receiveBuffer.add(args);
    }
  }

  Future<Ack> ack(int id) async {
    bool sent = false;
    return ([List<dynamic> args]) async {
      args ??= const <dynamic>[];
      if (sent) return;
      sent = true;
      log.d('sending ack $args');

      final List<dynamic> jsonArgs = <dynamic>[];
      jsonArgs.addAll(args);

      await packet(Packet(
        type: PacketType.ack,
        id: id,
        data: jsonArgs,
      ));
    };
  }

  Future<Null> onAck(Packet packet) async {
    final Ack ack = acks.remove(packet.id);

    if (ack != null) {
      log.d('calling ack ${packet.id} with ${packet.data}');
      await ack(packet.data);
    } else {
      log.d('bad ack ${packet.id}');
    }
  }

  Future<Null> onConnect() async {
    log.d('onConnect');
    connected = true;
    await emit(SocketEvent.connect);
    await emitBuffered();
  }

  Future<Null> emitBuffered() async {
    final List<List<dynamic>> removed = <List<dynamic>>[];
    receiveBuffer
      ..removeWhere((List<dynamic> data) {
        removed.add(data);
        return true;
      })
      ..clear();

    for (List<dynamic> data in removed) await super.emit(data[0], data);
    for (Packet packet in sendBuffer) {
      await this.packet(packet);
    }

    sendBuffer.clear();
  }

  Future<Null> onDisconnect() async {
    log.d('server disconnect ($namespace)');
    await destroy();
    await onClose('io server disconnect');
  }

  Future<Null> destroy() async {
    subs?.removeWhere((OnDestroy onDestroy) => onDestroy());
    subs = null;
    await io.destroy(this);
  }

  /// Disconnects the socket.
  Future<Null> close() async {
    if (connected) {
      log.d('performing disconnect ($namespace)');
      await packet(Packet.disconnect);
    }
    await destroy();
    if (connected) await onClose('io client disconnect');
  }

  /// Disconnects the socket.
  Future<Null> disconnect() => close();
}

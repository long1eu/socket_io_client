library packet;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:socket_io_client/src/models/packet_type.dart';

part 'packet.g.dart';

abstract class Packet implements Built<Packet, PacketBuilder> {
  factory Packet([PacketBuilder updates(PacketBuilder b)]) {
    return new _$Packet((PacketBuilder b) {
      return b
        ..id = -1
        ..type = PacketType.event
        ..update(updates);
    });
  }

  factory Packet.fromValues(PacketType type) {
    return new Packet((PacketBuilder b) {
      b..type = type;
    });
  }

  Packet._();

  PacketType get type;

  int get id;

  @nullable
  String get namespace;

  @nullable
  Object get data;

  @nullable
  int get attachments;

  @nullable
  String get query;

  static Packet parserError = new Packet((PacketBuilder b) {
    b
      ..type = PacketType.error
      ..data = 'parser error';
  });

  static Serializer<Packet> get serializer => _$packetSerializer;
}

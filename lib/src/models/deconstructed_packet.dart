library deconstructed_packet;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:socket_io_client/src/models/packet.dart';

part 'deconstructed_packet.g.dart';

abstract class DeconstructedPacket implements Built<DeconstructedPacket, DeconstructedPacketBuilder> {
  factory DeconstructedPacket([DeconstructedPacketBuilder updates(DeconstructedPacketBuilder b)]) = _$DeconstructedPacket;

  DeconstructedPacket._();

  Packet get packet;

  List<Object> get buffers;

  static Serializer<DeconstructedPacket> get serializer => _$deconstructedPacketSerializer;
}

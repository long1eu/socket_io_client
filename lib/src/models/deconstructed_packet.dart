import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:socket_io_client/src/models/packet.dart';

class DeconstructedPacket {
  const DeconstructedPacket({@required this.packet, @required this.buffers});

  final Packet packet;

  final List<Object> buffers;

  DeconstructedPacket copyWith({Packet packet, List<Object> buffers}) {
    return new DeconstructedPacket(
      packet: packet ?? this.packet,
      buffers: buffers ?? buffers,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'packet': packet,
      'buffers': buffers,
    };
  }

  @override
  String toString() => jsonEncode(toJson(), toEncodable: (Object it) => it.toString());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeconstructedPacket && runtimeType == other.runtimeType && packet == other.packet && buffers == other.buffers;

  @override
  int get hashCode => packet.hashCode ^ buffers.hashCode;
}

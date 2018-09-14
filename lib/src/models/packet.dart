import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:socket_io_client/src/models/packet_type.dart';

class Packet {
  const Packet({this.type = PacketType.event, this.id = -1, this.namespace, this.data, this.attachments = 0, this.query});

  final PacketType type;

  final int id;

  final String namespace;

  final Object data;

  final int attachments;

  final String query;

  static const Packet parserError = Packet(type: PacketType.error, data: 'parser error');
  static const Packet disconnect = Packet(type: PacketType.disconnect);

  Packet copyWith({
    PacketType type,
    int id,
    String namespace,
    Object data,
    int attachments,
    String query,
  }) {
    return Packet(
      type: type ?? this.type,
      id: id ?? this.id,
      namespace: namespace ?? this.namespace,
      data: data ?? this.data,
      attachments: attachments ?? this.attachments,
      query: query ?? this.query,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'id': id,
      'namespace': namespace,
      'data': data,
      'attachments': attachments,
      'query': query,
    };
  }

  @override
  String toString() => jsonEncode(toJson(), toEncodable: (Object it) => it.toString());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is Packet) {
      if (data.runtimeType != other.data.runtimeType) {
        return false;
      }

      bool dataIsEqual = data == other.data;
      if (data is List) {
        dataIsEqual = const DeepCollectionEquality().equals(data, other.data);
      }

      return runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id &&
          namespace == other.namespace &&
          dataIsEqual &&
          attachments == other.attachments &&
          query == other.query;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => type.hashCode ^ id.hashCode ^ namespace.hashCode ^ data.hashCode ^ attachments.hashCode ^ query.hashCode;
}

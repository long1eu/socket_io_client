import 'package:engine_io_client/engine_io_client.dart';
import 'package:socket_io_client/src/models/packet_type.dart';

class Packet {
  const Packet({this.type = PacketType.event, this.id = -1, this.namespace, this.data, this.attachments, this.query});

  final PacketType type;

  final int id;

  final String namespace;

  final Object data;

  final int attachments;

  final String query;

  static Packet parserError = new Packet(type: PacketType.error, data: 'parser error');

  @override
  String toString() {
    return (new ToStringHelper('Packet')
          ..add('type', type)
          ..add('id', id)
          ..add('namespace', namespace)
          ..add('data', data)
          ..add('attachments', attachments)
          ..add('query', query))
        .toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Packet &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id &&
          namespace == other.namespace &&
          data == other.data &&
          attachments == other.attachments &&
          query == other.query;

  @override
  int get hashCode => type.hashCode ^ id.hashCode ^ namespace.hashCode ^ data.hashCode ^ attachments.hashCode ^ query.hashCode;
}

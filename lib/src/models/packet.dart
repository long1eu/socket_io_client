import 'package:engine_io_client/src/logger.dart';
import 'package:socket_io_client/src/models/packet_type.dart';

class Packet {
  const Packet({this.type = PacketType.event, this.id = -1, this.namespace, this.data, this.attachments = 0, this.query});

  final PacketType type;

  final int id;

  final String namespace;

  final dynamic data;

  final int attachments;

  final String query;

  static const Packet parserError = const Packet(type: PacketType.error, data: 'parser error');

  Packet copyWith({
    PacketType type,
    int id,
    String namespace,
    dynamic data,
    int attachments,
    String query,
  }) {
    return new Packet(
      type: type ?? this.type,
      id: id ?? this.id,
      namespace: namespace ?? this.namespace,
      data: data ?? this.data,
      attachments: attachments ?? this.attachments,
      query: query ?? this.query,
    );
  }

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
          data.runtimeType == other.data.runtimeType &&
          data == other.data &&
          attachments == other.attachments &&
          query == other.query;

  @override
  int get hashCode => type.hashCode ^ id.hashCode ^ namespace.hashCode ^ data.hashCode ^ attachments.hashCode ^ query.hashCode;
}

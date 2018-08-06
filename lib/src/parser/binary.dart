import 'package:engine_io_client/src/logger.dart';
import 'package:socket_io_client/src/models/deconstructed_packet.dart';
import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/parser/has_binary.dart';

// ignore_for_file: avoid_classes_with_only_static_members
class Binary {
  static final Log log = new Log('Binary');
  static const String KEY_PLACEHOLDER = '_placeholder';

  static const String KEY_NUM = 'num';

  static DeconstructedPacket deconstructPacket(Packet packet) {
    final List<Object> buffers = <Object>[];

    packet = packet.copyWith(data: _deconstructPacket(packet.data, buffers), attachments: buffers.length);

    print(buffers.length);
    print(packet.data);

    final DeconstructedPacket result = new DeconstructedPacket(packet: packet, buffers: buffers);
    return result;
  }

  static Object _deconstructPacket(Object data, List<Object> buffers) {
    if (data == null) return null;

    if (data is List && HasBinary.isBinaryList(data)) {
      final Map<String, dynamic> placeholder = <String, dynamic>{KEY_PLACEHOLDER: true, KEY_NUM: buffers.length};

      buffers.add(data);
      return placeholder;
    } else if (data is List<dynamic>) {
      return data.map((dynamic list) => _deconstructPacket(list, buffers)).toList();
    } else if (data is Map<String, dynamic>) {
      return data.map<String, dynamic>((String key, dynamic value) {
        return new MapEntry<String, dynamic>(key, _deconstructPacket(data[key], buffers));
      });
    }
    return data;
  }

  static Packet reconstructPacket(Packet packet, List<List<int>> buffers) {
    return packet.copyWith(data: _reconstructPacket(packet.data, buffers), attachments: -1);
  }

  static Object _reconstructPacket(Object data, List<List<int>> buffers) {
    log.d('_reconstructPacket called with: data:$data of ${data.runtimeType}, buffers:$buffers');
    if (data is List<dynamic>) {
      return data.map((dynamic value) => _reconstructPacket(value, buffers)).toList();
    } else if (data is Map<String, dynamic>) {
      if (data[KEY_PLACEHOLDER] ?? false) {
        final int count = data[KEY_NUM] ?? -1;
        return count >= 0 && count < buffers.length ? buffers[count] : null;
      }

      return data.map<String, dynamic>((String key, dynamic values) {
        return new MapEntry<String, dynamic>(key, _reconstructPacket(data[key], buffers));
      });
    }
    return data;
  }
}

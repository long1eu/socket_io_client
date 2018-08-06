import 'dart:convert';

import 'package:engine_io_client/src/logger.dart';
import 'package:socket_io_client/src/models/deconstructed_packet.dart';
import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/models/packet_type.dart';
import 'package:socket_io_client/src/parser/binary.dart';
import 'package:socket_io_client/src/parser/binary_reconstructor.dart';
import 'package:socket_io_client/src/parser/has_binary.dart';
import 'package:socket_io_client/src/parser/parser.dart';
import 'package:utf/utf.dart';

class IoEncoder implements Encoder {
  static final Log log = new Log('SocketIo.IoEncoder');

  @override
  List<dynamic> encode(Packet packet) {
    PacketType type;
    if ((packet.type == PacketType.event || packet.type == PacketType.ack) && HasBinary.hasBinary(packet.data)) {
      type = packet.type == PacketType.event ? PacketType.binaryEvent : PacketType.binaryAck;
    }

    packet = packet.copyWith(type: type);
    log.d('encoding packet : $packet');

    if (packet.type == PacketType.binaryEvent || packet.type == PacketType.binaryAck) {
      return encodeAsBinary(packet);
    } else {
      final String encoding = encodeAsString(packet);
      log.d(encoding);
      return <String>[encoding];
    }
  }

  String encodeAsString(Packet packet) {
    final StringBuffer str = new StringBuffer(packet.type);

    if (packet.type == PacketType.binaryEvent || packet.type == PacketType.binaryAck) {
      str..write(packet.attachments)..write('-');
    }

    if (packet.namespace != null && packet.namespace.isNotEmpty && packet.namespace != '/') {
      str..write(packet.namespace)..write(',');
    }

    if (packet.id >= 0) {
      str.write(packet.id);
    }

    if (packet.data != null) {
      log.d('json: ${packet.data}');

      str.write(json.encode(packet.data, toEncodable: (dynamic object) {
        if (object is DateTime) {
          return object.toIso8601String();
        }
        log.w('toEncodable was called with object: $object of type: ${object.runtimeType}');
        return object.toString();
      }));
    }
    log.d('encoded $packet as $str');
    return str.toString();
  }

  List<dynamic> encodeAsBinary(Packet packet) {
    log.d('encodeAsBinary called with: packet:[$packet]');
    final DeconstructedPacket deconstruction = Binary.deconstructPacket(packet);
    final String pack = encodeAsString(deconstruction.packet);
    log.d('deconstruction: $deconstruction');
    log.d('pack: $pack');
    log.d(encodeAsString(deconstruction.packet));
    final List<dynamic> buffers = deconstruction.buffers;

    buffers.insert(0, pack);

    log.d('buffers: $buffers');
    return buffers;
  }
}

class IoDecoder implements Decoder {
  static final Log log = new Log('IoDecoder');
  BinaryReconstructor reconstructor;
  DecoderCallback onDecodedCallback;

  @override
  void add(dynamic data) {
    log.d('add: ${data.runtimeType} : ${data.toString()}');
    if (data is String) {
      final Packet packet = decodeString(data);
      if (packet.type == PacketType.binaryEvent || packet.type == PacketType.binaryAck) {
        reconstructor = new BinaryReconstructor(packet);
        if (reconstructor.packet.attachments == 0) onDecodedCallback?.call(packet);
      } else {
        onDecodedCallback?.call(packet);
      }
    } else if (data is List<int>) {
      if (reconstructor == null) {
        throw new StateError('got binary data when not reconstructing a packet');
      } else {
        final Packet packet = reconstructor.takeBinaryData(data);
        log.d(packet);
        if (packet != null) {
          reconstructor = null;
          onDecodedCallback?.call(packet);
        }
      }
    }
  }

  static Packet decodeString(String string) {
    int i = 0;
    final int length = string.length;

    PacketType packetType;
    try {
      final int value = int.parse(decodeUtf8(<int>[string.codeUnitAt(0)]));
      packetType = PacketType.values[value];
    } catch (e) {
      return Packet.parserError;
    }

    if (packetType == null) return Packet.parserError;

    Packet packet = new Packet(type: packetType);

    if (packet.type == PacketType.binaryEvent || packet.type == PacketType.binaryAck) {
      if (!string.contains('-') || length <= i + 1) return Packet.parserError;

      final StringBuffer attachments = new StringBuffer();
      while (string.codeUnitAt(++i) != '-'.codeUnitAt(0)) {
        attachments.writeCharCode(string.codeUnitAt(i));
      }

      packet = packet.copyWith(attachments: int.parse(attachments.toString()));
    }

    if (length > i + 1 && '/'.codeUnitAt(0) == string.codeUnitAt(i + 1)) {
      final StringBuffer namespace = new StringBuffer();

      // ignore: literal_only_boolean_expressions
      while (true) {
        ++i;
        final int c = string.codeUnitAt(i);
        if (','.codeUnitAt(0) == c) break;
        namespace.writeCharCode(c);
        if (i + 1 == length) break;
      }

      packet = packet.copyWith(namespace: namespace.toString());
    } else {
      packet = packet.copyWith(namespace: '/');
    }

    if (length > i + 1) {
      final String next = string.substring(i + 1, i + 2);
      final int value = int.tryParse(next) ?? -1;

      if (value > -1) {
        final StringBuffer id = new StringBuffer();

        // ignore: literal_only_boolean_expressions
        while (true) {
          ++i;

          final String nextChar = string.substring(i, i + 1);
          final int numericValue = int.tryParse(nextChar) ?? -1;

          if (numericValue < 0) {
            --i;
            break;
          }
          id.write(numericValue);
          if (i + 1 == length) break;
        }

        try {
          packet = packet.copyWith(id: int.parse(id.toString()));
        } catch (e) {
          return Packet.parserError;
        }
      }
    }

    if (length > i + 1) {
      try {
        i++;
        final String data = string.substring(i);
        final dynamic value = json.decode(data);
        packet = packet.copyWith(data: value);
      } catch (e) {
        log.d('An error occured while retrieving data from JSON $e');
        return Packet.parserError;
      }
    }

    log.d('decoded $string as $packet');
    return packet;
  }

  @override
  void destroy() {
    reconstructor?.finishReconstruction();
    onDecodedCallback = null;
  }

  @override
  void onDecoded(DecoderCallback callback) => onDecodedCallback = callback;
}

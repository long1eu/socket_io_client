import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/parser/io_parser.dart';
import 'package:test/test.dart';

// ignore: avoid_classes_with_only_static_members
class Helpers {
  static IoEncoder encoder = new IoEncoder();
  static IoDecoder decoder;

  static void test(Packet packet) {
    final List<dynamic> encodedPacks = encoder.encode(packet);
    decoder = new IoDecoder();
    decoder.onDecoded((Packet p) => expect(p, packet));
    decoder.add(encodedPacks[0]);
  }

  static void testDecodeError(String errorMessage) {
    decoder = new IoDecoder();
    decoder.onDecoded((Packet p) => expect(Packet.parserError, p));
    decoder.add(errorMessage);
  }

  static void testBin(Packet obj) {
    final dynamic originalData = obj.data;
    final List<dynamic> encodedPacks = encoder.encode(obj);

    decoder = new IoDecoder();
    decoder.onDecoded((Packet p) {
      obj = obj.copyWith(data: originalData, attachments: -1);
      //expect(p, obj);
    });

    encodedPacks.forEach(decoder.add);
  }

  static void assertPacket(Packet actual, Packet expected) {
    expect(actual.type, expected.type);
    expect(actual.id, expected.id);
    expect(actual.namespace, expected.namespace);
    expect(actual.attachments, expected.attachments);
    expect(actual.data, expected.data);
  }
}

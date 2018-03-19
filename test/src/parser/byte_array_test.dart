import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/models/packet_type.dart';
import 'package:socket_io_client/src/parser/io_parser.dart';
import 'package:test/test.dart';
import 'package:utf/utf.dart';

import 'helpers.dart';

void main() {
  test('encodeByteArray', () {
    final Packet packet = new Packet((PacketBuilder b) {
      b
        ..type = PacketType.binaryEvent
        ..data = encodeUtf8('abc')
        ..id = 23
        ..namespace = '/cool';
    });

    Helpers.testBin(packet);
  });

  test('encodeByteArray2', () {
    final Packet packet = new Packet((PacketBuilder b) {
      b
        ..type = PacketType.binaryEvent
        ..data = new List<int>.generate(2, (_) => 0)
        ..id = 0
        ..namespace = '/';
    });

    Helpers.testBin(packet);
  });

  test('encodeByteArrayDeepInJson', () {
    final Map<String, dynamic> data = <String, dynamic>{
      'a': 'hi',
      'b': <String, dynamic>{},
      'c': <String, dynamic>{
        'a': 'bye',
        'b': <String, dynamic>{},
      }
    };

    final Packet packet = new Packet((PacketBuilder b) {
      b
        ..type = PacketType.binaryEvent
        ..data = data
        ..id = 99
        ..namespace = '/deep';
    });

    Helpers.testBin(packet);
  });

  test('encodeDeepBinaryJSONWithNullValue', () {
    final Map<String, dynamic> data = <String, dynamic>{
      'a': 'b',
      'c': 4,
      'e': <String, dynamic>{'g': null},
      'h': null
    };
    data['h'] = new List<int>.generate(9, (_) => 0);

    final Packet packet = new Packet((PacketBuilder b) {
      b
        ..type = PacketType.binaryEvent
        ..data = data
        ..id = 600
        ..namespace = '/';
    });

    Helpers.testBin(packet);
  });

  test('encodeDeepBinaryJSONWithNullValue', () {
    final List<dynamic> data = <dynamic>['a', null, <String, dynamic>{}];
    data[1] = 'abc'.codeUnits;

    final Packet packet = new Packet((PacketBuilder b) {
      b
        ..type = PacketType.binaryAck
        ..data = data
        ..id = 127
        ..namespace = '/back';
    });

    Helpers.testBin(packet);
  });

  test('cleanItselfUpOnClose', () {
    final List<dynamic> data = <dynamic>[
      new List<int>.generate(2, (_) => 0),
      new List<int>.generate(3, (_) => 0),
    ];

    final Packet packet = new Packet((PacketBuilder b) {
      b
        ..type = PacketType.binaryEvent
        ..data = data
        ..id = 0
        ..namespace = '/';
    });

    final List<dynamic> encodedPackets = new IoEncoder().encode(packet);

    final IoDecoder decoder = new IoDecoder();

    decoder.onDecoded((Packet packet) {
      throw new StateError('received a packet when not all binary data was sent.');
    });
    decoder.add(encodedPackets[0]);
    decoder.add(encodedPackets[1]);
    decoder.destroy();

    expect(decoder.reconstructor.buffers.length, 0);
  });
}

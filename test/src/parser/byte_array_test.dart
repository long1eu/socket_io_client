import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/models/packet_type.dart';
import 'package:socket_io_client/src/parser/io_parser.dart';
import 'package:test/test.dart';
import 'package:utf/utf.dart';

import 'helpers.dart';

void main() {
  test('encodeByteArray', () {
    final Packet packet = new Packet(
      id: 23,
      type: PacketType.binaryEvent,
      data: encodeUtf8('abc'),
      namespace: '/cool',
    );

    Helpers.testBin(packet);
  });

  test('encodeByteArray2', () {
    final Packet packet = new Packet(
      id: 0,
      type: PacketType.binaryEvent,
      data: new List<int>.generate(2, (int i) => i),
      namespace: '/',
    );

    Helpers.testBin(packet);
  });

  test('encodeByteArrayDeepInJson', () {
    final Map<String, dynamic> data = <String, dynamic>{
      'a': 'hi',
      'b': <String, dynamic>{'why': new List<int>.generate(3, (int i) => 0)},
      'c': <String, dynamic>{
        'a': 'bye',
        'b': <String, dynamic>{'a': new List<int>.generate(6, (int i) => 0)},
      }
    };

    final Packet packet = new Packet(
      id: 99,
      type: PacketType.binaryEvent,
      data: data,
      namespace: '/deep',
    );

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

    final Packet packet = new Packet(
      id: 600,
      type: PacketType.binaryEvent,
      data: data,
      namespace: '/',
    );

    Helpers.testBin(packet);
  });

  test('encodeDeepBinaryJSONWithNullValue', () {
    final List<dynamic> data = <dynamic>['a', null, <String, dynamic>{}];
    data[1] = 'abc'.codeUnits;

    final Packet packet = new Packet(
      id: 127,
      type: PacketType.binaryAck,
      data: data,
      namespace: '/back',
    );

    Helpers.testBin(packet);
  });

  test('cleanItselfUpOnClose', () {
    final List<dynamic> data = <dynamic>[
      new List<int>.generate(2, (_) => 0),
      new List<int>.generate(3, (_) => 0),
    ];

    final Packet packet = new Packet(
      id: 0,
      type: PacketType.binaryEvent,
      data: data,
      namespace: '/',
    );

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

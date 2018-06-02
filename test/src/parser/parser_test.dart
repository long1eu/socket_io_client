import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/models/packet_type.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('encodeConnection', () {
    const Packet packet = const Packet(type: PacketType.connect, namespace: '/woot');

    Helpers.test(packet);
  });

  test('encodeDisconnection', () {
    const Packet packet = const Packet(type: PacketType.disconnect, namespace: '/woot');
    Helpers.test(packet);
  });

  //this gives a false negative
  test('encodeEvent', () {
    Packet packet = const Packet(
      type: PacketType.event,
      data: const <dynamic>['a', 1, <String, dynamic>{}],
      namespace: '/',
    );

    Helpers.test(packet);

    packet = const Packet(
      type: PacketType.event,
      data: <dynamic>['a', 1, <String, dynamic>{}],
      namespace: '/test',
    );

    Helpers.test(packet);
  });

  test('encodeAck', () {
    const Packet packet = const Packet(
      id: 123,
      type: PacketType.ack,
      namespace: '/',
    );

    Helpers.test(packet);
  });

  test('decodeInError', () {
    // Random string
    Helpers.testDecodeError('asdf');
    // Unknown type
    Helpers.testDecodeError('${PacketType.values.length}asdf');
    // Binary event with no `-`
    Helpers.testDecodeError('${PacketType.binaryEvent}asdf');
    // Binary ack with no `-`
    Helpers.testDecodeError('${PacketType.binaryAck}asdf');
    // Binary event with no attachment
    Helpers.testDecodeError(PacketType.binaryEvent.toString());
    // event non numeric id
    Helpers.testDecodeError('${PacketType.event}2sd');
    // event with invalid json data
    Helpers.testDecodeError('${PacketType.event}2[\"a\",1,{asdf}]');
  });
}

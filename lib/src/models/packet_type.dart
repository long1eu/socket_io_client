class PacketType {
  final int index;

  const PacketType._(this.index);

  static const PacketType connect = const PacketType._(0);
  static const PacketType disconnect = const PacketType._(1);
  static const PacketType event = const PacketType._(2);
  static const PacketType ack = const PacketType._(3);
  static const PacketType error = const PacketType._(4);
  static const PacketType binaryEvent = const PacketType._(5);
  static const PacketType binaryAck = const PacketType._(6);

  static const List<PacketType> values = const <PacketType>[connect, disconnect, event, ack, error, binaryEvent, binaryAck];

  @override
  String toString() {
    return const <int, String>{
      0: '0',
      1: '1',
      2: '2',
      3: '3',
      4: '4',
      5: '5',
      6: '6',
    }[index];
  }
}

import 'package:socket_io_client/src/models/packet.dart';
import 'package:socket_io_client/src/parser/binary.dart';

class BinaryReconstructor {
  BinaryReconstructor(this.packet);

  Packet packet;

  List<List<int>> buffers = <List<int>>[];

  Packet takeBinaryData(List<int> binData) {
    buffers.add(binData);
    if (buffers.length == packet.attachments) {
      final Packet packet = Binary.reconstructPacket(this.packet, buffers);
      finishReconstruction();
      return packet;
    }
    return null;
  }

  void finishReconstruction() {
    packet = null;
    buffers = <List<int>>[];
  }
}

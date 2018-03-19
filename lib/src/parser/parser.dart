import 'package:socket_io_client/src/models/packet.dart';

typedef void EncoderCallback(dynamic args);
typedef void DecoderCallback(Packet args);

abstract class Encoder {
  List<dynamic> encode(Packet packet);
}

abstract class Decoder {
  /// Can be [String] or [List<int>]
  void add(dynamic data);

  void destroy();

  void onDecoded(DecoderCallback callback);
}

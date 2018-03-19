library manager_options;

import 'package:built_value/built_value.dart';
import 'package:engine_io_client/engine_io_client.dart' show SocketOptions, SocketOptionsBuilder;
import 'package:socket_io_client/src/parser/io_parser.dart';

part 'manager_options.g.dart';

abstract class ManagerOptions implements Built<ManagerOptions, ManagerOptionsBuilder> {
  factory ManagerOptions([ManagerOptionsBuilder updates(ManagerOptionsBuilder b)]) {
    return new _$ManagerOptions((ManagerOptionsBuilder b) {
      return b
        ..reconnection = true
        ..timeout = 20000
        ..options = (new SocketOptions().toBuilder()..path = '/socket.io')
        ..reconnectionAttempts = 0x3FFFFFFF
        ..reconnectionDelay = 1000
        ..reconnectionDelayMax = 5000
        ..randomizationFactor = 0.5
        ..update(updates);
    });
  }

  ManagerOptions._();

  bool get reconnection;

  int get reconnectionAttempts;

  int get reconnectionDelay;

  int get reconnectionDelayMax;

  double get randomizationFactor;

  @nullable
  IoEncoder get encoder;

  @nullable
  IoDecoder get decoder;

  /// Connection timeout (ms). Set -1 to disable.
  int get timeout;

  SocketOptions get options;
}

import 'package:socket_io_client/src/client/io.dart';
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/models/manager_options.dart';

// ignore: avoid_classes_with_only_static_members
class Connection {
  static const int TIMEOUT = 7000;
  static const int PORT = 3001;

  static Socket client({String path, ManagerOptions options, bool forceNew = true, bool multiplex}) {
    return Io.socket('$uri${path == null ? '' : path}', options, forceNew, multiplex);
  }

  static String get uri => 'http://localhost:$PORT';

  static String get namespace => '/';
}

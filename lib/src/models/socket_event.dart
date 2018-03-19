import 'package:socket_io_client/src/models/manager_event.dart';

class SocketEvent {
  static const String connect = 'connect';
  static const String connecting = 'connecting';
  static const String disconnect = 'disconnect';
  static const String error = 'error';
  static const String message = 'message';
  static const String connectError = ManagerEvent.connectError;
  static const String connectTimeout = ManagerEvent.connectTimeout;
  static const String reconnect = ManagerEvent.reconnect;
  static const String reconnectError = ManagerEvent.reconnectError;
  static const String reconnectFailed = ManagerEvent.reconnectFailed;
  static const String reconnectAttempt = ManagerEvent.reconnectAttempt;
  static const String reconnecting = ManagerEvent.reconnecting;
  static const String ping = ManagerEvent.ping;
  static const String pong = ManagerEvent.pong;

  static const List<String> values = const <String>[
    connect,
    connecting,
    disconnect,
    error,
    message,
    connectError,
    connectTimeout,
    reconnect,
    reconnectError,
    reconnectFailed,
    reconnectAttempt,
    reconnecting,
    ping,
    pong
  ];
}

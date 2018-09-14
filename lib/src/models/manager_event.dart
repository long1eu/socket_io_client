class ManagerEvent {
  static const String open = 'open';
  static const String close = 'close';
  static const String packet = 'packet';
  static const String error = 'error';
  static const String connectError = 'connect_error';
  static const String connectTimeout = 'connect_timeout';
  static const String reconnect = 'reconnect';
  static const String reconnectError = 'reconnect_error';
  static const String reconnectFailed = 'reconnect_failed';
  static const String reconnectAttempt = 'reconnect_attempt';
  static const String reconnecting = 'reconnecting';
  static const String ping = 'ping';
  static const String pong = 'pong';
  static const String transport = 'transport';

  static const List<String> values = const <String>[
    open,
    close,
    packet,
    error,
    connectError,
    connectTimeout,
    reconnect,
    reconnectError,
    reconnectFailed,
    reconnectAttempt,
    reconnecting,
    ping,
    pong,
    transport
  ];
}

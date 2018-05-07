class SocketIOError extends Error {
  SocketIOError(this.transport, [this.code]);

  final String transport;
  final dynamic code;

  @override
  String toString() => 'SocketIOError{transport: $transport, code: $code}';
}

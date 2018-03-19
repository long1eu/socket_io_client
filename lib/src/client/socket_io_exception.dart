class SocketIOException extends Error {
  SocketIOException(this.transport, [this.code]);

  final String transport;
  final dynamic code;

  @override
  String toString() => 'SocketIOException{transport: $transport, code: $code}';
}

import 'dart:io' hide Socket;

import 'package:engine_io_client/engine_io_client.dart' show Socket, SocketOptions, ToStringHelper, TransportOptions;
import 'package:socket_io_client/src/parser/io_parser.dart';

class ManagerOptions extends SocketOptions {
  ManagerOptions({
    this.timeout = 2000,
    this.reconnection = true,
    this.reconnectionAttempts = 0x3FFFFFFF,
    this.reconnectionDelay = 1000,
    this.reconnectionDelayMax = 5000,
    this.randomizationFactor = 0.5,
    this.encoder,
    this.decoder,
    List<String> transports,
    bool upgrade,
    bool rememberUpgrade,
    String host,
    String rawQuery,
    Map<String, TransportOptions> transportOptions,
    String hostname,
    String path = '/socket.io',
    String timestampParam,
    bool secure,
    bool timestampRequests,
    int port,
    int policyPort,
    Map<String, String> query,
    Map<String, List<String>> headers,
    Socket socket,
    SecurityContext securityContext,
  }) : super(
            transports: transports,
            upgrade: upgrade,
            rememberUpgrade: rememberUpgrade,
            host: host,
            rawQuery: rawQuery,
            transportOptions: transportOptions,
            hostname: hostname,
            path: path,
            timestampParam: timestampParam,
            secure: secure,
            timestampRequests: timestampRequests,
            port: port,
            policyPort: policyPort,
            query: query,
            headers: headers,
            socket: socket,
            securityContext: securityContext);

  /// Connection timeout (ms). Set -1 to disable.
  final int timeout;

  final bool reconnection;

  final int reconnectionAttempts;

  final int reconnectionDelay;

  final int reconnectionDelayMax;

  final double randomizationFactor;

  final IoEncoder encoder;

  final IoDecoder decoder;

  @override
  TransportOptions copyWith({
    int timeout,
    bool reconnection,
    int reconnectionAttempts,
    int reconnectionDelay,
    int reconnectionDelayMax,
    double randomizationFactor,
    IoEncoder encoder,
    IoDecoder decoder,
    List<String> transports,
    bool upgrade,
    bool rememberUpgrade,
    String host,
    String rawQuery,
    Map<String, TransportOptions> transportOptions,
    String hostname,
    String path,
    String timestampParam,
    bool secure,
    bool timestampRequests,
    int port,
    int policyPort,
    Map<String, String> query,
    Map<String, List<String>> headers,
    Socket socket,
    SecurityContext securityContext,
  }) {
    return new ManagerOptions(
        timeout: timeout ?? this.timeout,
        reconnection: reconnection ?? this.reconnection,
        reconnectionAttempts: reconnectionAttempts ?? this.reconnectionAttempts,
        reconnectionDelay: reconnectionDelay ?? this.reconnectionDelay,
        reconnectionDelayMax: reconnectionDelayMax ?? this.reconnectionDelayMax,
        randomizationFactor: randomizationFactor ?? this.randomizationFactor,
        encoder: encoder ?? this.encoder,
        decoder: decoder ?? this.decoder,
        transports: transports ?? this.transports,
        upgrade: upgrade ?? this.upgrade,
        rememberUpgrade: rememberUpgrade ?? this.rememberUpgrade,
        host: host ?? this.host,
        rawQuery: rawQuery ?? this.rawQuery,
        transportOptions: transportOptions ?? this.transportOptions,
        hostname: hostname ?? this.hostname,
        path: path ?? this.path,
        timestampParam: timestampParam ?? this.timestampParam,
        secure: secure ?? this.secure ?? false,
        timestampRequests: timestampRequests ?? this.timestampRequests ?? false,
        port: port ?? this.port,
        policyPort: policyPort ?? this.policyPort,
        query: query ?? this.query,
        headers: headers ?? this.headers,
        socket: socket ?? this.socket,
        securityContext: securityContext ?? this.securityContext);
  }

  @override
  String toString() {
    return (new ToStringHelper('ManagerOptions')
          ..add('timeout', '$timeout')
          ..add('reconnection', '$reconnection')
          ..add('reconnectionAttempts', '$reconnectionAttempts')
          ..add('reconnectionDelay', '$reconnectionDelay')
          ..add('reconnectionDelayMax', '$reconnectionDelayMax')
          ..add('randomizationFactor', '$randomizationFactor')
          ..add('encoder', '$encoder')
          ..add('decoder', '$decoder')
          ..add('SocketOptions', '${super.toString()}'))
        .toString();
  }
}

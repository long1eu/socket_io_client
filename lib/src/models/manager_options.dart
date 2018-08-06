import 'dart:io' hide Socket;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:engine_io_client/engine_io_client.dart' show Socket, SocketOptions, TransportOptions;
import 'package:engine_io_client/src/logger.dart';
import 'package:socket_io_client/src/parser/io_parser.dart';

class ManagerOptions extends SocketOptions {
  const ManagerOptions({
    int timeout,
    bool reconnection,
    int reconnectionAttempts,
    int reconnectionDelay,
    int reconnectionDelayMax,
    double randomizationFactor,
    this.encoder,
    this.decoder,
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
    PersistCookieJar cookieJar,
  })  : timeout = timeout ?? 2000,
        reconnection = reconnection ?? true,
        reconnectionAttempts = reconnectionAttempts ?? 0x3FFFFFFF,
        reconnectionDelay = reconnectionDelay ?? 1000,
        reconnectionDelayMax = reconnectionDelayMax ?? 5000,
        randomizationFactor = randomizationFactor ?? 0.5,
        super(
          transports: transports,
          upgrade: upgrade,
          rememberUpgrade: rememberUpgrade,
          host: host,
          rawQuery: rawQuery,
          transportOptions: transportOptions,
          hostname: hostname,
          path: path ?? '/socket.io',
          timestampParam: timestampParam,
          secure: secure,
          timestampRequests: timestampRequests,
          port: port,
          policyPort: policyPort,
          query: query,
          headers: headers,
          socket: socket,
          securityContext: securityContext,
          cookieJar: cookieJar,
        );

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
    PersistCookieJar cookieJar,
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
      securityContext: securityContext ?? this.securityContext,
      cookieJar: cookieJar ?? this.cookieJar,
    );
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

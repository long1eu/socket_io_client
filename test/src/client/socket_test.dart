import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart' as eng;
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final eng.Log log = new eng.Log('socket_test');

  test('shouldHaveAnAccessibleSocketIdEqualToServerSideSocketId', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      values.add(socket.id);
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], socket.io.engine.id);
  });

  test('shouldHaveAnAccessibleSocketIdEqualToServerSideSocketIdOnCustomNamespace', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client(path: '/foo');

    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      values.add(socket.id);
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], '/foo#${socket.io.engine.id}');
  });

  test('clearsSocketIdUponDisconnection', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.on(Socket.eventDisconnect).listen((eng.Event event) {
        values.add(socket.id);
      });
      socket.disconnect();
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], isNull);
  });

  test('doesNotFireConnectErrorIfWeForceDisconnectInOpeningState', () async {
    final List<dynamic> values = <dynamic>[];

    const ManagerOptions options = const ManagerOptions(timeout: 100);

    final Socket socket = Connection.client(options: options);

    socket.on(Socket.eventConnectError).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.on(Socket.eventDisconnect).listen((eng.Event event) {
        values.add(new StateError('Unexpected'));
      });
    });
    socket.connect();
    socket.disconnect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {
      values.add('done');
    });
    log.d(values.toString());

    if (values[0] is! String) throw values[0];
  });

  test('pingAndPongWithLatency', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      bool pinged = false;
      socket.once(Socket.eventPing).listen((eng.Event event) {
        log.d('ping: ${event.args}');
        pinged = true;
      });
      socket.once(Socket.eventPong).listen((eng.Event event) {
        log.d('pong: ${event.args}');
        final int ms = event.args[0];
        values.add(pinged);
        values.add(ms);
      });
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 4000), () {});
    log.d(values.toString());

    expect(values[0], isTrue);
    expect(values[1] > 0, isTrue);
  });

  test('shouldChangeSocketIdUponReconnection', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      values.add(socket.id);

      socket.on(Socket.eventReconnectAttempt).listen((eng.Event event) {
        values.add(socket.id);
      });
      socket.on(Socket.eventReconnect).listen((eng.Event event) {
        values.add(socket.id);
      });

      socket.io.engine.close();
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 2000), () {});
    log.d(values.toString());

    expect(values[1], isNull);
    expect(values[2], isNot(values[0]));
  });

  test('shouldAcceptAQueryStringOnDefaultNamespace', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client(path: '/?c=d');
    socket.emit('getHandshake', <dynamic>[], true).listen(([List<dynamic> args]) {
      values.add(args[0]);
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.e(values.toString());

    expect(values[0]['query']['c'] == 'd', isTrue);
  });

  test('shouldAcceptAQueryString', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client(path: '/abc?b=c&d=e');
    socket.on('handshake').listen((eng.Event event) {
      log.d('handshake: ${event.args}');
      values.add(event.args[0]);
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0]['query']['b'] == 'c', isTrue);
    expect(values[0]['query']['d'] == 'e', isTrue);
  });
}

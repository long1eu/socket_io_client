import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart' as eng;
import 'package:socket_io_client/src/client/manager.dart';
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final eng.Log log = new eng.Log('server_connection_test');

  test('openAndClose', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      values.add(event.args);
      socket.disconnect();
    });
    socket.on(Socket.eventDisconnect).listen((eng.Event event) {
      log.d('disconnect ${event.args}');
      values.add(event.args);
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    log.d(values[1].runtimeType);
    expect(values[0].length, 0);
    expect(values[1].length, 1);
    expect(values[1][0] is String, isTrue);
  });

  test('message', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.send(<String>['foo', 'bar']);
    });
    socket.on(Socket.eventMessage).listen((eng.Event event) {
      log.d('message: ${event.args}');
      values.add(event.args);
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0], <String>['foo', 'bar']);
    expect(values[1], <String>['hello client']);
  });

  test('event', () async {
    final List<dynamic> values = <dynamic>[];

    final Map<String, dynamic> foo = <String, dynamic>{'foo': 1};
    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.emit('echo', <dynamic>[foo, null, 'bar']);
    });
    socket.on('echoBack').listen((eng.Event event) {
      log.d('message: ${event.args}');
      values.add(event.args);
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0].length, 3);
    expect(values[0][0], foo);
    expect(values[0][1], isNull);
    expect(values[0][2], 'bar');
  });

  test('ack', () async {
    final List<dynamic> values = <dynamic>[];

    final Map<String, dynamic> foo = <String, dynamic>{'foo': 1};
    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.emit('ack', <dynamic>[foo, 'bar'], true).listen(([List<dynamic> args]) => values.add(args));
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0].length, 2);
    expect(values[0][0], foo);
    expect(values[0][1], 'bar');
  });

  test('ackWithoutArgs', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.emit('ack', null, true).listen(([List<dynamic> args]) {
        values.add(args.length);
      });
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0], 0);

    socket.disconnect();
  });

  test('ackWithoutArgsFromClient', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.on('ack').listen((eng.Event event) async {
        values.add(event.args);
        await event.args[0]();
      });
      socket.on('ackBack').listen((eng.Event event) {
        values.add(event.args);
      });
      socket.emit('callAck');
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0].length, 1);
    expect(values[0][0] is Ack, isTrue);
    expect(values[1].length, 0);
  });

  test('closeEngineConnection', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.io.engine.on(eng.Socket.eventClose).listen((eng.Event event) {
        values.add('done');
      });
      socket.disconnect();
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0], 'done');
  });

  test('broadcast', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket1 = Connection.client();
    Socket socket2;
    socket1.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket2 = Connection.client(forceNew: true);

      socket2.on(Socket.eventConnect).listen((eng.Event event) {
        log.d('connect2: ${event.args}');
        socket2.emit('broadcast', <String>['hi']);
      });

      socket2.connect();
    });
    socket1.on('broadcastBack').listen((eng.Event event) {
      values.add(event.args);
    });

    socket1.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0].length, 1);
    expect(values[0][0], 'hi');
  });

  test('room', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.emit('room', <String>['hi']);
    });
    socket.on('roomBack').listen((eng.Event event) {
      values.add(event.args);
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0].length, 1);
    expect(values[0][0], 'hi');
  });

  test('pollingHeaders', () async {
    final List<dynamic> values = <dynamic>[];

    const ManagerOptions options = const ManagerOptions(
      transports: const <String>[eng.Polling.NAME],
      path: '/socket.io',
      headers: const <String, List<String>>{
        'X-SocketIO': const <String>['hi']
      },
    );

    final Socket socket = Connection.client(options: options);

    socket.io.on(Manager.eventTransport).listen((eng.Event event) {
      log.d('transport ${event.args}');
      final eng.Transport transport = event.args[0];

      transport.once(eng.Transport.eventResponseHeaders).listen((eng.Event event) {
        log.d('responseHeaders ${event.args}');
        final Map<String, List<String>> headers = event.args[0];
        final List<String> value = headers['X-SocketIO'.toLowerCase()];
        values.add(value != null ? value[0] : '');
      });
    });
    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], 'hi');
  });

  test('disconnectFromServer', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket.on(Socket.eventConnect).listen((eng.Event event) {
      log.d('connect: ${event.args}');
      socket.emit('requestDisconnect');
    });
    socket.on(Socket.eventDisconnect).listen((eng.Event event) => values.add('disconnected'));

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], 'disconnected');
  });
}

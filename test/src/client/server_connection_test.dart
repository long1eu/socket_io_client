import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart' as eng;
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:socket_io_client/src/models/socket_event.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final eng.Log log = new eng.Log('server_connection_test');

  test('openAndClose', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket
      ..on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('connect: $args');
        values.add(args);
        await socket.disconnect();
      })
      ..on(SocketEvent.disconnect, (List<dynamic> args) {
        log.d('disconnect $args');
        values.add(args);
      });

    await socket.connect();
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
    socket
      ..on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('connect: $args');
        await socket.send(<String>['foo', 'bar']);
      })
      ..on(SocketEvent.message, (List<dynamic> args) {
        log.d('message: $args');
        values.add(args);
      });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0], <String>['hello client']);
    expect(values[1], <String>['foo', 'bar']);

    await socket.disconnect();
  });

  test('event', () async {
    final List<dynamic> values = <dynamic>[];

    final Map<String, dynamic> foo = <String, dynamic>{'foo': 1};
    final Socket socket = Connection.client();
    socket
      ..on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('connect: $args');
        await socket.emit('echo', <dynamic>[foo, null, 'bar']);
      })
      ..on('echoBack', (List<dynamic> args) {
        log.d('message: $args');
        values.add(args);
      });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0].length, 3);
    expect(values[0][0], foo);
    expect(values[0][1], isNull);
    expect(values[0][2], 'bar');

    await socket.disconnect();
  });

  test('ack', () async {
    final List<dynamic> values = <dynamic>[];

    final Map<String, dynamic> foo = <String, dynamic>{'foo': 1};
    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect: $args');
      await socket.emitAck(
        'ack',
        <dynamic>[foo, 'bar'],
        ([List<dynamic> args]) async {
          values.add(args);
        },
      );
    });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0].length, 2);
    expect(values[0][0], foo);
    expect(values[0][1], 'bar');

    await socket.disconnect();
  });

  test('ackWithoutArgs', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect: $args');
      await socket.emitAck('ack', null, ([List<dynamic> args]) async {
        values.add(args.length);
      });
    });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0], 0);

    await socket.disconnect();
  });

  test('ackWithoutArgsFromClient', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect: $args');
      socket
        ..on('ack', (List<dynamic> args) async {
          values.add(args);
          await args[0]();
        })
        ..on('ackBack', (List<dynamic> args) async {
          values.add(args);
          await socket.disconnect();
        });
      await socket.emit('callAck');
    });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0].length, 1);
    expect(values[0][0] is Ack, isTrue);
    expect(values[1].length, 0);

    await socket.disconnect();
  });

  test('closeEngineConnection', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect: $args');
      socket.io.engine.on(eng.SocketEvent.close, (List<dynamic> args) {
        values.add('done');
      });
      await socket.disconnect();
    });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0], 'done');

    await socket.disconnect();
  });

  test('broadcast', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket1 = Connection.client();
    Socket socket2;
    socket1
      ..on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('connect: $args');
        socket2 = Connection.client(forceNew: true);

        socket2.on(SocketEvent.connect, (List<dynamic> args) async {
          log.d('connect2: $args');
          await socket2.emit('broadcast', <String>['hi']);
        });

        await socket2.connect();
      })
      ..on('broadcastBack', (List<dynamic> args) {
        values.add(args);
      });

    await socket1.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0].length, 1);
    expect(values[0][0], 'hi');

    await socket1.disconnect();
  });

  test('room', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket
      ..on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('connect: $args');
        await socket.emit('room', <String>['hi']);
      })
      ..on('roomBack', (List<dynamic> args) {
        values.add(args);
      });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0].length, 1);
    expect(values[0][0], 'hi');

    await socket.disconnect();
  });

  test('pollingHeaders', () async {
    final List<dynamic> values = <dynamic>[];

    final ManagerOptions options = ManagerOptions(
        transports: <String>[eng.Polling.NAME],
        path: '/socket.io',
        onRequestHeaders: (Map<String, String> headers) {
          log.d('requestHeaders $headers');
          headers['X-SocketIO'] = 'hi';
        },
        onResponseHeaders: (Map<String, String> headers) {
          log.d('responseHeaders $headers');
          final String value = headers['X-SocketIO'.toLowerCase()];
          values.add(value != null ? value : '');
        });

    final Socket socket = Connection.client(options: options);

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], 'hi');
    await socket.disconnect();
  });

  test('disconnectFromServer', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket
      ..on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('connect: $args');
        await socket.emit('requestDisconnect');
      })
      ..on(SocketEvent.disconnect, (List<dynamic> args) {
        values.add('disconnected');
      });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], 'disconnected');
  });
}

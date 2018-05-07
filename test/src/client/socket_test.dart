import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart' as eng;
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:socket_io_client/src/models/socket_event.dart';
import 'package:test/test.dart';

import 'connection.dart';

void main() {
  final eng.Log log = new eng.Log('socket_test');

  test('shouldHaveAnAccessibleSocketIdEqualToServerSideSocketId', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket
      ..on(Socket.eventConnect, (List<dynamic> args) async {
        log.d('connect: $args');
        values.add(socket.id);
      });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], socket.io.engine.id);
  });

  test('shouldHaveAnAccessibleSocketIdEqualToServerSideSocketIdOnCustomNamespace', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client(path: '/foo');

    socket
      ..on(Socket.eventConnect, (List<dynamic> args) async {
        log.d('connect: $args');
        values.add(socket.id);
      });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], '/foo#${socket.io.engine.id}');
  });

  test('clearsSocketIdUponDisconnection', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket
      ..on(Socket.eventConnect, (List<dynamic> args) async {
        log.d('connect: $args');
        socket.on(Socket.eventDisconnect, (List<dynamic> args) {
          values.add(socket.id);
        });

        await socket.disconnect();
      });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], isNull);
  });

  test('doesNotFireConnectErrorIfWeForceDisconnectInOpeningState', () async {
    final List<dynamic> values = <dynamic>[];

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b..timeout = 100;
    });

    final Socket socket = Connection.client(options: options);

    socket
      ..on(Socket.eventConnectError, (List<dynamic> args) async {
        log.d('connect: $args');
        socket.on(Socket.eventDisconnect, (List<dynamic> args) {
          values.add(new StateError('Unexpected'));
        });
      });
    await socket.connect();
    await socket.disconnect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {
      values.add('done');
    });
    log.d(values.toString());

    if (values[0] is! String) throw values[0];
  });

  test('pingAndPongWithLatency', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();

    socket
      ..on(Socket.eventConnect, (List<dynamic> args) async {
        log.d('connect: $args');
        bool pinged = false;
        socket
          ..once(Socket.eventPing, (List<dynamic> args) {
            log.d('ping: $args');
            pinged = true;
          })
          ..once(Socket.eventPong, (List<dynamic> args) {
            log.d('pong: $args');
            final int ms = args[0];
            values.add(pinged);
            values.add(ms);
          });
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 4000), () {});
    log.d(values.toString());

    expect(values[0], isTrue);
    expect(values[1] > 0, isTrue);
  });

  test('shouldChangeSocketIdUponReconnection', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket
      ..on(Socket.eventConnect, (List<dynamic> args) async {
        log.d('connect: $args');
        values.add(socket.id);

        socket
          ..on(Socket.eventReconnectAttempt, (List<dynamic> args) {
            values.add(socket.id);
          })
          ..on(Socket.eventReconnect, (List<dynamic> args) {
            values.add(socket.id);
          });

        await socket.io.engine.close();
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 2000), () {});
    log.d(values.toString());

    expect(values[1], isNull);
    expect(values[2], isNot(values[0]));
  });

  test('shouldAcceptAQueryStringOnDefaultNamespace', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client(path: '/?c=d');
    await socket.emit('getHandshake', <Ack>[
      ([List<dynamic> args]) {
        values.add(args[0]);
      }
    ]);
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0]['query']['c'] == 'd', isTrue);
  });

  test('shouldAcceptAQueryString', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client(path: '/abc?b=c&d=e');
    socket.on('handshake', (List<dynamic> args) {
      log.d('handshake: $args');
      values.add(args[0]);
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    log.d(values.toString());

    expect(values[0]['query']['b'] == 'c', isTrue);
    expect(values[0]['query']['d'] == 'e', isTrue);
  });
}

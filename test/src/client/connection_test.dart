import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart' show Listener, Log;
import 'package:socket_io_client/src/client/manager.dart';
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/models/manager_event.dart';
import 'package:socket_io_client/src/models/manager_options.dart';
import 'package:socket_io_client/src/models/socket_event.dart';
import 'package:test/test.dart';
import 'package:utf/utf.dart';

import 'connection.dart';

void main() {
  final Log log = new Log('connection_test');

  test('connectionToLocalHost', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();

    socket
      ..on(SocketEvent.connect, (List<dynamic> args) async {
        socket
          ..on('echoBack', (List<dynamic> args) {
            log.d('echoBack: $args');
            values.add('done');
          });
        await socket.emit('echo');
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d('values $values');

    expect(values[0], 'done');
    await socket.close();
  });

  test('startTwoConnectionsWithSamePath', () async {
    final Socket socket1 = Connection.client(path: '/');
    final Socket socket2 = Connection.client(path: '/');

    expect(socket1.io != socket2.io, isTrue);
    await socket1.close();
    await socket2.close();
  });

  test('startTwoConnectionsWithSamePathAndDifferentQueryStrings', () async {
    final Socket socket1 = Connection.client(path: '/?woot');
    final Socket socket2 = Connection.client(path: '/');

    expect(socket1.io != socket2.io, isTrue);
    await socket1.close();
    await socket2.close();
  });

  test('workWithAcks', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      socket
        ..on('ack', (List<dynamic> ack) {
          log.d('ack $ack');
          ack[0](<dynamic>[
            5,
            <String, dynamic>{'test': true}
          ]);
        })
        ..on('ackBack', (List<dynamic> args) {
          log.d('ackBack: $args');
          if (args[0] == 5 && args[1]['test']) values.add('done');
        });
      await socket.emit('callAck');
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d('aa $values');
    expect(values.isNotEmpty, isTrue);
    await socket.close();
  });

  test('receiveDateWithAck', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect');
      await socket.emitAck('getAckDate', <Map>[
        <String, bool>{'test': true}
      ], ([List<dynamic> args]) {
        values.add(args);
      });
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values.isNotEmpty, isTrue);
    await socket.close();
  });

  test('sendBinaryAck', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> buff = encodeUtf8('huehue');

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect');
      socket
        ..on('ack', (List<dynamic> ack) {
          log.d('ack $ack');
          ack[0](buff);
        })
        ..on('ackBack', (List<dynamic> args) {
          log.d('ackBack: ${args[0]}');
          values.add(args[0]);
        });
      await socket.emit('callAckBinary');
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], buff);
    await socket.close();
  });

  test('receiveBinaryDataWithAck', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> buff = encodeUtf8('huehue');

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect');
      await socket.emitAck('getAckBinary', <String>[''], ([List<dynamic> args]) {
        log.d('getAckBinary $args');
        values.add(args[0]);
      });
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], buff);
    await socket.close();
  });

  test('workWithFalse', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect');
      socket
        ..on('echoBack', (List<dynamic> args) {
          values.add(args[0]);
        });
      await socket.emit('echo', <bool>[false]);
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], isFalse);
    await socket.close();
  });

  test('receiveUTF8MultibyteCharacters', () async {
    final List<dynamic> values = <dynamic>[];
    final List<String> correct = <String>['てすと', 'Я Б Г Д Ж Й', 'Ä ä Ü ü ß', 'utf8 — string', 'utf8 — string'];

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('connect');
      socket
        ..on('echoBack', (List<dynamic> args) {
          values.add(args[0]);
        });

      for (String value in correct) socket.emit('echo', <String>[value]);
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d('result: ${values.toList()}');
    expect(values, correct);
    await socket.close();
  });

  test('connectToNamespaceAfterConnectionEstablished', () async {
    final List<dynamic> values = <dynamic>[];
    final Manager manager = new Manager(url: Connection.uri);
    final Socket socket = manager.socket('/');
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      log.d('socket connect');
      final Socket foo = manager.socket('/foo');
      foo.on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('foo connect');
        await foo.close();
        await socket.close();
        await manager.close();
        values.add('done');
      });

      await foo.open();
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], 'done');
    await socket.close();
  });

  test('connectToNamespaceAfterConnectionGetsClosed', () async {
    final List<dynamic> values = <dynamic>[];
    final Manager manager = new Manager(url: Connection.uri);
    final Socket socket = manager.socket('/');
    socket
      ..on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('socket connect');
        await socket.close();
      })
      ..on(SocketEvent.disconnect, (List<dynamic> args) async {
        final Socket foo = manager.socket('/foo');
        foo.on(SocketEvent.connect, (List<dynamic> args) async {
          log.d('foo connect');
          await foo.close();
          await manager.close();
          values.add('done');
        });

        await foo.open();
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    expect(values[0], 'done');
    await socket.close();
  });

  test('reconnectByDefault', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket.io
      ..on(ManagerEvent.reconnecting, (List<dynamic> args) {
        log.d('reconnecting');
      })
      ..on(ManagerEvent.reconnect, (List<dynamic> args) async {
        log.d('reconnect');
        await socket.close();
        values.add('done');
      });
    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
      await socket.io.engine.close();
      log.d('close done');
    });
    await new Future<Null>.delayed(const Duration(milliseconds: 1500), () {});

    expect(values[0], 'done');
  });

  test('reconnectManually', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket
      ..once(SocketEvent.connect, (List<dynamic> args) async {
        await socket.disconnect();
      })
      ..once(SocketEvent.disconnect, (List<dynamic> args) async {
        socket.once(SocketEvent.connect, (List<dynamic> args) async {
          await socket.close();
          values.add('done');
        });
        await socket.connect();
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});

    expect(values[0], 'done');
  });

  test('reconnectAutomaticallyAfterReconnectingManually', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket
      ..once(SocketEvent.connect, (List<dynamic> args) async {
        await socket.disconnect();
      })
      ..once(SocketEvent.disconnect, (List<dynamic> args) async {
        socket
          ..on(SocketEvent.reconnect, (List<dynamic> args) async {
            await socket.close();
            values.add('done');
          });
        await socket.connect();
        await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
          await socket.io.engine.close();
          log.d('close done');
        });
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 3000), () {});

    expect(values[0], 'done');
  });

  test('attemptReconnectsAfterAFailedReconnect', () async {
    final List<dynamic> values = <dynamic>[];

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..reconnection = true
        ..timeout = 0
        ..reconnectionAttempts = 2
        ..reconnectionDelay = 10;
    });

    final Manager manager = new Manager(url: Connection.uri, options: options);
    final Socket socket = manager.socket('/timeout');
    socket
      ..once(SocketEvent.reconnectFailed, (List<dynamic> args) async {
        int reconnects = 0;

        manager
          ..on(ManagerEvent.reconnectAttempt, (List<dynamic> args) async => reconnects++)
          ..on(ManagerEvent.reconnectFailed, (List<dynamic> args) {
            values.add(reconnects);
          });

        await socket.connect();
      });
    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], 2);
    await socket.close();
    await manager.close();
  });

  test('reconnectDelayShouldIncreaseEveryTime', () async {
    int reconnects = 0;
    bool increasingDelay = true;
    int startTime = 0;
    int prevDelay = 0;

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..reconnection = true
        ..timeout = 0
        ..reconnectionAttempts = 3
        ..reconnectionDelay = 100
        ..randomizationFactor = 0.2;
    });

    final Manager manager = new Manager(url: Connection.uri, options: options);
    final Socket socket = manager.socket('/timeout');
    socket
      ..on(SocketEvent.connectError, (List<dynamic> args) {
        startTime = new DateTime.now().millisecondsSinceEpoch;
      })
      ..on(SocketEvent.reconnectAttempt, (List<dynamic> args) {
        reconnects++;
        final int currentTime = new DateTime.now().millisecondsSinceEpoch;
        final int delay = currentTime - startTime;

        if (delay <= prevDelay) {
          increasingDelay = false;
        }
        prevDelay = delay;
      });

    await socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    expect(reconnects, 3);
    expect(increasingDelay, isTrue);
    await socket.close();
    await manager.close();
  });

  test('reconnectEventFireInSocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket
      ..on(SocketEvent.reconnect, (List<dynamic> args) async {
        values.add('done');
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
      await socket.io.engine.close();
      log.d('close done');
    });

    await new Future<Null>.delayed(const Duration(milliseconds: 2000), () {});
    expect(values[0], 'done');
    await socket.close();
  });

  test('notReconnectWhenForceClosed', () async {
    final List<dynamic> values = <dynamic>[];

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..timeout = 0
        ..reconnectionDelay = 10;
    });

    final Socket socket = Connection.client(path: '/invalid', options: options);
    socket
      ..on(SocketEvent.connectError, (List<dynamic> args) async {
        socket
          ..on(SocketEvent.reconnectAttempt, (List<dynamic> args) {
            values.add(false);
          });

        await socket.disconnect();
        await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
          values.add(true);
        });
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 5000), () {});
    expect(values[0], isTrue);
  });

  test('stopReconnectingWhenForceClosed', () async {
    final List<dynamic> values = <dynamic>[];

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..timeout = 0
        ..reconnectionDelay = 10;
    });

    final Socket socket = Connection.client(path: '/invalid', options: options);
    socket
      ..once(SocketEvent.reconnectAttempt, (List<dynamic> args) async {
        socket.once(SocketEvent.reconnectAttempt, (List<dynamic> args) {
          values.add(false);
        });

        await socket.disconnect();
        await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
          values.add(true);
        });
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    expect(values[0], isTrue);
  });

  test('reconnectAfterStoppingReconnection', () async {
    final List<dynamic> values = <dynamic>[];

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..timeout = 0
        ..reconnectionDelay = 10;
    });

    final Socket socket = Connection.client(path: '/invalid', options: options, forceNew: true);
    socket
      ..once(SocketEvent.reconnectAttempt, (List<dynamic> args) async {
        socket.once(SocketEvent.reconnectAttempt, (List<dynamic> args) {
          values.add('done');
        });

        await socket.disconnect();
        await socket.connect();
      });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], 'done');
  });

  test('stopReconnectingOnASocketAndKeepToReconnectOnAnother', () async {
    final List<dynamic> values = <dynamic>[];

    final Manager manager = new Manager(url: Connection.uri);

    final Socket socket1 = manager.socket('/');
    final Socket socket2 = manager.socket('/asd');

    manager.on(ManagerEvent.reconnectAttempt, (List<dynamic> args) async {
      socket1.on(SocketEvent.connect, (List<dynamic> args) {
        values.add(false);
      });
      socket2.on(SocketEvent.connect, (List<dynamic> args) async {
        await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
          await socket2.disconnect();
          await manager.close();
          values.add(true);
        });
      });
      await socket1.disconnect();
    });
    await socket1.connect();
    await socket2.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {
      manager.engine.close();
    });

    await new Future<Null>.delayed(const Duration(milliseconds: 3000), () {});
    expect(values[0], true);
  });

  test('connectWhileDisconnectingAnotherSocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Manager manager = new Manager(url: Connection.uri);

    final Socket socket1 = manager.socket('/foo');

    socket1.on(SocketEvent.connect, (List<dynamic> args) async {
      final Socket socket2 = manager.socket('/asd');
      socket2.on(SocketEvent.connect, (List<dynamic> args) async {
        log.d('connect');
        values.add('done');
        await socket2.disconnect();
      });

      await socket2.open();
      await socket1.disconnect();
    });

    await socket1.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], 'done');
    await manager.close();
  });

  test('tryToReconnectTwiceAndFailWithIncorrectAddress', () async {
    final List<dynamic> values = <dynamic>[];
    int reconnects = 0;

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..reconnection = true
        ..reconnectionAttempts = 2
        ..reconnectionDelay = 10;
    });

    final Manager manager = new Manager(url: 'http://localhost:3940', options: options);
    final Socket socket = manager.socket('/asd');

    manager
      ..on(ManagerEvent.reconnectAttempt, (List<dynamic> args) {
        reconnects++;
      })
      ..on(ManagerEvent.reconnectFailed, (List<dynamic> args) {
        values.add(reconnects);
      });

    await socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], 2);
    await socket.close();
    await manager.close();
  });

  test('tryToReconnectTwiceAndFailWithImmediateTimeout', () async {
    final List<dynamic> values = <dynamic>[];
    int reconnects = 0;

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..reconnection = true
        ..timeout = 0
        ..reconnectionAttempts = 2
        ..reconnectionDelay = 10;
    });

    final Manager manager = new Manager(url: Connection.uri, options: options);
    Socket socket;
    manager
      ..on(ManagerEvent.reconnectAttempt, (List<dynamic> args) {
        reconnects++;
      })
      ..on(ManagerEvent.reconnectFailed, (List<dynamic> args) async {
        values.add(reconnects);
      });

    socket = manager.socket('/timeout');
    await socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], 2);
    await socket.close();
    await manager.close();
  });

  test('notTryToReconnectWithIncorrectPortWhenReconnectionDisabled', () async {
    final List<dynamic> values = <dynamic>[];

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b..reconnection = false;
    });

    final Manager manager = new Manager(url: 'http://localhost:9823', options: options);
    Socket socket;
    manager
      ..on(ManagerEvent.reconnectAttempt, (List<dynamic> args) async {
        await socket.close();
        await manager.close();
        throw new StateError('Not good, we should not try to reconnect.');
      })
      ..on(ManagerEvent.connectError, (List<dynamic> args) async {
        await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
          values.add('done');
        });
      });
    socket = manager.socket('/invalid');
    await socket.open();
    await new Future<Null>.delayed(const Duration(seconds: 2), () {});
    expect(values[0], 'done');
    await socket.close();
    await manager.close();
  });

  test('fireReconnectEventsOnSocket', () async {
    final List<dynamic> values = <dynamic>[];
    int reconnects = 0;

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..reconnection = true
        ..timeout = 0
        ..reconnectionAttempts = 2
        ..reconnectionDelay = 10;
    });

    final Manager manager = new Manager(url: Connection.uri, options: options);
    final Socket socket = manager.socket('/timeout_socket');
    manager
      ..on(ManagerEvent.reconnectAttempt, (List<dynamic> args) async {
        log.d('reconnectionAttmept $args');
        reconnects++;
        values.add(args[0]);
      })
      ..on(ManagerEvent.reconnectFailed, (List<dynamic> args) async {
        log.d('reconnectFailed $args');
        await socket.close();
        await manager.close();
        values.add(reconnects);
      });
    await socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());
    expect(values[1], reconnects);
    expect(values[2], 2);
  });

  test('fireReconnectingWithAttemptsNumberWhenReconnectingTwice', () async {
    final List<dynamic> values = <dynamic>[];
    int reconnects = 0;

    final ManagerOptions options = new ManagerOptions((ManagerOptionsBuilder b) {
      b
        ..reconnection = true
        ..timeout = 0
        ..reconnectionAttempts = 2
        ..reconnectionDelay = 10;
    });

    final Manager manager = new Manager(url: Connection.uri, options: options);
    final Socket socket = manager.socket('/timeout_socket');
    manager
      ..on(ManagerEvent.reconnecting, (List<dynamic> args) async {
        log.d('reconnecting $args');
        reconnects++;
        values.add(args[0]);
      })
      ..on(ManagerEvent.reconnectFailed, (List<dynamic> args) async {
        log.d('reconnectFailed $args');
        await socket.close();
        await manager.close();
        values.add(reconnects);
      });
    await socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());
    expect(values[1], reconnects);
    expect(values[2], 2);
  });

  test('emitDateAsString', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      socket
        ..on('echoBack', (List<dynamic> args) {
          log.d('echoBack: $args');
          values.add(args[0]);
        });
      await socket.emit('echo', <DateTime>[new DateTime.now()]);
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values[0]);
    expect(values[0] is String, isTrue);
    await socket.close();
  });

  test('emitDateInObject', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      socket.on('echoBack', (List<dynamic> args) {
        log.d('echoBack: $args');
        values.add(args[0]);
      });
      await socket.emit('echo', <Map<String, dynamic>>[
        <String, dynamic>{'date': new DateTime.now()}
      ]);
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values[0]);

    expect(values[0] is Map, isTrue);
    expect(values[0]['date'] is String, isTrue);
    await socket.close();
  });

  test('sendAndGetBinaryData', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> buffer = encodeUtf8('asdfasdf');

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      socket.on('echoBack', (List<dynamic> args) {
        log.d('echoBack: $args');
        values.add(args[0]);
      });
      await socket.emit('echo', <List<int>>[buffer]);
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values[0].toString());

    expect(values[0], buffer);
    await socket.close();
  });

  test('sendBinaryDataMixedWithJson', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> buffer = encodeUtf8('howdy');

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      socket
        ..on('echoBack', (List<dynamic> args) {
          log.d('echoBack: $args');
          values.add(args[0]);
        });
      await socket.emit('echo', <Map<String, dynamic>>[
        <String, dynamic>{'hello': 'lol', 'message': buffer, 'goodbye': 'gotcha'}
      ]);
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values[0]);

    expect(values[0]['hello'], 'lol');
    expect(values[0]['message'], buffer);
    expect(values[0]['goodbye'], 'gotcha');
    await socket.close();
  });

  test('sendEventsWithByteArraysInTheCorrectOrder', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> buffer = encodeUtf8('abuff1');

    final Socket socket = Connection.client();
    socket.on(SocketEvent.connect, (List<dynamic> args) async {
      socket.on('echoBack', (List<dynamic> args) {
        log.d('echoBack: $args');
        values.add(args[0]);
      });
      await socket.emit('echo', <List<int>>[buffer]);
      await socket.emit('echo', <String>['please arrive second']);
    });
    await socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], buffer);
    expect(values[1], 'please arrive second');

    await socket.close();
  });
}

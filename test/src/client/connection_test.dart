import 'dart:async';

import 'package:engine_io_client/engine_io_client.dart' show Log;
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:socket_io_client/src/client/socket.dart';
import 'package:test/test.dart';
import 'package:utf/utf.dart';

import 'connection.dart';

void main() {
  final Log log = new Log('Socket.Io.connection_test');

  test('connectionToLocalHost', () async {
    final Socket socket = Connection.client(path: '/');

    final Observable<Event> event$ = socket.on('echoBack').map((Event event) => new Event(event.name));
    socket
        .on(Socket.eventConnect)
        .doOnData((Event event) => log.e(event))
        .doOnData((Event event) => socket.emit('echo'))
        .listen(null);

    socket.open();
    expect(event$, emits(new Event('echoBack')));
  });

  test('startTwoConnectionsWithSamePath', () async {
    final Socket socket1 = Connection.client(path: '/');
    final Socket socket2 = Connection.client(path: '/');

    expect(socket1.io != socket2.io, isTrue);
  });

  test('startTwoConnectionsWithSamePathAndDifferentQueryStrings', () async {
    final Socket socket1 = Connection.client(path: '/?woot');
    final Socket socket2 = Connection.client(path: '/');

    expect(socket1.io != socket2.io, isTrue);
  });

  test('workWithAcks', () async {
    final Socket socket = Connection.client();

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.on('ack').doOnData((Event event) {
        log.e('ack ${event.args}');
        event.args[0](<dynamic>[
          5,
          <String, dynamic>{'test': true}
        ]);
      }).ignoreElements(),
      socket.on('ackBack').doOnData((Event event) {
        log.d('ackBack: ${event.args}');
        log.e(event.args[0] == 5 && event.args[1]['test']);
      })
    ]);

    socket.on(Socket.eventConnect).listen((Event event) => socket.emit('callAck'));

    socket.connect();

    expect(
        events$,
        emits(new Event('ackBack', <dynamic>[
          5,
          <String, dynamic>{'test': true}
        ])));
  });

  test('receiveDateWithAck', () async {
    final Socket socket = Connection.client();

    DateTime dateTime;
    socket
        .on(Socket.eventConnect)
        .flatMap(
          (Event event) => socket.emit(
              'getAckDate',
              <Map<String, bool>>[
                <String, bool>{'test': true}
              ],
              true),
        )
        .listen((List<dynamic> date) => dateTime = DateTime.parse(date[0]));

    socket.connect();

    await new Future.delayed(const Duration(milliseconds: 500), () {});

    log.d(dateTime);
    expect(dateTime, isNotNull);
  });

  test('sendBinaryAck', () async {
    final List<int> buff = encodeUtf8('huehue');

    final Socket socket = Connection.client();

    final Observable<dynamic> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.on('ack').doOnData((Event event) {
        log.w(event);
        final Ack ack = event.args[0];
        ack(<List<int>>[buff]);
      }).ignoreElements(),
      socket.on('ackBack').map((Event event) => event.args[0])
    ]);

    socket.on(Socket.eventConnect).flatMap<dynamic>((Event event) => socket.emit('callAckBinary', null, true)).listen(null);

    socket.connect();

    expect(events$, emits(buff));
  });

  test('receiveBinaryDataWithAck', () async {
    final List<int> buff = encodeUtf8('huehue');

    final Socket socket = Connection.client();

    final Observable<dynamic> events$ =
        socket.on(Socket.eventConnect).flatMap<dynamic>((Event event) => socket.emit('getAckBinary', <String>[''], true));
    socket.connect();

    expect(events$, emits(<List<int>>[buff]));
  });

  test('workWithFalse', () async {
    final Socket socket = Connection.client();

    final Observable<Event> events$ = socket.on('echoBack').map((Event event) => event.args[0]);

    socket.on(Socket.eventConnect).flatMap<dynamic>((Event event) => socket.emit('echo', <bool>[false])).listen(null);

    socket.connect();

    expect(events$, emits(false));
  });

  test('receiveUTF8MultibyteCharacters', () async {
    final List<String> correct = <String>['てすと', 'Я Б Г Д Ж Й', 'Ä ä Ü ü ß', 'utf8 — string', 'utf8 — string'];
    final Socket socket = Connection.client();
    final Observable<Event> events$ = socket.on('echoBack').map((Event event) => event.args[0]);
    socket
        .on(Socket.eventConnect)
        .flatMap((Event _) => new Observable<String>.fromIterable(correct))
        .flatMap<dynamic>((String data) => socket.emit('echo', <String>[data]))
        .listen(null);

    socket.connect();

    expect(events$, emitsInOrder(correct));
  });

  test('connectToNamespaceAfterConnectionEstablished', () async {
    final Manager manager = new Manager(url: Connection.uri);
    final Socket socket = manager.socket('/');

    final Observable<String> events$ = socket.on(Socket.eventConnect).flatMap((Event event) {
      final Socket foo = manager.socket('/foo');
      final Observable<String> connect$ = foo.on(Socket.eventConnect).map((Event event) => event.name);
      foo.open();
      return connect$;
    });

    socket.connect();

    expect(events$, emits(Socket.eventConnect));
  });

  test('connectToNamespaceAfterConnectionGetsClosed', () async {
    final Manager manager = new Manager(url: Connection.uri);
    final Socket socket = manager.socket('/');

    final Observable<String> events$ = socket
        .on(Socket.eventConnect)
        .flatMap((Event event) {
          final Observable<Event> disconnect$ = socket.on(Socket.eventDisconnect);
          socket.close();
          return disconnect$;
        })
        .map((Event _) => manager.socket('/foo'))
        .flatMap((Socket foo) {
          final Observable<String> connect$ = foo.on(Socket.eventConnect).map((Event event) => event.name);
          foo.open();
          return connect$;
        });

    socket.connect();

    expect(events$, emits(Socket.eventConnect));
  });

  test('reconnectByDefault', () async {
    final Socket socket = Connection.client();

    final Observable<Event> events$ = new Observable<dynamic>.merge(<Observable<dynamic>>[
      new Observable<String>.timer('', const Duration(seconds: 1))
          .doOnData((String _) => socket.io.engine.close())
          .ignoreElements(),
      socket.io.on(Manager.eventReconnect)
    ]);

    socket.connect();

    expect(events$, emits(new Event(Manager.eventReconnect, <int>[1])));
  });

  test('reconnectManually', () async {
    final Socket socket = Connection.client();

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.once(Socket.eventConnect).doOnData((Event event) => socket.disconnect()).ignoreElements(),
      socket
          .once(Socket.eventDisconnect)
          .doOnData((Event event) => socket.connect())
          .flatMap((Event event) => socket.once(Socket.eventConnect))
          .map((Event event) => new Event('socket connected')),
    ]);

    socket.connect();

    expect(events$, emits(new Event('socket connected')));
  });

  test('reconnectAutomaticallyAfterReconnectingManually', () async {
    final Socket socket = Connection.client();

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket.once(Socket.eventConnect).doOnData((Event event) => socket.disconnect()).ignoreElements(),
      socket
          .once(Socket.eventDisconnect)
          .doOnData((Event event) => socket.connect())
          .flatMap((Event event) => new Observable<Event>.timer(new Event(''), const Duration(milliseconds: 500)))
          .doOnData((Event event) => socket.io.engine.close())
          .ignoreElements(),
      socket.on(Socket.eventReconnect).map((Event event) => new Event('socket connected')),
    ]);

    socket.connect();

    expect(events$, emits(new Event('socket connected')));
  });

  test('attemptReconnectsAfterAFailedReconnect', () async {
    const ManagerOptions options = const ManagerOptions(
      reconnection: true,
      timeout: 0,
      reconnectionAttempts: 3,
      reconnectionDelay: 10,
    );

    final Manager manager = new Manager(url: Connection.uri, options: options);
    final Socket socket = manager.socket('/timeout');

    final Observable<Event> events$ = manager.on(Manager.eventReconnectAttempt);

    socket.once(Socket.eventReconnectFailed).doOnData((Event event) => socket.connect()).listen(null);
    socket.connect();

    expect(
        events$,
        emitsInOrder(<Event>[
          new Event(Manager.eventReconnectAttempt, <int>[1]),
          new Event(Manager.eventReconnectAttempt, <int>[2]),
          new Event(Manager.eventReconnectAttempt, <int>[3]),
        ]));
  });

  test('reconnectDelayShouldIncreaseEveryTime', () async {
    int reconnects = 0;
    bool increasingDelay = true;
    int startTime = 0;
    int prevDelay = 0;

    const ManagerOptions options = const ManagerOptions(
      reconnection: true,
      timeout: 0,
      reconnectionAttempts: 3,
      reconnectionDelay: 100,
      randomizationFactor: 0.2,
    );

    final Manager manager = new Manager(url: Connection.uri, options: options);
    final Socket socket = manager.socket('/timeout');

    socket.on(Socket.eventConnectError).listen((Event event) {
      startTime = new DateTime.now().millisecondsSinceEpoch;
    });

    socket.on(Socket.eventReconnectAttempt).listen((Event event) {
      reconnects++;
      final int currentTime = new DateTime.now().millisecondsSinceEpoch;
      final int delay = currentTime - startTime;

      if (delay <= prevDelay) {
        increasingDelay = false;
      }
      prevDelay = delay;
    });

    socket.connect();
    await new Future<Null>.delayed(const Duration(milliseconds: 1000), () {});
    expect(reconnects, 3);
    expect(increasingDelay, isTrue);
  });

  test('reconnectEventFireInSocket', () async {
    final List<dynamic> values = <dynamic>[];

    final Socket socket = Connection.client();
    socket.on(Socket.eventReconnect).listen((Event event) => values.add('done'));
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
      socket.io.engine.close();
      log.d('close done');
    });

    await new Future<Null>.delayed(const Duration(milliseconds: 2000), () {});
    expect(values[0], 'done');
    socket.close();
  });

  test('notReconnectWhenForceClosed', () async {
    const ManagerOptions options = const ManagerOptions(timeout: 0, reconnectionDelay: 10);

    final Socket socket = Connection.client(path: '/invalid', options: options);

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      new Observable<Event>.timer(new Event('not reconnecting'), const Duration(seconds: 1)),
      socket.on(Socket.eventReconnectAttempt).map((Event event) => new Event(event.name))
    ]);

    socket.on(Socket.eventConnectError).listen((Event event) => socket.disconnect());

    socket.connect();

    expect(events$, emits(new Event('not reconnecting')));
  });

  test('reconnectAfterStoppingReconnection', () async {
    const ManagerOptions options = const ManagerOptions(timeout: 0, reconnectionDelay: 10);
    final Socket socket = Connection.client(path: '/invalid', options: options, forceNew: true);

    final Observable<Event> events$ = socket.on(Socket.eventReconnectAttempt).map((Event event) => new Event(event.name)).take(2);

    socket.on(Socket.eventConnectError).listen((Event event) {
      socket.disconnect();
      socket.connect();
    });

    socket.connect();

    expect(
        events$,
        emitsInOrder(<dynamic>[
          new Event(Socket.eventReconnectAttempt),
          new Event(Socket.eventReconnectAttempt),
          emitsDone,
        ]));
  });

  test('stopReconnectingOnASocketAndKeepToReconnectOnAnother', () async {
    final Manager manager = new Manager(url: Connection.uri);

    final Socket socket1 = manager.socket('/');
    final Socket socket2 = manager.socket('/asd');

    final Observable<Event> events$ = new Observable<Event>.merge(<Observable<Event>>[
      socket1.on(Socket.eventConnect).map((Event event) => new Event(event.name, <int>[1])).ignoreElements(),
      socket2.on(Socket.eventConnect).map((Event event) => new Event(event.name, <int>[2])),
    ]);

    manager.on(Manager.eventOpen).listen((Event event) {
      socket1.connect();
      socket2.connect();
    });
    manager.open();

    manager.on(Manager.eventReconnectAttempt).doOnData(log.w).listen((Event event) => socket1.disconnect());
    await new Future<void>.delayed(const Duration(milliseconds: 1000), () => manager.engine.close());

    expect(events$, emits(new Event(Socket.eventConnect, <int>[2])));
  });

  test('connectWhileDisconnectingAnotherSocket', () async {
    final Manager manager = new Manager(url: Connection.uri);
    final Socket socket1 = manager.socket('/foo');
    final Socket socket2 = manager.socket('/asd');

    final Observable<Event> events$ = socket2.on(Socket.eventConnect);
    socket1.on(Socket.eventConnect).listen((Event event) {
      socket2.open();
      socket1.close();
    });

    socket1.open();

    expect(events$, emits(new Event(Socket.eventConnect, <dynamic>[])));
  });

  test('tryToReconnectTwiceAndFailWithIncorrectAddress', () async {
    final List<dynamic> values = <dynamic>[];
    int reconnects = 0;

    const ManagerOptions options = const ManagerOptions(reconnection: true, reconnectionAttempts: 2, reconnectionDelay: 10);

    final Manager manager = new Manager(url: 'http://localhost:3940', options: options);
    final Socket socket = manager.socket('/asd');

    manager.on(Manager.eventReconnectAttempt).listen((_) => reconnects++);
    manager.on(Manager.eventReconnectFailed).listen((_) => values.add(reconnects));

    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], 2);
  });

  test('tryToReconnectTwiceAndFailWithImmediateTimeout', () async {
    final List<dynamic> values = <dynamic>[];
    int reconnects = 0;

    const ManagerOptions options = const ManagerOptions(
      reconnection: true,
      timeout: 0,
      reconnectionAttempts: 2,
      reconnectionDelay: 10,
    );

    final Manager manager = new Manager(url: Connection.uri, options: options);

    manager.on(Manager.eventReconnectAttempt).listen((_) => reconnects++);
    manager.on(Manager.eventReconnectFailed).listen((_) => values.add(reconnects));

    final Socket socket = manager.socket('/timeout');
    socket.open();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    expect(values[0], 2);
  });

  test('notTryToReconnectWithIncorrectPortWhenReconnectionDisabled', () async {
    final List<dynamic> values = <dynamic>[];

    const ManagerOptions options = const ManagerOptions(reconnection: false);

    final Manager manager = new Manager(url: 'http://localhost:9823', options: options);
    Socket socket;
    manager.on(Manager.eventReconnectAttempt).listen((_) {
      throw new StateError('Not good, we should not try to reconnect.');
    });
    manager.on(Manager.eventConnectError).listen((Event event) async {
      await new Future<Null>.delayed(const Duration(milliseconds: 500), () async {
        values.add('done');
      });
    });

    socket = manager.socket('/invalid');
    socket.open();
    await new Future<Null>.delayed(const Duration(seconds: 2), () {});
    expect(values[0], 'done');
  });

  test('fireReconnectEventsOnSocket', () async {
    final List<dynamic> values = <dynamic>[];
    int reconnects = 0;

    const ManagerOptions options = const ManagerOptions(
      reconnection: true,
      timeout: 0,
      reconnectionAttempts: 2,
      reconnectionDelay: 10,
    );

    final Manager manager = new Manager(url: Connection.uri, options: options);
    final Socket socket = manager.socket('/timeout_socket');
    manager.on(Manager.eventReconnectAttempt).listen((Event event) async {
      log.d('reconnectionAttempt ${event.args}');
      reconnects++;
      values.add(event.args[0]);
    });
    manager.on(Manager.eventReconnectFailed).listen((Event event) async {
      log.d('reconnectFailed ');
      values.add(reconnects);
    });
    socket.open();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());
    expect(values[1], reconnects);
    expect(values[2], 2);
  });

  test('fireReconnectingWithAttemptsNumberWhenReconnectingTwice', () async {
    final List<dynamic> values = <dynamic>[];
    int reconnects = 0;

    const ManagerOptions options = const ManagerOptions(
      reconnection: true,
      timeout: 0,
      reconnectionAttempts: 2,
      reconnectionDelay: 10,
    );
    final Manager manager = new Manager(url: Connection.uri, options: options);
    final Socket socket = manager.socket('/timeout_socket');
    manager.on(Manager.eventReconnecting).listen((Event event) async {
      log.d('reconnecting ${event.args}');
      reconnects++;
      values.add(event.args[0]);
    });
    manager.on(Manager.eventReconnectFailed).listen((Event event) async {
      log.d('reconnectFailed');
      values.add(reconnects);
    });
    socket.open();
    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());
    expect(values[1], reconnects);
    expect(values[2], 2);
  });

  test('emitDateAsString', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((Event args) async {
      socket.on('echoBack').listen((Event event) {
        log.d('echoBack: ${event.args}');
        values.add(event.args[0]);
      });
      socket.emit('echo', <DateTime>[new DateTime.now()]);
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values[0]);
    expect(values[0] is String, isTrue);
  });

  test('emitDateInObject', () async {
    final List<dynamic> values = <dynamic>[];
    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((Event event) async {
      socket.on('echoBack').listen((Event event) {
        log.d('echoBack: ${event.args}');
        values.add(event.args[0]);
      });
      socket.emit('echo', <Map<String, dynamic>>[
        <String, dynamic>{'date': new DateTime.now()},
        <String, dynamic>{'date': new DateTime.now()}
      ]);
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values[0]);

    expect(values[0] is Map, isTrue);
    expect(values[0]['date'] is String, isTrue);
  });

  test('sendAndGetBinaryData', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> buffer = encodeUtf8('asdfasdf');

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((Event event) async {
      socket.on('echoBack').listen((Event event) {
        log.d('echoBack: ${event.args}');
        values.add(event.args[0]);
      });
      socket.emit('echo', <dynamic>[buffer]);
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values);

    //expect(values[0], buffer);
  });

  test('sendBinaryDataMixedWithJson', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> buffer = encodeUtf8('howdy');

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((Event event) async {
      socket
        ..on('echoBack').listen((Event event) {
          log.d('echoBack: ${event.args}');
          values.add(event.args[0]);
        });
      socket.emit('echo', <Map<String, dynamic>>[
        <String, dynamic>{
          'hello': 'lol',
          'message': buffer,
          'goodbye': 'gotcha',
        }
      ]);
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values[0]);

    expect(values[0]['hello'], 'lol');
    expect(values[0]['message'], buffer);
    expect(values[0]['goodbye'], 'gotcha');
  });

  test('sendEventsWithByteArraysInTheCorrectOrder', () async {
    final List<dynamic> values = <dynamic>[];
    final List<int> buffer = encodeUtf8('abuff1');

    final Socket socket = Connection.client();
    socket.on(Socket.eventConnect).listen((Event event) async {
      socket.on('echoBack').listen((Event event) {
        log.d('echoBack: ${event.args}');
        values.add(event.args[0]);
      });
      socket.emit('echo', <List<int>>[buffer]);
      socket.emit('echo', <String>['please arrive second']);
    });
    socket.connect();

    await new Future<Null>.delayed(const Duration(milliseconds: 500), () {});
    log.d(values.toString());

    expect(values[0], buffer);
    expect(values[1], 'please arrive second');
  });
}

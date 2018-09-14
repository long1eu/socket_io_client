import 'package:engine_io_client/engine_io_client.dart' show Log;
import 'package:socket_io_client/src/client/manager.dart';
import 'package:socket_io_client/src/client/socket.dart';
import 'package:socket_io_client/src/client/url.dart';
import 'package:socket_io_client/src/models/manager_options.dart';

class Io {
  static final Log log = new Log('Io');

  Io._();

  static final Map<String, Manager> managers = <String, Manager>{};

  static Socket socket(String uri, [ManagerOptions options, bool forceNew, bool multiplex]) {
    forceNew ??= false;
    multiplex ??= true;
    options = options ?? const ManagerOptions();

    final Uri source = Url.parse(uri);
    final String id = Url.extractId(source.toString());
    final String path = source.path;

    final bool sameNamespace = managers.containsKey(id) && managers[id].namespaces.containsKey(path);
    final bool newConnection = forceNew || !multiplex || sameNamespace;
    Manager io;

    if (newConnection) {
      log.d('ignoring socket cache for $source');
      io = new Manager(url: source.toString(), options: options);
    } else {
      if (!managers.containsKey(id)) {
        log.d('new io instance for $source');
        managers.putIfAbsent(id, () => new Manager(url: source.toString(), options: options));
      }
      io = managers[id];
    }

    final String query = source.query;
    if (query != null && (options.rawQuery == null || options.rawQuery.isEmpty)) {
      options = options.copyWith(rawQuery: query);
    }
    log.d(io);

    return io.socket(source.path, options);
  }
}

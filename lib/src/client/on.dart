import 'package:engine_io_client/engine_io_client.dart';

typedef bool OnDestroy();

class On {
  static final Log log = new Log('On');

  factory On(Emitter emitter, String event, Listener callback) {
    emitter.on(event, callback);
    return new On._(emitter, event, callback);
  }

  const On._(this.emitter, this.event, this.callback);

  final Emitter emitter;
  final String event;

  final Listener callback;

  bool destroy() {
    log.d('destroy: $event');
    emitter.off(event, callback);
    return true;
  }
}

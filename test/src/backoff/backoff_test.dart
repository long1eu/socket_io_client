import 'dart:math' as math;

import 'package:socket_io_client/src/backoff/backoff.dart';
import 'package:test/test.dart';

void main() {
  test('durationShouldIncreaseTheBackoff', () {
    final Backoff backoff = new Backoff();

    expect(backoff.duration(), 100);
    expect(backoff.duration(), 200);
    expect(backoff.duration(), 400);
    expect(backoff.duration(), 800);

    backoff.reset();
    expect(backoff.duration(), 100);
    expect(backoff.duration(), 200);
  });

  test('durationOverflow', () {
    for (int i = 0; i < 10; i++) {
      final Backoff backoff = new Backoff()
        ..ms = 100
        ..max = 10000
        ..jitter = 0.5;

      for (int j = 0; j < 100; j++) {
        final int ms = 100 * math.pow(2, j);
        final int deviation = (ms * 0.5).toInt();
        final int duration = backoff.duration();

        final int min = math.min(ms - deviation, 10000);
        final int max = math.min(ms + deviation, 10001);

        final bool v1 = min <= duration && duration < max;
        final bool v2 = min.compareTo(duration) <= 0 && max.compareTo(duration) == 1;

        expect(v1, v2);
      }
    }
  });
}

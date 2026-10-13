import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:waky/features/alarms/application/alarm_scheduler.dart';
import 'package:waky/features/alarms/domain/uyg_alarm.dart';
import 'package:waky/features/challenges/application/math_generator.dart';
import 'package:waky/features/challenges/application/typing_sentences.dart';
import 'package:waky/features/challenges/domain/challenge_type.dart';

void main() {
  test('math questions have correct, non-negative answers', () {
    final g = MathGenerator(Random(1));
    for (final d in Difficulty.values) {
      for (var i = 0; i < 200; i++) {
        final q = g.next(d);
        final parts = q.text.split(' ');
        final a = int.parse(parts[0]), b = int.parse(parts[2]);
        final expected = switch (parts[1]) {
          '+' => a + b,
          '−' => a - b,
          '×' => a * b,
          _ => throw StateError(q.text),
        };
        expect(q.answer, expected);
        expect(q.answer, greaterThanOrEqualTo(0));
      }
    }
  });

  test('typing match ignores case, spacing and apostrophe glyphs', () {
    expect(sentenceMatches("  o‘rningdan   TUR ", "O'rningdan tur"), isTrue);
    expect(sentenceMatches('rise', 'rise and shine'), isFalse);
  });

  test('one-shot alarm rolls to tomorrow when time has passed', () {
    final a = UygAlarm(id: 1, hour: 6, minute: 30);
    final from = DateTime(2026, 10, 11, 7, 0);
    expect(a.nextOccurrence(from), DateTime(2026, 10, 12, 6, 30));
    expect(a.nextOccurrence(DateTime(2026, 10, 11, 5, 0)),
        DateTime(2026, 10, 11, 6, 30));
  });

  test('weekday occurrence lands on the right day', () {
    final a = UygAlarm(id: 1, hour: 6, minute: 30, days: {1, 5});
    final from = DateTime(2026, 10, 11, 7, 0); // a Sunday
    expect(a.nextOccurrenceOn(DateTime.monday, from), DateTime(2026, 10, 12, 6, 30));
    expect(a.nextOccurrenceOn(DateTime.friday, from), DateTime(2026, 10, 16, 6, 30));
    expect(a.nextOccurrence(from), DateTime(2026, 10, 12, 6, 30));
  });

  test('disabled alarm has no next occurrence; json round-trips', () {
    final a = UygAlarm(id: 3, hour: 1, minute: 2, enabled: false, days: {2});
    expect(a.nextOccurrence(), isNull);
    final b = UygAlarm.fromJson(a.toJson());
    expect(b.toJson(), a.toJson());
  });

  test('native id packing and payload round-trip', () {
    final id = AlarmScheduler.idFor(42, 5);
    expect(AlarmScheduler.alarmIdOf(id), 42);
    expect(AlarmScheduler.slotOf(id), 5);
    final p = RingPayload.decode(const RingPayload(42, RingKind.snooze, 2).encode())!;
    expect((p.alarmId, p.kind, p.snoozesUsed), (42, RingKind.snooze, 2));
  });
}

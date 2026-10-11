import '../features/alarms/data/alarm_repository.dart';
import '../features/alarms/domain/uyg_alarm.dart';
import '../features/challenges/domain/challenge_type.dart';
import 'storage.dart';

/// Compile-time opt-in (`--dart-define=SEED_DEMO=true`) used only to take
/// store screenshots: fills an empty app with realistic sample alarms.
const kSeedDemo = bool.fromEnvironment('SEED_DEMO', defaultValue: false);

Future<void> seedDemoData() async {
  if (!kSeedDemo) return;
  await Storage.settings.put('onboarded', true);
  final repo = AlarmRepository();
  if (repo.all().isNotEmpty) return;
  final alarms = [
    UygAlarm(
      id: await repo.nextId(),
      hour: 6,
      minute: 30,
      label: 'Ish',
      days: {1, 2, 3, 4, 5},
      challenge: ChallengeType.math,
      difficulty: Difficulty.medium,
    ),
    UygAlarm(
      id: await repo.nextId(),
      hour: 7,
      minute: 45,
      label: 'Sport',
      days: {6, 7},
      challenge: ChallengeType.shake,
      shakeCount: 30,
    ),
    UygAlarm(
      id: await repo.nextId(),
      hour: 5,
      minute: 50,
      label: 'Yugurish',
      days: {1, 3, 5},
      challenge: ChallengeType.walk,
      walkMeters: 50,
    ),
    UygAlarm(
      id: await repo.nextId(),
      hour: 8,
      minute: 15,
      label: 'Hammom',
      enabled: false,
      challenge: ChallengeType.qr,
      scanValue: 'uygon-demo',
    ),
  ];
  for (final a in alarms) {
    await repo.save(a);
  }
}

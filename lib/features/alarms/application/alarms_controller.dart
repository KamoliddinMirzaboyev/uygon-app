import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../settings/application/settings_controller.dart';
import '../data/alarm_repository.dart';
import '../domain/uyg_alarm.dart';
import 'alarm_scheduler.dart';

final alarmRepositoryProvider = Provider((_) => AlarmRepository());
final alarmSchedulerProvider = Provider((_) => AlarmScheduler());

class AlarmsController extends Notifier<List<UygAlarm>> {
  AlarmRepository get _repo => ref.read(alarmRepositoryProvider);
  AlarmScheduler get _scheduler => ref.read(alarmSchedulerProvider);
  L10n get _t => ref.read(l10nProvider);

  @override
  List<UygAlarm> build() => _repo.all();

  /// A blank alarm pre-filled from the user's defaults.
  Future<UygAlarm> create() async {
    final s = ref.read(settingsProvider);
    final now = DateTime.now().add(const Duration(hours: 1));
    return UygAlarm(
      id: await _repo.nextId(),
      hour: now.hour,
      minute: 0,
      challenge: s.defaultChallenge,
      snoozeMinutes: s.defaultSnoozeMinutes,
      maxSnoozes: s.defaultMaxSnoozes,
      wakeCheck: s.defaultWakeCheck,
    );
  }

  Future<void> upsert(UygAlarm a) async {
    await _repo.save(a);
    await _scheduler.schedule(a, _t);
    state = _repo.all();
  }

  Future<void> toggle(UygAlarm a, bool enabled) =>
      upsert(a.copyWith(enabled: enabled));

  Future<void> remove(UygAlarm a) async {
    await _scheduler.cancel(a.id);
    await _repo.delete(a.id);
    state = _repo.all();
  }

  /// Re-arms anything the OS may have lost. Called on startup and resume.
  Future<void> reconcile() async {
    await _scheduler.reconcile(_repo.all(), _t);
    state = _repo.all();
  }

  /// A one-shot alarm that has rung is switched off.
  Future<void> markOneShotDone(int alarmId) async {
    final a = _repo.byId(alarmId);
    if (a == null || a.isRepeating || !a.enabled) return;
    await _repo.save(a.copyWith(enabled: false));
    state = _repo.all();
  }
}

final alarmsProvider =
    NotifierProvider<AlarmsController, List<UygAlarm>>(AlarmsController.new);

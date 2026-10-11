import 'dart:convert';

import 'package:alarm/alarm.dart';

import '../../../core/l10n.dart';
import '../domain/uyg_alarm.dart';

/// What kind of ring an [AlarmSettings] represents.
enum RingKind { ring, snooze, check }

class RingPayload {
  const RingPayload(this.alarmId, this.kind, [this.snoozesUsed = 0]);

  final int alarmId;
  final RingKind kind;
  final int snoozesUsed;

  String encode() =>
      jsonEncode({'a': alarmId, 'k': kind.name, 'n': snoozesUsed});

  static RingPayload? decode(String? s) {
    if (s == null) return null;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return RingPayload(
        j['a'] as int,
        RingKind.values.asNameMap()[j['k']] ?? RingKind.ring,
        (j['n'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Maps [UygAlarm]s onto the `alarm` package, which owns exact scheduling,
/// the foreground service, audio, the full-screen intent and boot recovery.
///
/// Each Uyg'on alarm owns up to ten native alarm ids: `id * 10 + slot`.
///   slot 0     one-shot alarm
///   slot 1..7  one entry per repeat weekday (ISO weekday number)
///   slot 8     pending snooze
///   slot 9     pending wake-up check
/// Scheduling every weekday separately means a repeating alarm keeps working
/// for the rest of the week even if the app is never opened again.
class AlarmScheduler {
  static const snoozeSlot = 8;
  static const checkSlot = 9;

  static int idFor(int alarmId, int slot) => alarmId * 10 + slot;
  static int alarmIdOf(int nativeId) => nativeId ~/ 10;
  static int slotOf(int nativeId) => nativeId % 10;

  /// Cancels every native alarm of [alarmId] and schedules it again.
  Future<void> schedule(UygAlarm a, L10n t, {DateTime? now}) async {
    await cancel(a.id);
    if (!a.enabled) return;
    if (a.isRepeating) {
      for (final d in a.days) {
        await _set(a, idFor(a.id, d), a.nextOccurrenceOn(d, now), t);
      }
    } else {
      await _set(a, idFor(a.id, 0), a.nextOccurrence(now)!, t);
    }
  }

  /// Makes sure every slot of every enabled alarm is armed. Safe to call on
  /// each app start: it never touches an alarm that is currently ringing or
  /// already armed for the future.
  Future<void> reconcile(List<UygAlarm> alarms, L10n t) async {
    final armed = {
      for (final s in await Alarm.getAlarms()) s.id: s,
    };
    final now = DateTime.now();
    for (final a in alarms) {
      if (!a.enabled) continue;
      final slots = a.isRepeating ? a.days : {0};
      for (final slot in slots) {
        final nid = idFor(a.id, slot);
        final existing = armed[nid];
        if (existing != null && existing.dateTime.isAfter(now)) continue;
        if (await Alarm.isRinging(nid)) continue;
        final when = slot == 0
            ? a.nextOccurrence(now)!
            : a.nextOccurrenceOn(slot, now);
        await _set(a, nid, when, t);
      }
    }
  }

  Future<void> cancel(int alarmId) async {
    for (var slot = 0; slot <= 9; slot++) {
      await Alarm.stop(idFor(alarmId, slot));
    }
  }

  /// Re-arms the weekly slot after it rang (no-op for other slots).
  Future<void> rearmWeekly(UygAlarm a, int slot, L10n t) async {
    if (!a.enabled || !a.days.contains(slot)) return;
    await _set(a, idFor(a.id, slot), a.nextOccurrenceOn(slot), t);
  }

  Future<void> scheduleSnooze(UygAlarm a, int snoozesUsed, L10n t) => _set(
        a,
        idFor(a.id, snoozeSlot),
        DateTime.now().add(Duration(minutes: a.snoozeMinutes)),
        t,
        payload: RingPayload(a.id, RingKind.snooze, snoozesUsed + 1),
      );

  Future<void> scheduleWakeCheck(UygAlarm a, int delayMinutes, L10n t) => _set(
        a,
        idFor(a.id, checkSlot),
        DateTime.now().add(Duration(minutes: delayMinutes)),
        t,
        payload: RingPayload(a.id, RingKind.check),
      );

  Future<void> _set(
    UygAlarm a,
    int nativeId,
    DateTime when,
    L10n t, {
    RingPayload? payload,
  }) async {
    final kind = payload?.kind ?? RingKind.ring;
    final isCheck = kind == RingKind.check;
    final title = isCheck
        ? t('checkTitle')
        : (a.label.isEmpty ? t('wakeUp') : a.label);
    final settings = AlarmSettings(
      id: nativeId,
      dateTime: when,
      assetAudioPath: _audioPath(a.ringtone),
      loopAudio: true,
      vibrate: true,
      // The challenge screen is the only way to silence it: no stop button
      // and swiping the notification away does not stop the alarm.
      warningNotificationOnKill: false,
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false,
      androidStaleAfter: const Duration(hours: 1),
      volumeSettings: VolumeSettings.fade(
        fadeDuration: const Duration(seconds: 3),
        volume: 1.0,
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: isCheck ? t('checkBody') : t('solveToStop'),
        androidStopAlarmOnDismiss: false,
      ),
      payload: (payload ?? RingPayload(a.id, RingKind.ring)).encode(),
    );
    await Alarm.set(alarmSettings: settings);
  }

  static String? _audioPath(String ringtone) {
    if (ringtone == kSystemSound) return null;
    if (ringtone.startsWith(kBuiltInPrefix)) {
      return 'assets/sounds/${ringtone.substring(kBuiltInPrefix.length)}.wav';
    }
    return ringtone; // relative to the app documents directory
  }
}

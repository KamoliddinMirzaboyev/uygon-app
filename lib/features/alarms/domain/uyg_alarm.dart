import '../../challenges/domain/challenge_type.dart';

/// Special ringtone values. Anything else is a path relative to the app's
/// documents directory (a user-picked file copied there).
const kSystemSound = 'system';
const kBuiltInPrefix = 'asset:';

const kBuiltInSounds = ['classic_beep', 'siren', 'rooster', 'digital'];

class UygAlarm {
  const UygAlarm({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.days = const {},
    this.enabled = true,
    this.challenge = ChallengeType.math,
    this.difficulty = Difficulty.easy,
    this.shakeCount = 30,
    this.ringtone = '${kBuiltInPrefix}siren',
    this.snoozeMinutes = 5,
    this.maxSnoozes = 2,
    this.wakeCheck = false,
  });

  final int id;
  final int hour;
  final int minute;
  final String label;

  /// ISO weekdays (DateTime.monday = 1 … DateTime.sunday = 7). Empty = once.
  final Set<int> days;
  final bool enabled;
  final ChallengeType challenge;
  final Difficulty difficulty;
  final int shakeCount;
  final String ringtone;

  /// 0 disables snooze.
  final int snoozeMinutes;
  final int maxSnoozes;
  final bool wakeCheck;

  bool get isRepeating => days.isNotEmpty;
  bool get snoozeAllowed => snoozeMinutes > 0 && maxSnoozes > 0;

  UygAlarm copyWith({
    int? hour,
    int? minute,
    String? label,
    Set<int>? days,
    bool? enabled,
    ChallengeType? challenge,
    Difficulty? difficulty,
    int? shakeCount,
    String? ringtone,
    int? snoozeMinutes,
    int? maxSnoozes,
    bool? wakeCheck,
  }) =>
      UygAlarm(
        id: id,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        label: label ?? this.label,
        days: days ?? this.days,
        enabled: enabled ?? this.enabled,
        challenge: challenge ?? this.challenge,
        difficulty: difficulty ?? this.difficulty,
        shakeCount: shakeCount ?? this.shakeCount,
        ringtone: ringtone ?? this.ringtone,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
        maxSnoozes: maxSnoozes ?? this.maxSnoozes,
        wakeCheck: wakeCheck ?? this.wakeCheck,
      );

  /// The next moment this alarm should fire, or null if it is disabled.
  /// For repeating alarms use [nextOccurrenceOn] per weekday.
  DateTime? nextOccurrence([DateTime? from]) {
    if (!enabled) return null;
    final now = from ?? DateTime.now();
    if (!isRepeating) {
      var t = DateTime(now.year, now.month, now.day, hour, minute);
      if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
      // DateTime(…) handles DST by normalising; re-build to be safe.
      return DateTime(t.year, t.month, t.day, hour, minute);
    }
    DateTime? best;
    for (final d in days) {
      final t = nextOccurrenceOn(d, now);
      if (best == null || t.isBefore(best)) best = t;
    }
    return best;
  }

  /// Next time at [hour]:[minute] that falls on ISO weekday [weekday].
  DateTime nextOccurrenceOn(int weekday, [DateTime? from]) {
    final now = from ?? DateTime.now();
    var date = DateTime(now.year, now.month, now.day);
    while (date.weekday != weekday ||
        !DateTime(date.year, date.month, date.day, hour, minute).isAfter(now)) {
      date = DateTime(date.year, date.month, date.day + 1);
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'days': days.toList(),
        'enabled': enabled,
        'challenge': challenge.name,
        'difficulty': difficulty.name,
        'shakeCount': shakeCount,
        'ringtone': ringtone,
        'snoozeMinutes': snoozeMinutes,
        'maxSnoozes': maxSnoozes,
        'wakeCheck': wakeCheck,
      };

  factory UygAlarm.fromJson(Map<dynamic, dynamic> j) => UygAlarm(
        id: j['id'] as int,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        label: (j['label'] as String?) ?? '',
        days: ((j['days'] as List?) ?? const []).cast<int>().toSet(),
        enabled: (j['enabled'] as bool?) ?? true,
        challenge: ChallengeType.values.asNameMap()[j['challenge']] ??
            ChallengeType.math,
        difficulty:
            Difficulty.values.asNameMap()[j['difficulty']] ?? Difficulty.easy,
        shakeCount: (j['shakeCount'] as int?) ?? 30,
        ringtone: (j['ringtone'] as String?) ?? kSystemSound,
        snoozeMinutes: (j['snoozeMinutes'] as int?) ?? 5,
        maxSnoozes: (j['maxSnoozes'] as int?) ?? 2,
        wakeCheck: (j['wakeCheck'] as bool?) ?? false,
      );
}

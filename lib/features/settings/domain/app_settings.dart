import '../../challenges/domain/challenge_type.dart';

class AppSettings {
  const AppSettings({
    this.language = 'uz',
    this.defaultChallenge = ChallengeType.math,
    this.defaultSnoozeMinutes = 5,
    this.defaultMaxSnoozes = 2,
    this.defaultWakeCheck = false,
    this.wakeCheckDelayMinutes = 4,
  });

  final String language; // 'uz' | 'en'
  final ChallengeType defaultChallenge;
  final int defaultSnoozeMinutes; // 0 = snooze disabled
  final int defaultMaxSnoozes;
  final bool defaultWakeCheck;
  final int wakeCheckDelayMinutes; // 3..5

  AppSettings copyWith({
    String? language,
    ChallengeType? defaultChallenge,
    int? defaultSnoozeMinutes,
    int? defaultMaxSnoozes,
    bool? defaultWakeCheck,
    int? wakeCheckDelayMinutes,
  }) =>
      AppSettings(
        language: language ?? this.language,
        defaultChallenge: defaultChallenge ?? this.defaultChallenge,
        defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
        defaultMaxSnoozes: defaultMaxSnoozes ?? this.defaultMaxSnoozes,
        defaultWakeCheck: defaultWakeCheck ?? this.defaultWakeCheck,
        wakeCheckDelayMinutes:
            wakeCheckDelayMinutes ?? this.wakeCheckDelayMinutes,
      );

  Map<String, Object?> toJson() => {
        'language': language,
        'defaultChallenge': defaultChallenge.name,
        'defaultSnoozeMinutes': defaultSnoozeMinutes,
        'defaultMaxSnoozes': defaultMaxSnoozes,
        'defaultWakeCheck': defaultWakeCheck,
        'wakeCheckDelayMinutes': wakeCheckDelayMinutes,
      };

  factory AppSettings.fromJson(Map<dynamic, dynamic> j) {
    const d = AppSettings();
    return AppSettings(
      language: (j['language'] as String?) ?? d.language,
      defaultChallenge: ChallengeType.values.asNameMap()[j['defaultChallenge']] ??
          d.defaultChallenge,
      defaultSnoozeMinutes:
          (j['defaultSnoozeMinutes'] as int?) ?? d.defaultSnoozeMinutes,
      defaultMaxSnoozes: (j['defaultMaxSnoozes'] as int?) ?? d.defaultMaxSnoozes,
      defaultWakeCheck: (j['defaultWakeCheck'] as bool?) ?? d.defaultWakeCheck,
      wakeCheckDelayMinutes:
          (j['wakeCheckDelayMinutes'] as int?) ?? d.wakeCheckDelayMinutes,
    );
  }
}

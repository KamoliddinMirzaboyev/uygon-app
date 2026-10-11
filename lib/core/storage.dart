import 'package:hive_flutter/hive_flutter.dart';

/// Hive boxes. Values are stored as plain JSON-compatible maps, so no
/// generated adapters are needed.
class Storage {
  static const _alarmsBox = 'alarms';
  static const _settingsBox = 'settings';

  static late Box alarms;
  static late Box settings;

  static Future<void> init() async {
    await Hive.initFlutter();
    alarms = await Hive.openBox(_alarmsBox);
    settings = await Hive.openBox(_settingsBox);
  }
}

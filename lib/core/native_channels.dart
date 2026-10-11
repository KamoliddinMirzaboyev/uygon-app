import 'package:flutter/services.dart';

typedef SystemSound = ({String title, String uri});

/// The phone's own alarm / ringtone sounds (Android `RingtoneManager`).
class SystemRingtones {
  static const _channel = MethodChannel('uz.uygon/ringtones');

  static Future<List<SystemSound>> list() async {
    final raw = await _channel.invokeListMethod<Map>('list') ?? const [];
    return [
      for (final m in raw)
        (title: m['title'] as String, uri: m['uri'] as String),
    ];
  }

  /// Copies [uri] into the app's data folder; returns the path relative to
  /// the documents directory, ready to store as an alarm ringtone.
  static Future<String> copy(String uri, String name) async => (await _channel
      .invokeMethod<String>('copy', {'uri': uri, 'name': name}))!;
}

/// Opt-in "uninstall protection": registers the app as a device admin, so
/// Android makes the user deactivate it in Settings before uninstalling.
class UninstallProtection {
  static const _channel = MethodChannel('uz.uygon/protection');

  static Future<bool> isActive() async =>
      await _channel.invokeMethod<bool>('isActive') ?? false;

  static Future<void> enable() => _channel.invokeMethod('enable');

  static Future<bool> disable() async =>
      await _channel.invokeMethod<bool>('disable') ?? false;
}

/// Whether this build ships the optional uninstall-protection feature. The
/// Google Play build leaves it out (store policy); the direct APK has it.
const kUninstallProtectionAvailable = bool.fromEnvironment(
  'UNINSTALL_PROTECTION',
  defaultValue: false,
);

/// Short "ratchet" tick + haptic used by the time wheel.
class UiFeedback {
  static const _channel = MethodChannel('uz.uygon/feedback');
  static var _flip = false;

  static Future<void> tick() async {
    HapticFeedback.selectionClick();
    _flip = !_flip;
    try {
      // Alternate the pitch a little so fast scrolling sounds like a ratchet.
      await _channel.invokeMethod('tick', {'rate': _flip ? 1.0 : 1.12});
    } catch (_) {
      /* sound is optional */
    }
  }
}

/// Battery-optimisation state and settings shortcut.
class SystemSettings {
  static const _channel = MethodChannel('uz.uygon/system');

  static Future<bool> isUnrestricted() async =>
      await _channel.invokeMethod<bool>('batteryUnrestricted') ?? false;

  static Future<bool> canScheduleExact() async =>
      await _channel.invokeMethod<bool>('canScheduleExact') ?? true;

  static Future<void> openExactAlarmSettings() =>
      _channel.invokeMethod('openExactAlarmSettings');

  static Future<void> openSettings() =>
      _channel.invokeMethod('openSystemSettings');
}

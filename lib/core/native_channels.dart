import 'package:flutter/services.dart';

typedef SystemSound = ({String title, String uri});

/// The phone's own alarm / ringtone sounds (Android `RingtoneManager`).
class SystemRingtones {
  static const _channel = MethodChannel('uz.waky.app/ringtones');

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

/// In-app audio preview for alarm ringtones.
class SoundPreview {
  static const _channel = MethodChannel('uz.waky.app/ringtones');

  static Future<void> playAsset(String soundName) async {
    try {
      await _channel.invokeMethod('play', {'type': 'asset', 'value': soundName});
    } catch (_) {}
  }

  static Future<void> playSystem() async {
    try {
      await _channel.invokeMethod('play', {'type': 'system'});
    } catch (_) {}
  }

  static Future<void> playUri(String uri) async {
    try {
      await _channel.invokeMethod('play', {'type': 'uri', 'value': uri});
    } catch (_) {}
  }

  static Future<void> playFile(String path) async {
    try {
      await _channel.invokeMethod('play', {'type': 'file', 'value': path});
    } catch (_) {}
  }

  static Future<void> playRingtone(String ringtone) async {
    if (ringtone == 'system') {
      return playSystem();
    } else if (ringtone.startsWith('asset:')) {
      return playAsset(ringtone.substring('asset:'.length));
    } else {
      return playFile(ringtone);
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  static Future<bool> isPlaying() async {
    try {
      return (await _channel.invokeMethod<bool>('isPlaying')) ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Opt-in "uninstall protection": registers the app as a device admin, so
/// Android makes the user deactivate it in Settings before uninstalling.
class UninstallProtection {
  static const _channel = MethodChannel('uz.waky.app/protection');

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
  static const _channel = MethodChannel('uz.waky.app/feedback');
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
  static const _channel = MethodChannel('uz.waky.app/system');

  static Future<bool> isUnrestricted() async =>
      await _channel.invokeMethod<bool>('batteryUnrestricted') ?? false;

  static Future<bool> canScheduleExact() async =>
      await _channel.invokeMethod<bool>('canScheduleExact') ?? true;

  static Future<void> openExactAlarmSettings() =>
      _channel.invokeMethod('openExactAlarmSettings');

  static Future<void> openSettings() =>
      _channel.invokeMethod('openSystemSettings');
}

import 'package:permission_handler/permission_handler.dart';

import 'native_channels.dart';

class PermissionState {
  const PermissionState({
    required this.notifications,
    required this.exactAlarm,
    required this.battery,
  });

  final bool notifications;
  final bool exactAlarm;
  final bool battery;

  bool get allGranted => notifications && exactAlarm && battery;

  /// Without these the alarm cannot ring reliably; battery is only advice.
  bool get criticalGranted => notifications && exactAlarm;
}

class Permissions {
  static Future<PermissionState> check() async => PermissionState(
    notifications: await Permission.notification.isGranted,
    // Below Android 12 this permission does not exist and reports granted.
    exactAlarm: await SystemSettings.canScheduleExact(),
    battery: await SystemSettings.isUnrestricted(),
  );

  static Future<void> requestNotifications() async {
    final s = await Permission.notification.request();
    if (s.isPermanentlyDenied) await openAppSettings();
  }

  /// Opens the system "Alarms & reminders" screen on Android 12+.
  static Future<void> requestExactAlarm() =>
      SystemSettings.openExactAlarmSettings();

  /// Opens the system battery-optimisation list (the app has to be set to
  /// "Unrestricted" / "Not optimised" there).
  static Future<void> requestBattery() => SystemSettings.openSettings();

  /// Asks for everything that is cheap to ask for, in order. Called from
  /// the home screen on first launch.
  static Future<void> requestAll() async {
    await Permission.notification.request();
    if (!await SystemSettings.canScheduleExact()) {
      await SystemSettings.openExactAlarmSettings();
    }
  }
}

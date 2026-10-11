import 'package:permission_handler/permission_handler.dart';

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
}

class Permissions {
  static Future<PermissionState> check() async => PermissionState(
    notifications: await Permission.notification.isGranted,
    // Below Android 12 this permission does not exist and reports granted.
    exactAlarm: await Permission.scheduleExactAlarm.isGranted,
    battery: await Permission.ignoreBatteryOptimizations.isGranted,
  );

  static Future<void> requestNotifications() async {
    final s = await Permission.notification.request();
    if (s.isPermanentlyDenied) await openAppSettings();
  }

  /// Opens the system "Alarms & reminders" screen on Android 12+.
  static Future<void> requestExactAlarm() async {
    await Permission.scheduleExactAlarm.request();
  }

  static Future<void> requestBattery() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  /// Asks for everything that is cheap to ask for, in order. Called from
  /// the home screen on first launch.
  static Future<void> requestAll() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }
}

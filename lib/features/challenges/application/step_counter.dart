import 'dart:async';
import 'dart:math';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Metres per step used to convert the walking distance to a step goal.
const kMetersPerStep = 0.7;

int stepsForMeters(int meters) => (meters / kMetersPerStep).ceil();

/// Counts steps since [start]. Uses the hardware step counter; if the phone
/// has none (or permission is refused) it falls back to accelerometer peaks.
class StepCounter {
  StepCounter({required this.onSteps});

  final void Function(int steps) onSteps;

  StreamSubscription<StepCount>? _pedo;
  StreamSubscription<UserAccelerometerEvent>? _accel;
  int? _base;
  int _fallbackSteps = 0;
  DateTime _lastStep = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> start() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return _startFallback();
    _pedo = Pedometer.stepCountStream.listen((e) {
      _base ??= e.steps;
      onSteps(e.steps - _base!);
    }, onError: (_) => _startFallback());
  }

  void _startFallback() {
    _pedo?.cancel();
    _pedo = null;
    _accel ??=
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((e) {
          final m = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          final now = DateTime.now();
          if (m > 2.2 && now.difference(_lastStep).inMilliseconds > 350) {
            _lastStep = now;
            onSteps(++_fallbackSteps);
          }
        });
  }

  void stop() {
    _pedo?.cancel();
    _accel?.cancel();
    _pedo = _accel = null;
  }
}

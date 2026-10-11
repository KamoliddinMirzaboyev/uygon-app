import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'motion.dart';

/// Metres per step used to convert the walking distance to a step goal.
const kMetersPerStep = 0.7;

int stepsForMeters(int meters) => (meters / kMetersPerStep).ceil();

/// Counts steps since [start]. Uses the hardware step counter; if the phone
/// has none, the permission is refused, or it stays silent for a few
/// seconds, it falls back to accelerometer peak detection.
class StepCounter {
  StepCounter({required this.onSteps});

  final void Function(int steps) onSteps;

  StreamSubscription<StepCount>? _pedo;
  PeakDetector? _accel;
  Timer? _silenceTimer;
  int? _base;
  int _fallbackSteps = 0;
  bool _hardwareWorking = false;

  Future<void> start() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return _startFallback();
    _pedo = Pedometer.stepCountStream.listen((e) {
      _hardwareWorking = true;
      _silenceTimer?.cancel();
      _accel?.stop();
      _accel = null;
      _base ??= e.steps;
      onSteps(e.steps - _base!);
    }, onError: (_) => _startFallback());
    // Some phones expose no step sensor and never report an error.
    _silenceTimer = Timer(const Duration(seconds: 6), () {
      if (!_hardwareWorking) _startFallback();
    });
  }

  void _startFallback() {
    if (_accel != null) return;
    _accel = PeakDetector(
      threshold: 2.0,
      minGap: const Duration(milliseconds: 350),
      onPeak: () {
        if (!_hardwareWorking) onSteps(++_fallbackSteps);
      },
    )..start();
  }

  void stop() {
    _silenceTimer?.cancel();
    _pedo?.cancel();
    _accel?.stop();
    _pedo = null;
    _accel = null;
  }
}

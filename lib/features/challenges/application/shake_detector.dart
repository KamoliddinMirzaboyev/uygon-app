import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Counts shakes using the gravity-free accelerometer. A shake is a spike in
/// acceleration magnitude; [minGap] stops one wave of movement counting twice.
class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.threshold = 11.0,
    this.minGap = const Duration(milliseconds: 250),
  });

  final void Function() onShake;
  final double threshold; // m/s², gravity removed
  final Duration minGap;

  StreamSubscription<UserAccelerometerEvent>? _sub;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  void start() {
    _sub ??=
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((e) {
          final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
          if (magnitude < threshold) return;
          final now = DateTime.now();
          if (now.difference(_last) < minGap) return;
          _last = now;
          onShake();
        });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}

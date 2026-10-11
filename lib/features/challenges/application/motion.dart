import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

/// Gravity-free acceleration magnitude (m/s²) computed from the raw
/// accelerometer with a low-pass gravity estimate. Unlike Android's
/// "linear acceleration" sensor this exists on every phone, including those
/// without a gyroscope.
Stream<double> motionMagnitude() async* {
  var gx = 0.0, gy = 0.0, gz = 0.0;
  var primed = false;
  const alpha = 0.9; // gravity low-pass factor
  await for (final e in accelerometerEventStream(
    samplingPeriod: SensorInterval.gameInterval,
  )) {
    if (!primed) {
      gx = e.x;
      gy = e.y;
      gz = e.z;
      primed = true;
      continue;
    }
    gx = alpha * gx + (1 - alpha) * e.x;
    gy = alpha * gy + (1 - alpha) * e.y;
    gz = alpha * gz + (1 - alpha) * e.z;
    final x = e.x - gx, y = e.y - gy, z = e.z - gz;
    yield sqrt(x * x + y * y + z * z);
  }
}

/// Calls [onPeak] for each spike above [threshold], at most once per [minGap].
class PeakDetector {
  PeakDetector({
    required this.threshold,
    required this.minGap,
    required this.onPeak,
  });

  final double threshold;
  final Duration minGap;
  final void Function() onPeak;

  StreamSubscription<double>? _sub;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  void start() {
    _sub ??= motionMagnitude().listen((m) {
      if (m < threshold) return;
      final now = DateTime.now();
      if (now.difference(_last) < minGap) return;
      _last = now;
      onPeak();
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}

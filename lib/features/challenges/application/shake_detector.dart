import 'motion.dart';

/// Counts shakes: a spike in gravity-free acceleration. [minGap] stops one
/// wave of movement from counting twice.
class ShakeDetector {
  ShakeDetector({
    required void Function() onShake,
    double threshold = 10.0,
    Duration minGap = const Duration(milliseconds: 250),
  }) : _peaks = PeakDetector(
          threshold: threshold,
          minGap: minGap,
          onPeak: onShake,
        );

  final PeakDetector _peaks;

  void start() => _peaks.start();

  void stop() => _peaks.stop();
}

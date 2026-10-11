import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../application/shake_detector.dart';

class ShakeChallenge extends ConsumerStatefulWidget {
  const ShakeChallenge({
    super.key,
    required this.count,
    required this.onSolved,
  });

  final int count;
  final VoidCallback onSolved;

  @override
  ConsumerState<ShakeChallenge> createState() => _ShakeChallengeState();
}

class _ShakeChallengeState extends ConsumerState<ShakeChallenge> {
  late final ShakeDetector _detector;
  int _shakes = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _detector = ShakeDetector(onShake: _onShake)..start();
  }

  void _onShake() {
    if (_done) return;
    HapticFeedback.mediumImpact();
    setState(() => _shakes++);
    if (_shakes >= widget.count) {
      _done = true;
      _detector.stop();
      widget.onSolved();
    }
  }

  @override
  void dispose() {
    _detector.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final scheme = Theme.of(context).colorScheme;
    final progress = (_shakes / widget.count).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t('shakeNow'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: const Duration(milliseconds: 200),
                  builder: (_, v, _) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vibration, size: 48, color: scheme.primary),
                  Text(
                    '${widget.count - _shakes}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t('shakesLeft', {'n': widget.count - _shakes}),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

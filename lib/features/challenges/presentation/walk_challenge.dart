import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../application/step_counter.dart';

class WalkChallenge extends ConsumerStatefulWidget {
  const WalkChallenge({
    super.key,
    required this.meters,
    required this.onSolved,
  });

  final int meters;
  final VoidCallback onSolved;

  @override
  ConsumerState<WalkChallenge> createState() => _WalkChallengeState();
}

class _WalkChallengeState extends ConsumerState<WalkChallenge> {
  late final int _goal = stepsForMeters(widget.meters);
  late final StepCounter _counter = StepCounter(onSteps: _onSteps);
  int _steps = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _counter.start();
  }

  void _onSteps(int steps) {
    if (_done || !mounted) return;
    setState(() => _steps = steps.clamp(0, _goal));
    if (steps >= _goal) {
      _done = true;
      _counter.stop();
      widget.onSolved();
    }
  }

  @override
  void dispose() {
    _counter.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final walked = (_steps * kMetersPerStep).round().clamp(0, widget.meters);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t('walkNow', {'m': widget.meters}),
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _steps / _goal),
                  duration: const Duration(milliseconds: 250),
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
                  Icon(
                    Icons.directions_walk,
                    size: 44,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    '$walked / ${widget.meters} m',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../application/math_generator.dart';
import '../domain/challenge_type.dart';

/// Solve [required] arithmetic problems in a row; a wrong answer resets.
class MathChallenge extends ConsumerStatefulWidget {
  const MathChallenge({
    super.key,
    required this.difficulty,
    required this.onSolved,
    this.required = 3,
  });

  final Difficulty difficulty;
  final int required;
  final VoidCallback onSolved;

  @override
  ConsumerState<MathChallenge> createState() => _MathChallengeState();
}

class _MathChallengeState extends ConsumerState<MathChallenge>
    with SingleTickerProviderStateMixin {
  final _gen = MathGenerator();
  final _controller = TextEditingController();
  final _focus = FocusNode();
  late MathQuestion _q = _gen.next(widget.difficulty);
  int _streak = 0;
  bool _wrong = false;

  late final AnimationController _shakeAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _shakeAnim.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) return;
    if (value == _q.answer) {
      _streak++;
      if (_streak >= widget.required) {
        widget.onSolved();
        return;
      }
      setState(() => _wrong = false);
    } else {
      _streak = 0;
      _shakeAnim.forward(from: 0);
      HapticFeedback.heavyImpact();
      setState(() => _wrong = true);
    }
    setState(() {
      _q = _gen.next(widget.difficulty);
      _controller.clear();
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t('mathProgress', {'n': _streak, 'total': widget.required}),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _streak / widget.required,
          borderRadius: BorderRadius.circular(8),
          minHeight: 8,
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(
              _shakeAnim.isAnimating
                  ? sin(_shakeAnim.value * pi * 6) * 14 * (1 - _shakeAnim.value)
                  : 0,
              0,
            ),
            child: child,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              '${_q.text} = ?',
              key: ValueKey(_q.text),
              style: Theme.of(context).textTheme.displayMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: _wrong ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Text(t('wrong'), style: TextStyle(color: scheme.error)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(signed: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
          decoration: InputDecoration(hintText: t('answer')),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
            child: Text(t('submit')),
          ),
        ),
      ],
    );
  }
}

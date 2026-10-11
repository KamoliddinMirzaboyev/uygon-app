import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../application/typing_sentences.dart';

class TypingChallenge extends ConsumerStatefulWidget {
  const TypingChallenge({super.key, required this.onSolved});

  final VoidCallback onSolved;

  @override
  ConsumerState<TypingChallenge> createState() => _TypingChallengeState();
}

class _TypingChallengeState extends ConsumerState<TypingChallenge> {
  late final String _target = randomSentence(ref.read(l10nProvider).code);
  final _controller = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {});
    if (!_done && sentenceMatches(text, _target)) {
      _done = true;
      widget.onSolved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final scheme = Theme.of(context).colorScheme;
    final typed = normalizeTyped(_controller.text);
    final target = normalizeTyped(_target);
    // Length of the correct prefix, to colour the sentence as the user types.
    var ok = 0;
    while (ok < typed.length && ok < target.length && typed[ok] == target[ok]) {
      ok++;
    }
    final hasError = typed.length > ok;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t('typeThis'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _target.substring(0, ok.clamp(0, _target.length)),
                    style: TextStyle(color: scheme.primary),
                  ),
                  TextSpan(
                    text: _target.substring(ok.clamp(0, _target.length)),
                    style: TextStyle(
                      color: hasError ? scheme.error : scheme.onSurface,
                    ),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          // Pasting the sentence would defeat the point.
          enableInteractiveSelection: false,
          contextMenuBuilder: null,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: t('typeHere'),
            errorText: hasError ? ' ' : null,
          ),
          onChanged: _onChanged,
        ),
      ],
    );
  }
}

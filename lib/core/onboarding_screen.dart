import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ios_widgets.dart';
import 'l10n.dart';
import 'permissions.dart';
import 'theme.dart';

/// Three short pages shown once: what the app does, the tasks, permissions.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _icons = [Icons.alarm_on, Icons.task_alt, Icons.verified_user];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_index < 2) {
      await _page.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await Permissions.requestAll();
    await Permissions.requestBattery();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final last = _index == 2;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: last ? null : widget.onDone,
                  child: Text(t('skip'), style: kOrangeText),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: 3,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _Page(
                  active: i == _index,
                  icon: _icons[i],
                  title: t('onb${i + 1}Title'),
                  body: t('onb${i + 1}Body'),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.all(4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? kAccent : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    backgroundColor: kAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      last ? t('grantAll') : t('next'),
                      key: ValueKey(last),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.active,
    required this.icon,
    required this.title,
    required this.body,
  });

  final bool active;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: active ? 1 : 0.7,
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAccent.withValues(alpha: 0.15),
              ),
              child: Icon(icon, size: 72, color: kAccent),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            height: 1.4,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    ),
  );
}

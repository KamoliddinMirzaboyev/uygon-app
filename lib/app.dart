import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n.dart';
import 'core/onboarding_screen.dart';
import 'core/splash_screen.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'features/alarms/presentation/home_screen.dart';
import 'features/challenges/application/ring_listener.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class WakyApp extends ConsumerStatefulWidget {
  const WakyApp({super.key});

  @override
  ConsumerState<WakyApp> createState() => _WakyAppState();
}

class _WakyAppState extends ConsumerState<WakyApp> {
  final RingListener _ring = RingListener(navigatorKey);

  @override
  void initState() {
    super.initState();
    // Must start eagerly: this is what shows the challenge when an alarm rings.
    _ring.start();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: t('appName'),
      debugShowCheckedModeBanner: false,
      // Dark by default: it is used first thing in the morning.
      themeMode: ThemeMode.dark,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: Locale(t.code),
      supportedLocales: L10n.supported,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Gate(),
    );
  }
}

/// Splash → (first run only) onboarding → home, with cross-fades. Done inside
/// one route so a ringing alarm can be pushed on top at any moment.
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

enum _Stage { splash, onboarding, home }

class _GateState extends State<_Gate> {
  static const _flag = 'onboarded';
  _Stage _stage = _Stage.splash;

  void _afterSplash() => setState(
    () => _stage = Storage.settings.get(_flag) == true
        ? _Stage.home
        : _Stage.onboarding,
  );

  void _afterOnboarding() {
    Storage.settings.put(_flag, true);
    setState(() => _stage = _Stage.home);
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 600),
    switchInCurve: Curves.easeOut,
    transitionBuilder: (child, anim) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.97, end: 1.0).animate(anim),
        child: child,
      ),
    ),
    child: switch (_stage) {
      _Stage.splash => SplashScreen(
        key: const ValueKey('s'),
        onFinished: _afterSplash,
      ),
      _Stage.onboarding => OnboardingScreen(
        key: const ValueKey('o'),
        onDone: _afterOnboarding,
      ),
      _Stage.home => const HomeScreen(key: ValueKey('h')),
    },
  );
}

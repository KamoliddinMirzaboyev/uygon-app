import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n.dart';
import 'core/theme.dart';
import 'features/alarms/presentation/home_screen.dart';
import 'features/challenges/application/ring_listener.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class UygonApp extends ConsumerStatefulWidget {
  const UygonApp({super.key});

  @override
  ConsumerState<UygonApp> createState() => _UygonAppState();
}

class _UygonAppState extends ConsumerState<UygonApp> {
  late final RingListener _ring = RingListener(navigatorKey)..start();

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
      home: const HomeScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n.dart';
import 'theme.dart';

/// Animated splash that continues the native splash seamlessly: the same
/// brand image stays in place, a warm glow pulses behind it and the name and
/// tagline fade in underneath.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2200),
        )
        ..forward().whenComplete(() {
          if (mounted) widget.onFinished();
        });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _interval(
    double v,
    double from,
    double to, [
    Curve curve = Curves.easeOut,
  ]) => curve.transform(((v - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final size = MediaQuery.sizeOf(context);
    final logo = size.shortestSide * 0.62;
    return Scaffold(
      // Same colour as the native splash so the hand-over is invisible.
      backgroundColor: const Color(0xFF16171B),
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final glow = _interval(v, 0.0, 0.6);
          final scale = 1 + 0.07 * _interval(v, 0.0, 1.0, Curves.easeInOut);
          final name = _interval(v, 0.45, 0.8);
          final tag = _interval(v, 0.6, 0.95);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Warm glow behind the logo.
              Container(
                width: logo * 1.9,
                height: logo * 1.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kAccent.withValues(alpha: 0.30 * glow),
                      kAccent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Image.asset(
                  'assets/brand/splash.png',
                  width: logo,
                  height: logo,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.52),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: name,
                      child: Transform.translate(
                        offset: Offset(0, (1 - name) * 14),
                        child: Text(
                          t('appName'),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: tag,
                      child: Text(
                        t('tagline'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

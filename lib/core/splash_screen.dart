import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n.dart';
import 'theme.dart';

/// Animated splash: the sun rises over the horizon, rays fan out and the
/// name fades in. Continues the native (static) splash seamlessly.
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

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final text = Curves.easeOut.transform(
            ((v - 0.55) / 0.35).clamp(0, 1),
          );
          final tag = Curves.easeOut.transform(((v - 0.7) / 0.3).clamp(0, 1));
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _SunPainter(v))),
              Align(
                alignment: const Alignment(0, 0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: text,
                      child: Transform.translate(
                        offset: Offset(0, (1 - text) * 16),
                        child: Text(
                          t('appName'),
                          style: const TextStyle(
                            fontSize: 44,
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

class _SunPainter extends CustomPainter {
  _SunPainter(this.v);

  final double v; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final horizon = size.height * 0.40;
    final r = min(size.width, size.height) * 0.16;

    final rise = Curves.easeOutCubic.transform((v / 0.6).clamp(0, 1));
    final glow = Curves.easeIn.transform((v / 0.8).clamp(0, 1));
    final cy = horizon + r * (1 - rise) * 1.25; // starts below the horizon

    // Glow behind the sun.
    final glowRect = Rect.fromCircle(
      center: Offset(cx, horizon),
      radius: r * 3.4,
    );
    canvas.drawCircle(
      Offset(cx, horizon),
      r * 3.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            kAccent.withValues(alpha: 0.55 * glow),
            kAccent.withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );

    // Everything above the horizon only.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, horizon));

    // Rays fan out one after another.
    const rays = 9;
    for (var i = 0; i < rays; i++) {
      final start = 0.45 + i * 0.03;
      final p = Curves.easeOutBack.transform(((v - start) / 0.3).clamp(0, 1));
      if (p <= 0) continue;
      final a = pi * (1 + (i + 0.5) / rays);
      final from = Offset(cx + cos(a) * r * 1.3, horizon + sin(a) * r * 1.3);
      final to = Offset(
        cx + cos(a) * r * (1.3 + 0.55 * p),
        horizon + sin(a) * r * (1.3 + 0.55 * p),
      );
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = const Color(0xFFFFB840).withValues(alpha: p.clamp(0, 1))
          ..strokeWidth = r * 0.11
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC043), kAccent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    canvas.restore();

    // Horizon lines.
    final line = Curves.easeOut.transform((v / 0.5).clamp(0, 1));
    final w = r * 4.2 * line;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, horizon + 6), width: w, height: 5),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, horizon + 22),
          width: w * 0.6,
          height: 5,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.v != v;
}

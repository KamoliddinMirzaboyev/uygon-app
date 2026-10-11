import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n.dart';
import '../../alarms/application/alarm_scheduler.dart';
import '../../alarms/application/alarms_controller.dart';
import '../../alarms/domain/uyg_alarm.dart';
import '../../settings/application/settings_controller.dart';
import '../../../core/ios_widgets.dart';
import '../../../core/theme.dart';
import '../domain/challenge_type.dart';
import 'math_challenge.dart';
import 'scan_widgets.dart';
import 'walk_challenge.dart';
import 'shake_challenge.dart';
import 'typing_challenge.dart';

enum _Phase { challenge, success }

/// Full-screen ringing UI. The native service keeps playing audio until
/// [Alarm.stop] is called, which only happens after the challenge is solved
/// (or the user spends a snooze).
class RingScreen extends ConsumerStatefulWidget {
  const RingScreen({
    super.key,
    required this.nativeId,
    required this.payload,
    this.preview = false,
    this.previewAlarm,
  });

  /// Number of ring screens currently on screen (used by [RingListener] so
  /// a re-ring after a mute does not stack a second screen).
  static final open = ValueNotifier<int>(0);

  /// The alarm being previewed from the editor (it may not be saved yet).
  final UygAlarm? previewAlarm;

  final int nativeId;
  final RingPayload payload;

  /// Preview from the edit screen: no native alarm is involved.
  final bool preview;

  @override
  ConsumerState<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends ConsumerState<RingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  _Phase _phase = _Phase.challenge;
  late int _nativeId = widget.nativeId;
  int _muteSeconds = 0; // >0 while the sound is silenced
  Timer? _muteTimer;
  late final Timer _clock;
  DateTime _now = DateTime.now();
  bool _scheduledCheck = false;

  UygAlarm? get _alarm =>
      widget.previewAlarm ??
      ref.read(alarmRepositoryProvider).byId(widget.payload.alarmId);

  @override
  void initState() {
    super.initState();
    RingScreen.open.value++;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // Keep the screen on and immersive while ringing.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _bg.dispose();
    _clock.cancel();
    _muteTimer?.cancel();
    RingScreen.open.value--;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _stopNative() async {
    if (widget.preview) return;
    await Alarm.stop(_nativeId);
  }

  /// Runs once the challenge (or the awake check) is complete.
  Future<void> _onSolved() async {
    if (_phase == _Phase.success) return;
    final alarm = _alarm;
    final t = ref.read(l10nProvider);
    await _stopNative();
    if (!widget.preview && alarm != null) {
      final scheduler = ref.read(alarmSchedulerProvider);
      final slot = AlarmScheduler.slotOf(_nativeId);
      await scheduler.rearmWeekly(alarm, slot, t);
      if (!alarm.isRepeating && widget.payload.kind != RingKind.check) {
        await ref.read(alarmsProvider.notifier).markOneShotDone(alarm.id);
      }
      if (alarm.wakeCheck && widget.payload.kind != RingKind.check) {
        final delay = ref.read(settingsProvider).wakeCheckDelayMinutes;
        await scheduler.scheduleWakeCheck(alarm, delay, t);
        _scheduledCheck = true;
      }
    }
    HapticFeedback.heavyImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    if (mounted) setState(() => _phase = _Phase.success);
  }

  /// Silences the alarm for [minutes] so the task can be done in peace. The
  /// native alarm is stopped and re-armed to ring again after that time, so
  /// it comes back even if this screen or the app is killed meanwhile.
  Future<void> _mute(UygAlarm alarm, int minutes) async {
    if (widget.preview) {
      _startMuteCountdown(minutes * 60);
      return;
    }
    final t = ref.read(l10nProvider);
    final scheduler = ref.read(alarmSchedulerProvider);
    await Alarm.stop(_nativeId);
    // The weekly slot we were using is free again: arm next week's now.
    await scheduler.rearmWeekly(alarm, AlarmScheduler.slotOf(_nativeId), t);
    _nativeId = await scheduler.scheduleReRing(
      alarm,
      widget.payload,
      Duration(minutes: minutes),
      t,
    );
    _startMuteCountdown(minutes * 60);
  }

  void _startMuteCountdown(int seconds) {
    _muteTimer?.cancel();
    setState(() => _muteSeconds = seconds);
    _muteTimer = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (!mounted) return tm.cancel();
      setState(() => _muteSeconds--);
      if (_muteSeconds <= 0) tm.cancel();
    });
  }

  Future<void> _unmuteNow(UygAlarm alarm) async {
    _muteTimer?.cancel();
    setState(() => _muteSeconds = 0);
    if (widget.preview) return;
    // Re-ring immediately (min. native delay is applied by the scheduler).
    final t = ref.read(l10nProvider);
    await Alarm.stop(_nativeId);
    _nativeId = await ref
        .read(alarmSchedulerProvider)
        .scheduleReRing(alarm, widget.payload, const Duration(seconds: 2), t);
  }

  Future<void> _snooze(UygAlarm alarm) async {
    final t = ref.read(l10nProvider);
    final scheduler = ref.read(alarmSchedulerProvider);
    await _stopNative();
    if (!widget.preview) {
      await scheduler.rearmWeekly(alarm, AlarmScheduler.slotOf(_nativeId), t);
      await scheduler.scheduleSnooze(alarm, widget.payload.snoozesUsed, t);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _finish() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final alarm = _alarm;
    final scheme = Theme.of(context).colorScheme;
    final isCheck = widget.payload.kind == RingKind.check;

    // Back button / predictive back never dismisses a ringing alarm.
    return PopScope(
      canPop: _phase == _Phase.success || widget.preview,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _bg,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.9),
                radius: 1.3,
                colors: [
                  kAccent.withValues(
                    alpha: _phase == _Phase.success
                        ? 0.35
                        : 0.12 + 0.12 * _bg.value,
                  ),
                  Colors.black,
                ],
              ),
            ),
            child: child,
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _phase == _Phase.success
                  ? _Success(
                      key: const ValueKey('success'),
                      t: t,
                      checkMinutes: _scheduledCheck
                          ? ref.read(settingsProvider).wakeCheckDelayMinutes
                          : null,
                      onDone: _finish,
                    )
                  : SingleChildScrollView(
                      key: const ValueKey('challenge'),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.sizeOf(context).height -
                              MediaQuery.paddingOf(context).vertical -
                              48,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.preview)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final nav = Navigator.of(context);
                                    await _stopNative();
                                    if (mounted) nav.pop();
                                  },
                                  icon: const Icon(Icons.close, color: kAccent),
                                  label: Text(t('close'), style: kOrangeText),
                                ),
                              ),
                            _PulsingBell(color: scheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('HH:mm').format(
                                widget.preview && alarm != null
                                    ? DateTime(
                                        2000,
                                        1,
                                        1,
                                        alarm.hour,
                                        alarm.minute,
                                      )
                                    : _now,
                              ),
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontSize: 96,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                            Text(
                              isCheck
                                  ? t('checkTitle')
                                  : (alarm?.label.isNotEmpty == true
                                        ? alarm!.label
                                        : t('wakeUp')),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 32),
                            if (isCheck)
                              _AwakeButton(t: t, onConfirmed: _onSolved)
                            else
                              _buildChallenge(alarm),
                            if (!isCheck && alarm != null) ...[
                              const SizedBox(height: 24),
                              _muteControls(alarm, t),
                              ..._snoozeButton(alarm, t),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallenge(UygAlarm? alarm) {
    final type = alarm?.effectiveChallenge ?? ChallengeType.math;
    switch (type) {
      case ChallengeType.math:
        return MathChallenge(
          difficulty: alarm?.difficulty ?? Difficulty.easy,
          onSolved: _onSolved,
        );
      case ChallengeType.shake:
        return ShakeChallenge(
          count: alarm?.shakeCount ?? 30,
          onSolved: _onSolved,
        );
      case ChallengeType.typing:
        return TypingChallenge(onSolved: _onSolved);
      case ChallengeType.qr:
      case ChallengeType.barcode:
        return ScanChallenge(
          type: type,
          expected: alarm!.scanValue!,
          onSolved: _onSolved,
        );
      case ChallengeType.walk:
        return WalkChallenge(
          meters: alarm?.walkMeters ?? 50,
          onSolved: _onSolved,
        );
    }
  }

  Widget _muteControls(UygAlarm alarm, L10n t) {
    if (_muteSeconds > 0) {
      return Column(
        children: [
          Text(
            t('mutedInfo', {'s': _muteSeconds}),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: () => _unmuteNow(alarm),
            child: Text(t('unmuteNow')),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final m in const [1, 2])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: OutlinedButton.icon(
              onPressed: () => _mute(alarm, m),
              icon: const Icon(Icons.volume_off, size: 18),
              label: Text(t('muteFor', {'n': m})),
            ),
          ),
      ],
    );
  }

  List<Widget> _snoozeButton(UygAlarm alarm, L10n t) {
    final left = alarm.maxSnoozes - widget.payload.snoozesUsed;
    if (!alarm.snoozeAllowed || left <= 0) return const [];
    return [
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: () => _snooze(alarm),
        icon: const Icon(Icons.snooze),
        label: Text(t('snoozeBtn', {'n': left})),
      ),
    ];
  }
}

class _PulsingBell extends StatefulWidget {
  const _PulsingBell({required this.color});

  final Color color;

  @override
  State<_PulsingBell> createState() => _PulsingBellState();
}

class _PulsingBellState extends State<_PulsingBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween(
      begin: 0.9,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: Icon(Icons.alarm, size: 56, color: widget.color),
  );
}

class _AwakeButton extends StatelessWidget {
  const _AwakeButton({required this.t, required this.onConfirmed});

  final L10n t;
  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onConfirmed,
      style: FilledButton.styleFrom(minimumSize: const Size(0, 72)),
      icon: const Icon(Icons.wb_sunny),
      label: Text(t('imAwake'), style: const TextStyle(fontSize: 20)),
    ),
  );
}

class _Success extends StatelessWidget {
  const _Success({
    super.key,
    required this.t,
    required this.checkMinutes,
    required this.onDone,
  });

  final L10n t;
  final int? checkMinutes;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Icon(Icons.check_circle, size: 120, color: scheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              t('successTitle'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              t('successBody'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (checkMinutes != null) ...[
              const SizedBox(height: 16),
              Text(
                t('successCheck', {'n': checkMinutes!}),
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.tertiary),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(minimumSize: const Size(200, 56)),
              child: Text(t('done')),
            ),
          ],
        ),
      ),
    );
  }
}

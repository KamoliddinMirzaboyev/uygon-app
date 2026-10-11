import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ios_widgets.dart';
import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../core/native_channels.dart';
import '../../../core/permissions.dart';
import '../../challenges/domain/challenge_type.dart' as ch;
import '../../challenges/presentation/math_challenge.dart';
import '../../challenges/domain/challenge_type.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  PermissionState? _perms;
  bool _protected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final p = await Permissions.check();
    final prot = await UninstallProtection.isActive();
    if (mounted) {
      setState(() {
        _perms = p;
        _protected = prot;
      });
    }
  }

  Future<void> _toggleProtection(bool on, L10n t) async {
    if (on) {
      await UninstallProtection.enable(); // system dialog; state refreshed on resume
      return;
    }
    // Turning it off needs a solved challenge, like dismissing an alarm.
    final solved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t('protectionOffTitle')),
        content: MathChallenge(
          difficulty: ch.Difficulty.medium,
          onSolved: () => Navigator.pop(c, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t('cancel')),
          ),
        ],
      ),
    );
    if (solved == true) {
      await UninstallProtection.disable();
      await _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<T?> _choose<T>(String title, List<(T, String)> options, T current) =>
      showModalBottomSheet<T>(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (value, label) in options)
                ListTile(
                  title: Text(label),
                  trailing: value == current
                      ? const Icon(Icons.check, color: kAccent)
                      : null,
                  onTap: () => Navigator.pop(c, value),
                ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final s = ref.watch(settingsProvider);
    final ctl = ref.read(settingsProvider.notifier);
    final perms = _perms;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('settings'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: kAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          GroupCard(
            children: [
              GroupRow(
                title: t('language'),
                value: s.language == 'uz' ? t('uzbek') : t('english'),
                onTap: () async {
                  final v = await _choose<String>(t('language'), [
                    ('uz', t('uzbek')),
                    ('en', t('english')),
                  ], s.language);
                  if (v != null) ctl.update((x) => x.copyWith(language: v));
                },
              ),
            ],
          ),
          SectionLabel(t('challenge')),
          GroupCard(
            children: [
              GroupRow(
                title: t('defaultChallenge'),
                value: t(s.defaultChallenge.name),
                onTap: () async {
                  // QR / barcode need a per-alarm registered code, so they are
                  // chosen per alarm rather than as a global default.
                  final v = await _choose<ChallengeType>(
                    t('defaultChallenge'),
                    [
                      for (final c in ChallengeType.values)
                        if (!c.needsScan) (c, t(c.name)),
                    ],
                    s.defaultChallenge,
                  );
                  if (v != null) {
                    ctl.update((x) => x.copyWith(defaultChallenge: v));
                  }
                },
              ),
            ],
          ),
          SectionLabel(t('snooze')),
          GroupCard(
            children: [
              GroupRow(
                title: t('defaultSnooze'),
                value: s.defaultSnoozeMinutes == 0
                    ? t('snoozeOff')
                    : t('snoozeMinutes', {'n': s.defaultSnoozeMinutes}),
                onTap: () async {
                  final v = await _choose<int>(t('defaultSnooze'), [
                    (0, t('snoozeOff')),
                    (5, t('snoozeMinutes', {'n': 5})),
                    (10, t('snoozeMinutes', {'n': 10})),
                  ], s.defaultSnoozeMinutes);
                  if (v != null) {
                    ctl.update((x) => x.copyWith(defaultSnoozeMinutes: v));
                  }
                },
              ),
              if (s.defaultSnoozeMinutes > 0)
                GroupRow(
                  title: t('defaultMaxSnoozes'),
                  value: '${s.defaultMaxSnoozes}',
                  onTap: () async {
                    final v = await _choose<int>(t('defaultMaxSnoozes'), [
                      (1, '1'),
                      (2, '2'),
                      (3, '3'),
                    ], s.defaultMaxSnoozes);
                    if (v != null) {
                      ctl.update((x) => x.copyWith(defaultMaxSnoozes: v));
                    }
                  },
                ),
              GroupRow(
                title: t('defaultWakeCheck'),
                chevron: false,
                trailing: IosSwitch(
                  value: s.defaultWakeCheck,
                  onChanged: (v) =>
                      ctl.update((x) => x.copyWith(defaultWakeCheck: v)),
                ),
              ),
              GroupRow(
                title: t('wakeCheckDelay'),
                value: t('snoozeMinutes', {'n': s.wakeCheckDelayMinutes}),
                onTap: () async {
                  final v = await _choose<int>(t('wakeCheckDelay'), [
                    for (final m in const [3, 4, 5])
                      (m, t('snoozeMinutes', {'n': m})),
                  ], s.wakeCheckDelayMinutes);
                  if (v != null) {
                    ctl.update((x) => x.copyWith(wakeCheckDelayMinutes: v));
                  }
                },
              ),
            ],
          ),
          if (kUninstallProtectionAvailable) ...[
            SectionLabel(t('protection')),
            GroupCard(
              children: [
                GroupRow(
                  title: t('protection'),
                  chevron: false,
                  trailing: IosSwitch(
                    value: _protected,
                    onChanged: (v) => _toggleProtection(v, t),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 6, 16, 0),
              child: Text(
                t('protectionSub'),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
          SectionLabel(t('permissions')),
          if (perms != null)
            GroupCard(
              children: [
                _permTile(
                  t,
                  t('permNotifications'),
                  perms.notifications,
                  Permissions.requestNotifications,
                ),
                _permTile(
                  t,
                  t('permExact'),
                  perms.exactAlarm,
                  Permissions.requestExactAlarm,
                ),
                _permTile(
                  t,
                  t('permBattery'),
                  perms.battery,
                  Permissions.requestBattery,
                  actionLabel: t('openIt'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _permTile(
    L10n t,
    String title,
    bool granted,
    Future<void> Function() ask, {
    String? actionLabel,
  }) => GroupRow(
    title: title,
    chevron: false,
    trailing: granted
        ? const Icon(Icons.check_circle, color: Color(0xFF34C759))
        : TextButton(
            onPressed: () async {
              await ask();
              await _load();
            },
            child: Text(actionLabel ?? t('grant'), style: kOrangeText),
          ),
  );
}

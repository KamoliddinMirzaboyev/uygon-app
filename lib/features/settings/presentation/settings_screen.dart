import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/permissions.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final p = await Permissions.check();
    if (mounted) setState(() => _perms = p);
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

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final s = ref.watch(settingsProvider);
    final ctl = ref.read(settingsProvider.notifier);
    final perms = _perms;
    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(t('language')),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'uz', label: Text(t('uzbek'))),
              ButtonSegment(value: 'en', label: Text(t('english'))),
            ],
            selected: {s.language},
            onSelectionChanged: (v) =>
                ctl.update((x) => x.copyWith(language: v.first)),
          ),
          _header(t('defaultChallenge')),
          SegmentedButton<ChallengeType>(
            segments: [
              ButtonSegment(value: ChallengeType.math, label: Text(t('math'))),
              ButtonSegment(value: ChallengeType.shake, label: Text(t('shake'))),
              ButtonSegment(value: ChallengeType.typing, label: Text(t('typing'))),
            ],
            selected: {s.defaultChallenge},
            onSelectionChanged: (v) =>
                ctl.update((x) => x.copyWith(defaultChallenge: v.first)),
          ),
          _header(t('defaultSnooze')),
          Wrap(spacing: 8, children: [
            for (final m in const [0, 5, 10])
              ChoiceChip(
                label: Text(m == 0 ? t('snoozeOff') : t('snoozeMinutes', {'n': m})),
                selected: s.defaultSnoozeMinutes == m,
                onSelected: (_) =>
                    ctl.update((x) => x.copyWith(defaultSnoozeMinutes: m)),
              ),
          ]),
          if (s.defaultSnoozeMinutes > 0) ...[
            _header(t('defaultMaxSnoozes')),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
              ],
              selected: {s.defaultMaxSnoozes.clamp(1, 3)},
              onSelectionChanged: (v) =>
                  ctl.update((x) => x.copyWith(defaultMaxSnoozes: v.first)),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('defaultWakeCheck')),
            value: s.defaultWakeCheck,
            onChanged: (v) => ctl.update((x) => x.copyWith(defaultWakeCheck: v)),
          ),
          _header(t('wakeCheckDelay')),
          SegmentedButton<int>(
            segments: [
              for (final m in const [3, 4, 5])
                ButtonSegment(value: m, label: Text(t('snoozeMinutes', {'n': m}))),
            ],
            selected: {s.wakeCheckDelayMinutes},
            onSelectionChanged: (v) =>
                ctl.update((x) => x.copyWith(wakeCheckDelayMinutes: v.first)),
          ),
          _header(t('permissions')),
          if (perms != null) ...[
            _permTile(t, t('permNotifications'), perms.notifications,
                Permissions.requestNotifications),
            _permTile(t, t('permExact'), perms.exactAlarm,
                Permissions.requestExactAlarm),
            _permTile(t, t('permBattery'), perms.battery,
                Permissions.requestBattery),
          ],
        ],
      ),
    );
  }

  Widget _permTile(L10n t, String title, bool granted, Future<void> Function() ask) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          granted ? Icons.check_circle : Icons.error_outline,
          color: granted ? Colors.green : Theme.of(context).colorScheme.error,
        ),
        title: Text(title),
        trailing: granted
            ? Text(t('granted'))
            : FilledButton.tonal(
                onPressed: () async {
                  await ask();
                  await _load();
                },
                child: Text(t('grant')),
              ),
      );

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}

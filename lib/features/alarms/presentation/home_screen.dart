import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/permissions.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/alarms_controller.dart';
import '../domain/uyg_alarm.dart';
import 'alarm_edit_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  PermissionState? _perms;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Permissions.requestAll();
    await _refresh();
  }

  Future<void> _refresh() async {
    final p = await Permissions.check();
    if (mounted) setState(() => _perms = p);
    await ref.read(alarmsProvider.notifier).reconcile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _open(UygAlarm? alarm) async {
    final target = alarm ?? await ref.read(alarmsProvider.notifier).create();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AlarmEditScreen(alarm: target, isNew: alarm == null),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final alarms = ref.watch(alarmsProvider);
    final perms = _perms;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('appName')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(null),
        icon: const Icon(Icons.add),
        label: Text(t('newAlarm')),
      ),
      body: Column(
        children: [
          if (perms != null && !perms.allGranted)
            _PermissionBanner(
              t: t,
              onFix: () async {
                if (!perms.notifications) await Permissions.requestNotifications();
                if (!perms.exactAlarm) await Permissions.requestExactAlarm();
                if (!perms.battery) await Permissions.requestBattery();
                await _refresh();
              },
            ),
          Expanded(
            child: alarms.isEmpty
                ? Center(
                    child: Text(
                      t('noAlarms'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: alarms.length,
                    itemBuilder: (_, i) => _AlarmTile(
                      key: ValueKey(alarms[i].id),
                      alarm: alarms[i],
                      t: t,
                      onTap: () => _open(alarms[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.t, required this.onFix});

  final L10n t;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
        title: Text(t('permBannerTitle'),
            style: TextStyle(color: scheme.onErrorContainer)),
        subtitle: Text(t('permBannerBody'),
            style: TextStyle(color: scheme.onErrorContainer)),
        trailing: FilledButton(onPressed: onFix, child: Text(t('fix'))),
      ),
    );
  }
}

class _AlarmTile extends ConsumerWidget {
  const _AlarmTile({
    super.key,
    required this.alarm,
    required this.t,
    required this.onTap,
  });

  final UygAlarm alarm;
  final L10n t;
  final VoidCallback onTap;

  String _repeatText() {
    if (!alarm.isRepeating) return t('once');
    if (alarm.days.length == 7) return t('everyDay');
    final names = t.weekdaysShort;
    final sorted = alarm.days.toList()..sort();
    return sorted.map((d) => names[d - 1]).join(' ');
  }

  String _countdown() {
    final next = alarm.nextOccurrence();
    if (next == null) return t('alarmDisabled');
    final diff = next.difference(DateTime.now());
    final d = diff.inDays, h = diff.inHours % 24, m = diff.inMinutes % 60 + 1;
    final text = d > 0
        ? t('ringsInDM', {'d': d, 'h': h, 'm': m})
        : diff.inHours > 0
            ? t('ringsInHM', {'h': diff.inHours, 'm': m})
            : t('ringsInM', {'m': m});
    return t('ringsIn', {'t': text});
  }

  IconData get _icon => switch (alarm.challenge.name) {
        'math' => Icons.calculate_outlined,
        'shake' => Icons.vibration,
        _ => Icons.keyboard_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final time =
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    final dim = !alarm.enabled;
    return Dismissible(
      key: ValueKey('dismiss${alarm.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => ref.read(alarmsProvider.notifier).remove(alarm),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedOpacity(
                    opacity: dim ? 0.45 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (alarm.label.isNotEmpty) alarm.label,
                            _repeatText(),
                          ].join(' · '),
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(_icon, size: 16, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            _countdown(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                Switch(
                  value: alarm.enabled,
                  onChanged: (v) =>
                      ref.read(alarmsProvider.notifier).toggle(alarm, v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations.dart';
import '../../../core/ios_widgets.dart';
import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../core/permissions.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/alarms_controller.dart';
import '../domain/uyg_alarm.dart';
import 'alarm_edit_screen.dart';
import '../../challenges/domain/challenge_icons.dart';

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
    // Never put a permission dialog on top of a ringing alarm.
    if (!await Alarm.isRinging()) await Permissions.requestAll();
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AlarmEditScreen(alarm: target, isNew: alarm == null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final alarms = ref.watch(alarmsProvider);
    final perms = _perms;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: kAccent),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: kAccent, size: 32),
                    onPressed: () => _open(null),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t('alarms'),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (perms != null && !perms.allGranted)
              _PermissionBanner(
                t: t,
                onFix: () async {
                  if (!perms.notifications) {
                    await Permissions.requestNotifications();
                  }
                  if (!perms.exactAlarm) await Permissions.requestExactAlarm();
                  if (!perms.battery) await Permissions.requestBattery();
                  await _refresh();
                },
              ),
            Expanded(
              child: alarms.isEmpty
                  ? _EmptyState(t: t, onAdd: () => _open(null))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
                      itemCount: alarms.length,
                      itemBuilder: (_, i) => FadeSlideIn(
                        key: ValueKey(alarms[i].id),
                        delay: Duration(milliseconds: 60 * i.clamp(0, 8)),
                        child: _AlarmTile(
                          alarm: alarms[i],
                          t: t,
                          onTap: () => _open(alarms[i]),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.t, required this.onAdd});

  final L10n t;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: FadeSlideIn(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kAccent.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.alarm_add, size: 54, color: kAccent),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t('emptyTitle'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              t('emptyBody'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 50),
              ),
              icon: const Icon(Icons.add),
              label: Text(t('addFirst')),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.t, required this.onFix});

  final L10n t;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(
          Icons.warning_amber_rounded,
          color: scheme.onErrorContainer,
        ),
        title: Text(
          t('permBannerTitle'),
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        subtitle: Text(
          t('permBannerBody'),
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        trailing: FilledButton(onPressed: onFix, child: Text(t('fix'))),
      ),
    );
  }
}

class _AlarmTile extends ConsumerWidget {
  const _AlarmTile({required this.alarm, required this.t, required this.onTap});

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
    final total = (next.difference(DateTime.now()).inSeconds / 60).ceil();
    final d = total ~/ 1440, h = (total % 1440) ~/ 60, m = total % 60;
    final text = d > 0
        ? t('ringsInDM', {'d': d, 'h': h, 'm': m})
        : h > 0
        ? t('ringsInHM', {'h': h, 'm': m})
        : t('ringsInM', {'m': total});
    return t('ringsIn', {'t': text});
  }

  IconData get _icon => challengeIcon(alarm.challenge);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final time =
        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
    final dim = !alarm.enabled;
    final subtitle = [
      if (alarm.label.isNotEmpty) alarm.label else t('labelHint'),
      _repeatText(),
    ].join(', ');
    return Dismissible(
      key: ValueKey('dismiss${alarm.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async =>
          await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(t('deleteConfirm')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(t('cancel'), style: kOrangeText),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: Text(
                    t('delete'),
                    style: const TextStyle(color: Colors.red, fontSize: 17),
                  ),
                ),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) {
        ref.read(alarmsProvider.notifier).remove(alarm);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t('deleted'))));
      },
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: dim ? 0.4 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 58,
                              fontWeight: FontWeight.w200,
                              height: 1.05,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  subtitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(_icon, size: 16, color: kAccent),
                            ],
                          ),
                          if (alarm.enabled)
                            Text(
                              _countdown(),
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IosSwitch(
                    value: alarm.enabled,
                    onChanged: (v) =>
                        ref.read(alarmsProvider.notifier).toggle(alarm, v),
                  ),
                ],
              ),
            ),
          ),
          const Divider(indent: 20),
        ],
      ),
    );
  }
}

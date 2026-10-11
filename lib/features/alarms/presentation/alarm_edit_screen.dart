import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/l10n.dart';
import '../../challenges/domain/challenge_type.dart';
import '../../challenges/presentation/ring_screen.dart';
import '../application/alarm_scheduler.dart';
import '../application/alarms_controller.dart';
import '../domain/uyg_alarm.dart';

class AlarmEditScreen extends ConsumerStatefulWidget {
  const AlarmEditScreen({super.key, required this.alarm, required this.isNew});

  final UygAlarm alarm;
  final bool isNew;

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  late UygAlarm _a = widget.alarm;
  late final _label = TextEditingController(text: _a.label);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _set(UygAlarm a) => setState(() => _a = a);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _a.hour, minute: _a.minute),
    );
    if (picked != null) _set(_a.copyWith(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _save() async {
    await ref
        .read(alarmsProvider.notifier)
        .upsert(_a.copyWith(label: _label.text.trim(), enabled: true));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final t = ref.read(l10nProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t('deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(t('delete'))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(alarmsProvider.notifier).remove(widget.alarm);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _pickRingtone() async {
    final t = ref.read(l10nProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: Text(t('systemDefault')),
              selected: _a.ringtone == kSystemSound,
              onTap: () => Navigator.pop(c, kSystemSound),
            ),
            for (final s in kBuiltInSounds)
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: Text(t('sound_$s')),
                selected: _a.ringtone == '$kBuiltInPrefix$s',
                onTap: () => Navigator.pop(c, '$kBuiltInPrefix$s'),
              ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(t('customFile')),
              onTap: () => Navigator.pop(c, 'custom'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice != 'custom') return _set(_a.copyWith(ringtone: choice));

    final picked = await FilePicker.pickFile(type: FileType.audio);
    final path = picked?.path;
    if (path == null) return;
    // Copy next to the app's data so it survives the picker's cache cleanup.
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'ringtones'));
    await dir.create(recursive: true);
    final name = '${_a.id}_${p.basename(path)}';
    await File(path).copy(p.join(dir.path, name));
    _set(_a.copyWith(ringtone: p.join('ringtones', name)));
  }

  String _ringtoneName(L10n t) {
    if (_a.ringtone == kSystemSound) return t('systemDefault');
    if (_a.ringtone.startsWith(kBuiltInPrefix)) {
      return t('sound_${_a.ringtone.substring(kBuiltInPrefix.length)}');
    }
    return t('customFileNamed', {'name': p.basename(_a.ringtone)});
  }

  void _preview() {
    final payload = RingPayload(_a.id, RingKind.ring);
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RingScreen(nativeId: 0, payload: payload, preview: true),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final scheme = Theme.of(context).colorScheme;
    final time =
        '${_a.hour.toString().padLeft(2, '0')}:${_a.minute.toString().padLeft(2, '0')}';
    final names = t.weekdaysShort;
    return Scaffold(
      appBar: AppBar(
        title: Text(t(widget.isNew ? 'newAlarm' : 'editAlarm')),
        actions: [
          if (!widget.isNew)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          TextButton(onPressed: _save, child: Text(t('save'))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _pickTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  time,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 88,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                ),
              ),
            ),
          ),
          TextField(
            controller: _label,
            decoration: InputDecoration(
              labelText: t('label'),
              hintText: t('labelHint'),
              prefixIcon: const Icon(Icons.label_outline),
            ),
          ),
          _section(t('repeat')),
          Wrap(
            spacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(names[d - 1]),
                  selected: _a.days.contains(d),
                  onSelected: (on) => _set(_a.copyWith(
                    days: on ? {..._a.days, d} : ({..._a.days}..remove(d)),
                  )),
                ),
            ],
          ),
          Wrap(spacing: 8, children: [
            ActionChip(
              label: Text(t('weekdays')),
              onPressed: () => _set(_a.copyWith(days: {1, 2, 3, 4, 5})),
            ),
            ActionChip(
              label: Text(t('everyDay')),
              onPressed: () => _set(_a.copyWith(days: {1, 2, 3, 4, 5, 6, 7})),
            ),
            ActionChip(
              label: Text(t('once')),
              onPressed: () => _set(_a.copyWith(days: const {})),
            ),
          ]),
          _section(t('challenge')),
          SegmentedButton<ChallengeType>(
            segments: [
              ButtonSegment(
                  value: ChallengeType.math,
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(t('math'))),
              ButtonSegment(
                  value: ChallengeType.shake,
                  icon: const Icon(Icons.vibration),
                  label: Text(t('shake'))),
              ButtonSegment(
                  value: ChallengeType.typing,
                  icon: const Icon(Icons.keyboard_outlined),
                  label: Text(t('typing'))),
            ],
            selected: {_a.challenge},
            onSelectionChanged: (s) => _set(_a.copyWith(challenge: s.first)),
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            alignment: Alignment.topCenter,
            child: switch (_a.challenge) {
              ChallengeType.math => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('difficulty')),
                    const SizedBox(height: 8),
                    SegmentedButton<Difficulty>(
                      segments: [
                        ButtonSegment(value: Difficulty.easy, label: Text(t('easy'))),
                        ButtonSegment(value: Difficulty.medium, label: Text(t('medium'))),
                        ButtonSegment(value: Difficulty.hard, label: Text(t('hard'))),
                      ],
                      selected: {_a.difficulty},
                      onSelectionChanged: (s) => _set(_a.copyWith(difficulty: s.first)),
                    ),
                  ],
                ),
              ChallengeType.shake => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('shakeCount', {'n': _a.shakeCount})),
                    Slider(
                      value: _a.shakeCount.toDouble(),
                      min: 20,
                      max: 50,
                      divisions: 6,
                      label: '${_a.shakeCount}',
                      onChanged: (v) => _set(_a.copyWith(shakeCount: v.round())),
                    ),
                  ],
                ),
              ChallengeType.typing => const SizedBox.shrink(),
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.play_arrow),
              label: Text(t('testChallenge')),
            ),
          ),
          _section(t('ringtone')),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.music_note),
            title: Text(_ringtoneName(t)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickRingtone,
          ),
          _section(t('snooze')),
          Wrap(spacing: 8, children: [
            for (final m in const [0, 5, 10])
              ChoiceChip(
                label: Text(m == 0 ? t('snoozeOff') : t('snoozeMinutes', {'n': m})),
                selected: _a.snoozeMinutes == m,
                onSelected: (_) => _set(_a.copyWith(snoozeMinutes: m)),
              ),
          ]),
          if (_a.snoozeMinutes > 0) ...[
            const SizedBox(height: 12),
            Text(t('maxSnoozes')),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
              ],
              selected: {_a.maxSnoozes.clamp(1, 3)},
              onSelectionChanged: (s) => _set(_a.copyWith(maxSnoozes: s.first)),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('wakeCheck')),
            subtitle: Text(t('wakeCheckSub')),
            value: _a.wakeCheck,
            onChanged: (v) => _set(_a.copyWith(wakeCheck: v)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

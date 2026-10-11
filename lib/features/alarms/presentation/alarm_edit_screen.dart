import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoTextThemeData,
        CupertinoTheme,
        CupertinoThemeData;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/animations.dart';
import '../../../core/ios_widgets.dart';
import '../../../core/l10n.dart';
import '../../../core/native_channels.dart';
import '../../../core/theme.dart';
import '../../challenges/domain/challenge_icons.dart';
import '../../challenges/domain/challenge_type.dart';
import '../../challenges/presentation/ring_screen.dart';
import '../../challenges/presentation/scan_widgets.dart';
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

  Future<void> _save() async {
    final t = ref.read(l10nProvider);
    if (_a.challenge.needsScan && (_a.scanValue ?? '').isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('scanRequired'))));
      return;
    }
    final ok = await ref
        .read(alarmsProvider.notifier)
        .upsert(_a.copyWith(label: _label.text.trim(), enabled: true));
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('scheduleFailed'))));
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final t = ref.read(l10nProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(alarmsProvider.notifier).remove(widget.alarm);
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ---- repeat -------------------------------------------------------------

  String _repeatSummary(L10n t) {
    if (_a.days.isEmpty) return t('once');
    if (_a.days.length == 7) return t('everyDay');
    if (_a.days.length == 5 && !_a.days.contains(6) && !_a.days.contains(7)) {
      return t('weekdays');
    }
    if (_a.days.length == 2 && _a.days.containsAll([6, 7])) {
      return t('weekends');
    }
    final names = t.weekdaysShort;
    return (_a.days.toList()..sort()).map((d) => names[d - 1]).join(' ');
  }

  Future<void> _pickRepeat(L10n t) async {
    var days = {..._a.days};
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var d = 1; d <= 7; d++)
                ListTile(
                  title: Text(t.weekdaysFull[d - 1]),
                  trailing: days.contains(d)
                      ? const Icon(Icons.check, color: kAccent)
                      : null,
                  onTap: () => setSheet(() {
                    days.contains(d) ? days.remove(d) : days.add(d);
                    _set(_a.copyWith(days: {...days}));
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- challenge ----------------------------------------------------------

  Future<void> _pickChallenge(L10n t) async {
    final picked = await showModalBottomSheet<ChallengeType>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in ChallengeType.values)
              ListTile(
                leading: Icon(challengeIcon(type), color: kAccent),
                title: Text(t(type.name)),
                subtitle: Text(t('${type.name}Sub')),
                trailing: type == _a.challenge
                    ? const Icon(Icons.check, color: kAccent)
                    : null,
                onTap: () => Navigator.pop(c, type),
              ),
          ],
        ),
      ),
    );
    if (picked != null) _set(_a.copyWith(challenge: picked));
  }

  Future<void> _registerCode(L10n t) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RegisterCodeScreen(type: _a.challenge),
      ),
    );
    if (code != null) _set(_a.copyWith(scanValue: code));
  }

  List<Widget> _challengeParams(L10n t) {
    switch (_a.challenge) {
      case ChallengeType.math:
        return [
          GroupRow(
            title: t('difficulty'),
            chevron: false,
            trailing: SegmentedButton<Difficulty>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: Difficulty.easy, label: Text(t('easy'))),
                ButtonSegment(
                  value: Difficulty.medium,
                  label: Text(t('medium')),
                ),
                ButtonSegment(value: Difficulty.hard, label: Text(t('hard'))),
              ],
              selected: {_a.difficulty},
              onSelectionChanged: (s) => _set(_a.copyWith(difficulty: s.first)),
            ),
          ),
        ];
      case ChallengeType.shake:
        return [
          _sliderRow(
            t('shakeCount', {'n': _a.shakeCount}),
            _a.shakeCount,
            20,
            50,
            6,
            (v) => _set(_a.copyWith(shakeCount: v)),
          ),
        ];
      case ChallengeType.walk:
        return [
          _sliderRow(
            t('walkDistance', {'m': _a.walkMeters}),
            _a.walkMeters,
            20,
            100,
            8,
            (v) => _set(_a.copyWith(walkMeters: v)),
          ),
        ];
      case ChallengeType.qr:
      case ChallengeType.barcode:
        final has = (_a.scanValue ?? '').isNotEmpty;
        return [
          GroupRow(
            title: t(has ? 'scanRescan' : 'scanRegister'),
            value: has ? '✓ ${t('scanRegistered')}' : null,
            onTap: () => _registerCode(t),
          ),
        ];
      case ChallengeType.typing:
        return const [];
    }
  }

  Widget _sliderRow(
    String title,
    int value,
    int min,
    int max,
    int divisions,
    ValueChanged<int> onChanged,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17)),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    ),
  );

  // ---- ringtone -----------------------------------------------------------

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
              leading: const Icon(Icons.library_music),
              title: Text(t('phoneRingtones')),
              onTap: () => Navigator.pop(c, 'phone'),
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
    if (choice == 'phone') return _pickPhoneSound(t);
    if (choice != 'custom') return _set(_a.copyWith(ringtone: choice));

    final picked = await FilePicker.pickFile(type: FileType.audio);
    final path = picked?.path;
    if (path == null) return;
    // Copy next to the app's data so it survives the picker's cache cleanup.
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'ringtones'),
    );
    await dir.create(recursive: true);
    final name = '${_a.id}_${p.basename(path)}';
    await File(path).copy(p.join(dir.path, name));
    _set(_a.copyWith(ringtone: p.join('ringtones', name)));
  }

  Future<void> _pickPhoneSound(L10n t) async {
    final sounds = await SystemRingtones.list();
    if (!mounted) return;
    final picked = await showModalBottomSheet<SystemSound>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scroll) => Column(
          children: [
            Text(
              t('phoneRingtonesTitle'),
              style: Theme.of(c).textTheme.titleMedium,
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: sounds.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(sounds[i].title),
                  onTap: () => Navigator.pop(c, sounds[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final safe = picked.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    final rel = await SystemRingtones.copy(picked.uri, 'sys_${_a.id}_$safe');
    _set(_a.copyWith(ringtone: rel));
  }

  String _ringtoneName(L10n t) {
    if (_a.ringtone == kSystemSound) return t('systemDefault');
    if (_a.ringtone.startsWith(kBuiltInPrefix)) {
      return t('sound_${_a.ringtone.substring(kBuiltInPrefix.length)}');
    }
    final base = p.basename(_a.ringtone);
    if (base.startsWith('sys_')) {
      final name = base
          .replaceFirst(RegExp(r'^sys_\d+_'), '')
          .replaceAll('_', ' ');
      return t('phoneSoundNamed', {'name': name});
    }
    return t('customFileNamed', {'name': base});
  }

  void _preview() {
    final payload = RingPayload(_a.id, RingKind.ring);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => RingScreen(
          nativeId: 0,
          payload: payload,
          preview: true,
          previewAlarm: _a,
        ),
      ),
    );
  }

  Future<void> _pickSnoozeMinutes(L10n t) async {
    final m = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in const [5, 10])
              ListTile(
                title: Text(t('snoozeMinutes', {'n': v})),
                trailing: _a.snoozeMinutes == v
                    ? const Icon(Icons.check, color: kAccent)
                    : null,
                onTap: () => Navigator.pop(c, v),
              ),
          ],
        ),
      ),
    );
    if (m != null) _set(_a.copyWith(snoozeMinutes: m));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(l10nProvider);
    final snoozeOn = _a.snoozeMinutes > 0;
    final initial = DateTime(2000, 1, 1, _a.hour, _a.minute);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 130,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t('cancel'), style: kOrangeText),
          ),
        ),
        title: Text(
          t(widget.isNew ? 'newAlarm' : 'editAlarm'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              t('save'),
              style: kOrangeText.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                brightness: Brightness.dark,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: initial,
                onDateTimeChanged: (d) =>
                    _set(_a.copyWith(hour: d.hour, minute: d.minute)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: GroupCard(
              children: [
                GroupRow(
                  title: t('repeat'),
                  value: _repeatSummary(t),
                  onTap: () => _pickRepeat(t),
                ),
                GroupRow(
                  title: t('label'),
                  chevron: false,
                  trailing: SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _label,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: t('labelHint'),
                      ),
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                ),
                GroupRow(
                  title: t('ringtone'),
                  value: _ringtoneName(t),
                  onTap: _pickRingtone,
                ),
              ],
            ),
          ),
          SectionLabel(t('challenge')),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: GroupCard(
              children: [
                GroupRow(
                  title: t('challenge'),
                  value: t(_a.challenge.name),
                  onTap: () => _pickChallenge(t),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(_a.challenge),
                      children: _challengeParams(t),
                    ),
                  ),
                ),
                GroupRow(
                  title: t('testChallenge'),
                  titleColor: kAccent,
                  chevron: false,
                  onTap: _preview,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GroupCard(
            children: [
              GroupRow(
                title: t('snooze'),
                chevron: false,
                trailing: IosSwitch(
                  value: snoozeOn,
                  onChanged: (v) => _set(_a.copyWith(snoozeMinutes: v ? 5 : 0)),
                ),
              ),
              if (snoozeOn) ...[
                GroupRow(
                  title: t('snoozeDuration'),
                  value: t('snoozeMinutes', {'n': _a.snoozeMinutes}),
                  onTap: () => _pickSnoozeMinutes(t),
                ),
                GroupRow(
                  title: t('maxSnoozes'),
                  chevron: false,
                  trailing: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1')),
                      ButtonSegment(value: 2, label: Text('2')),
                      ButtonSegment(value: 3, label: Text('3')),
                    ],
                    selected: {_a.maxSnoozes.clamp(1, 3)},
                    onSelectionChanged: (s) =>
                        _set(_a.copyWith(maxSnoozes: s.first)),
                  ),
                ),
              ],
              GroupRow(
                title: t('wakeCheck'),
                chevron: false,
                trailing: IosSwitch(
                  value: _a.wakeCheck,
                  onChanged: (v) => _set(_a.copyWith(wakeCheck: v)),
                ),
              ),
            ],
          ),
          if (!widget.isNew) ...[
            const SizedBox(height: 20),
            GroupCard(
              children: [
                GroupRow(
                  title: t('delete'),
                  titleColor: Colors.red,
                  chevron: false,
                  onTap: _delete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen scanner used to register the code the user must scan later.
class _RegisterCodeScreen extends ConsumerWidget {
  const _RegisterCodeScreen({required this.type});

  final ChallengeType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(l10nProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t(type.name))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(t('scanHint'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Expanded(
              child: CodeScanner(
                type: type,
                height: double.infinity,
                onCode: (v) => Navigator.of(context).pop(v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

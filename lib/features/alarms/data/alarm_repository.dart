import '../../../core/storage.dart';
import '../domain/uyg_alarm.dart';

class AlarmRepository {
  static const _counterKey = 'nextAlarmId';

  List<UygAlarm> all() {
    final list = Storage.alarms.values
        .whereType<Map>()
        .map(UygAlarm.fromJson)
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return list;
  }

  UygAlarm? byId(int id) {
    final raw = Storage.alarms.get('a$id');
    return raw is Map ? UygAlarm.fromJson(raw) : null;
  }

  Future<void> save(UygAlarm a) => Storage.alarms.put('a${a.id}', a.toJson());

  Future<void> delete(int id) => Storage.alarms.delete('a$id');

  /// Base ids stay small: scheduler ids are `base * 10 + slot` and must fit
  /// in a 32-bit int.
  Future<int> nextId() async {
    final n = (Storage.settings.get(_counterKey) as int? ?? 0) + 1;
    await Storage.settings.put(_counterKey, n);
    return n;
  }
}

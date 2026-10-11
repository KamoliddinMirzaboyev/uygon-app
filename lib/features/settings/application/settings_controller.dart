import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage.dart';
import '../domain/app_settings.dart';

class SettingsController extends Notifier<AppSettings> {
  static const _key = 'app';

  @override
  AppSettings build() {
    final raw = Storage.settings.get(_key);
    return raw is Map ? AppSettings.fromJson(raw) : const AppSettings();
  }

  void update(AppSettings Function(AppSettings) change) {
    state = change(state);
    Storage.settings.put(_key, state.toJson());
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

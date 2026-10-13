import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/demo_seed.dart';
import 'core/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await seedDemoData(); // no-op unless built with SEED_DEMO
  await Alarm.init();
  runApp(const ProviderScope(child: WakyApp()));
}

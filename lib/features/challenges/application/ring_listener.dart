import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';

import '../../alarms/application/alarm_scheduler.dart';
import '../presentation/ring_screen.dart';

/// Watches the native ringing state and pushes [RingScreen] over whatever
/// the app is showing. The alarm keeps sounding natively until the screen
/// stops it, so even if this route is lost (process death, user pressing
/// Home) the notification's full-screen intent brings it back.
class RingListener {
  RingListener(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;
  StreamSubscription<AlarmSet>? _sub;
  int? _shownNativeId;

  void start() {
    _sub ??= Alarm.ringing.listen(_onRinging);
  }

  void dispose() => _sub?.cancel();

  void _onRinging(AlarmSet set) {
    // Forget the shown alarm once it is no longer ringing so that the next
    // ring (e.g. snooze / wake-up check with the same id) is shown again.
    if (_shownNativeId != null && !set.containsId(_shownNativeId!)) {
      _shownNativeId = null;
    }
    if (_shownNativeId != null || set.alarms.isEmpty) return;
    final alarm = set.alarms.first;
    final payload = RingPayload.decode(alarm.payload);
    if (payload == null) return;
    _shownNativeId = alarm.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => RingScreen(nativeId: alarm.id, payload: payload),
      ));
    });
  }
}

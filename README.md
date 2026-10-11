# Uyg'on — challenge alarm clock (Android MVP)

An alarm you cannot just swipe away. The alarm keeps ringing until you solve a
challenge: **Math**, **Shake**, **Typing**, **QR code**, **Barcode** or **Walk (e.g. 50 m)**. Uzbek is the primary language,
English the fallback. Dark Material 3 UI by default.

## Setup

```bash
flutter pub get
flutter run            # on a real Android device (API 26+) – strongly recommended
flutter build apk --release
```

Requires Flutter 3.47+ / Dart 3.13+, JDK 17, Android SDK platform 37
(`compileSdk = 37` – needed by `permission_handler_android`).

## Architecture

```
lib/
  core/              l10n (uz/en), theme, Hive storage, permissions
  features/
    alarms/          model, Hive repository, scheduler (alarm pkg), home + edit UI
    challenges/      math / shake / typing logic + widgets, ring screen, ring listener
    settings/        language, defaults, permission status
```

State: Riverpod 3 (`Notifier`). Storage: Hive (plain JSON maps, no codegen).
Scheduling, audio, vibration, foreground service, full-screen intent and
boot recovery: the [`alarm`](https://pub.dev/packages/alarm) package
(`AlarmManager.setAlarmClock`, so Doze-exempt).

### How scheduling works
Each alarm owns native ids `id*10 + slot`: slot 0 = one-shot, 1–7 = one per
repeat weekday, 8 = pending snooze, 9 = pending wake-up check. Weekly slots are
re-armed (+7 days) when the alarm is stopped, and `reconcile()` re-arms anything
missing on every app start/resume. The native side re-registers alarms after reboot.

### How dismissal is blocked
* The notification has **no stop button**, and swiping it does not stop the alarm.
* Stopping happens only from `RingScreen` after the challenge succeeds (or when a
  limited snooze is spent).
* Back / predictive back is disabled (`PopScope`) while the challenge is open.
* Alarm audio is volume-enforced at 100 % on the alarm stream.
* Closing the app from Recents does not stop the alarm (`androidStopAlarmOnTermination: false`).

## Manual test plan
1. Open the app, grant notifications + "Alarms & reminders"; allow ignoring battery optimizations.
2. Create an alarm 2 minutes ahead; in the editor, press **Try challenge** to preview each type.
3. Lock the phone / swipe the app away. At the time the screen turns on with the ring screen.
4. **Math**: 3 correct answers in a row (a wrong one resets). **Shake**: shake N times.
   **Typing**: type the sentence (case, spacing and apostrophe variants are tolerated; paste is disabled).
5. Press Home, or pull down the notification: the sound continues. Re-open → still the challenge.
6. Snooze: set 5 min / max 2; the button shows remaining snoozes; after the last one it disappears.
7. Wake-up check: enable it, solve; after 3–5 min (Settings) a second ring asks "Are you awake?".
8. Reboot the phone with an alarm set; it still rings.
9. Repeat days: pick weekdays, confirm the home tile shows the correct countdown; it rings again next week.
10. Settings: switch language Uzbek ↔ English, change defaults, see permission status.

## Tasks (v2)
* **QR / Barcode**: in the editor you scan *your* code once (e.g. a sticker in the bathroom);
  to stop the alarm you must scan that same code. Without a saved code the alarm falls back to math.
* **Walk**: hardware step counter (`pedometer`, needs the *Physical activity* permission); 0.7 m/step.
  Falls back to accelerometer step detection if the sensor is unavailable.
* **Mute**: on the ring screen "1 / 2 daqiqa jim" silences the sound while you work on the task.
  The native alarm is re-armed, so the music returns after that time even if the app is killed.
* UI follows the iPhone Clock style (black, orange accent, wheel time picker, grouped lists)
  and is fully Uzbek (English can be chosen in Settings).

## Phone sounds & uninstall protection
* **Ringtone → "Telefon ohanglari…"** lists the phone's own alarm/ringtone sounds
  (`RingtoneManager`); the chosen sound is copied into the app's data folder because the
  alarm service plays file paths.
* **Settings → Uninstall protection** (opt-in) registers a policy-less device admin: Android
  then requires deactivating it in system settings before uninstalling. Turning it off inside
  the app requires solving a math challenge. It is not true anti-uninstall: the user can still
  deactivate it in Settings → Security → Device admin apps, or uninstall via safe mode/ADB.

## Known limitations
* **Android cannot fully lock a user into an app.** The Home button and the app
  switcher still work; the alarm keeps sounding and the full-screen notification/app re-opens
  from the notification, but a determined user can power off the phone or force-stop the app.
* Aggressive OEMs (Xiaomi, Huawei, Oppo, Samsung "sleeping apps") may need
  *Autostart* / "unrestricted battery" enabled manually.
* Android 14+ may require the user to allow full-screen notifications in system
  settings (App info → Notifications) on devices where it is not granted by default.
* Ringtone: built-in loud sounds are synthesised beeps (replace the files in
  `assets/sounds/` with real recordings); "system alarm sound" uses the device's default
  alarm tone; any other system tone can be chosen via the file picker (audio file).
* Wake-up check keeps ringing until "I'm awake" is pressed rather than ringing briefly.
* Shake threshold (`ShakeDetector.threshold`) may need tuning per device.
* One-shot alarms switch themselves off after they ring.
* Not implemented: photo challenge, sleep tracking, cloud, iOS, IAP/ads.
* Camera/step challenges were built but not yet tested on a device.
* Unit tests for the pure logic are in `test/logic_test.dart`. On this dev machine
  `flutter test` could not run because the Command Line Tools macOS 27 SDK breaks the
  `objective_c` native-assets link step; the logic tests pass when run as plain Dart.
  The app itself has **not been run on a device/emulator yet**.

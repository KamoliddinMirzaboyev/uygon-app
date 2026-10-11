# Uyg'on — Google Play release guide

Everything needed for the first upload is in this folder.

| File | What it is |
|---|---|
| `../Uygon-play-release.aab` | **Upload this to Play Console** (signed with the upload key) |
| `../Uygon.apk` | Same app as an APK for sharing outside Play (includes the optional uninstall protection) |
| `listing/uz.md`, `en.md`, `ru.md` | Title, short + full description, release notes |
| `graphics/icon-512.png` | App icon (512×512) |
| `graphics/feature-graphic-1024x500.png` | Feature graphic |
| `graphics/phone/01…08_*.png` | 8 phone screenshots (1080×1920) |
| `play-console-answers.md` | Data safety, content rating, permission declarations (copy-paste) |
| `../docs/privacy.html` | Privacy policy (Uzbek + English) |
| `tools/compose.py` | Re-creates the graphics from raw screenshots |

## 1. Signing key — BACK IT UP FIRST
The upload key lives **outside** the repo:

```
~/.uygon-keystore/upload-keystore.jks
~/.uygon-keystore/key.properties      (passwords)
```
`android/key.properties` is a git-ignored copy. **Copy `~/.uygon-keystore/` to a safe place (password manager / cloud drive).**
Play App Signing keeps the real app-signing key, so a lost *upload* key can be reset through Play support, but it takes days.

## 2. Privacy policy URL (required)
Publish `docs/privacy.html` with GitHub Pages:
1. Push this repo (`git push`).
2. GitHub → *Settings → Pages* → Source: **Deploy from a branch**, Branch: `main`, Folder: `/docs`.
3. URL: `https://kamoliddinmirzaboyev.github.io/uygon-app/privacy.html`

## 3. Create the app in Play Console
1. *Create app* → name `Uyg'on: Vazifali budilnik`, default language **Uzbek**, App, Free.
2. *Dashboard → Set up your app*: privacy policy URL, ads = No, app access = all available, content rating (answers in `play-console-answers.md`), target audience 13+, data safety (No data collected), government/financial/health = No.
3. *Policy → App content → Sensitive permissions*: fill the declarations for **Full-screen intent**, **Exact alarms**, **Foreground service (media playback)** with the texts in `play-console-answers.md`. Record a ~30 s screen video of an alarm ringing on a real phone for the foreground-service declaration.
4. *Store listing*: copy `listing/uz.md` (default), add English and Russian translations; upload icon, feature graphic and the 8 phone screenshots.
5. *Testing → Closed testing → Create release* → upload `Uygon-play-release.aab`, paste release notes.

> **Personal developer accounts created after 13 Nov 2023** must run a closed test with **12+ testers for 14 days** before they can apply for production access. Organisation accounts are exempt. Start the closed test as soon as the listing is filled in.

## 4. Build commands (for future releases)
```bash
# bump `version: 1.0.0+1` in pubspec.yaml first (the +N must increase for every upload)
flutter build appbundle --release --flavor play            # Play Store AAB
flutter build apk --release --flavor direct --dart-define=UNINSTALL_PROTECTION=true   # sharing APK
# store screenshots build (sample alarms, offline):
flutter build apk --release --flavor direct --dart-define=SEED_DEMO=true
```

## 5. What was checked
- Release manifest: no network permissions, no storage/battery/DND permissions; `SCHEDULE_EXACT_ALARM` only up to Android 12, `USE_EXACT_ALARM` otherwise.
- Device-admin (uninstall protection) is **not** in the `play` flavor.
- Upload-key signature verified (`apksigner`), 16 KB page-size alignment verified (`zipalign -P 16`), target SDK 36, min SDK 26.
- R8 minified release build tested on an emulator: onboarding, permissions, alarm ring from lock screen, 6 tasks (QR/barcode and hardware step counter need a real phone), mute, reboot recovery.

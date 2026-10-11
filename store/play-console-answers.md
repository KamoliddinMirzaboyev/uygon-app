# Google Play Console — ready answers

## App details
- **App name:** Uyg'on: Vazifali budilnik   (en: Uyg'on: Challenge Alarm)
- **Default language:** Uzbek (uz). Add translations: English (en-US), Russian (ru-RU) from `store/listing/`.
- **App or game:** App · **Free**
- **Category:** Tools (alternative: Productivity)
- **Tags:** Alarm clock, Productivity
- **Contact email:** kamoliddinmirzaboyev2005@gmail.com (change if your developer account differs)
- **Privacy policy URL:** see `store/README.md` (GitHub Pages: `https://kamoliddinmirzaboyev.github.io/uygon-app/privacy.html`)

## App content
- **Ads:** No
- **App access:** All functionality available without login or special access
- **Target audience:** 13+ (not directed to children) → no Families policy
- **Content rating (IARC questionnaire):** category *Utility/Productivity*; no violence, sexual content, gambling, drugs, user-generated content, location sharing or purchases → expected rating **Everyone / PEGI 3**
- **News app / COVID / government / financial / health:** No
- **Data safety:** *No data collected, no data shared* (see below)

## Data safety form
- Does your app collect or share any of the required user data types? **No**
- Reason it is true: no INTERNET permission in the release build; no analytics/ads/crash SDKs; alarms, settings and any chosen audio/QR text stay in app-private storage; camera frames and step counts are processed on device only; cloud backup disabled.
- Is all of the user data encrypted in transit? Not applicable (no data transmitted).
- Do you provide a way for users to request data deletion? Not applicable (no data collected; uninstalling removes local data).

## Sensitive permission declarations (Policy → App content)

### USE_FULL_SCREEN_INTENT
> Uyg'on is an alarm clock. When an alarm fires while the phone is locked or the screen is off, the app must show the alarm screen (the task the user must complete to turn the alarm off) full screen and turn the screen on. This is the core, user-visible function of the app.

### USE_EXACT_ALARM (and SCHEDULE_EXACT_ALARM, Android 12 only)
> The app's core function is an alarm clock: alarms must ring at the exact time the user chose. The app uses AlarmManager.setAlarmClock for user-set alarms. It qualifies for USE_EXACT_ALARM as an alarm-clock app.

### Foreground service — type: mediaPlayback (FOREGROUND_SERVICE_MEDIA_PLAYBACK)
> When an alarm rings, a foreground service plays the alarm sound (looping audio with vibration) and keeps the ring session alive until the user completes the task. Task: *Alarm ringing*. User impact if not allowed: the alarm could be killed by the system and fail to wake the user.
>
> Demo video: record the screen while an alarm rings on a real phone: lock screen → alarm screen with sound → complete task → sound stops.

### CAMERA (optional, uses-feature required=false)
> Used only for the optional "QR code" and "Barcode" tasks to scan a code the user registered. No images are stored or transmitted.

### ACTIVITY_RECOGNITION
> Used only for the optional "Walk" task to count steps. Data stays on the device.

## Not in the Play build
The optional *uninstall protection* (device-admin) feature exists only in the `direct` flavor (APK for sharing outside Google Play). The Play flavor does not declare the admin receiver and has no network permission.

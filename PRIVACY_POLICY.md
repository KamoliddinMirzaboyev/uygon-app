# Waky — Maxfiylik Siyosati (Privacy Policy)

**Oxirgi yangilanish:** 2026-yil 12-oktabr

Ushbu Maxfiylik Siyosati **"Waky"** (paket nomi: `uz.waky.app`) mobil ilovasidan foydalanishda foydalanuvchilarning maxfiyligi qanday ta'minlanishi haqida ma'lumot beradi.

---

### 1. Umumiy qoidalar va Ma'lumotlarni yig'maslik
"Waky" ilovasi foydalanuvchilarning shaxsiy daxlsizligini to'liq hurmat qiladi.
- **Ilova 100% oflayn ishlaydi.**
- Ilovada hech qanday internet ulanishi (`android.permission.INTERNET`) ishlatilmaydi.
- Foydalanuvchining shaxsiy ma'lumotlari, fotosuratlari, joylashuvi yoki kontaktlari serverlarga yuborilmaydi va uchinchi tomonlar bilan ulashilmaydi.
- Ilovada tashqi tahliliy (analytics) yoki reklama kuzatuv modullari mavjud emas.

---

### 2. Talab qilinadigan ruxsatnomalar va ulardan foydalanish maqsadi

Ilova faqat uning asosiy funksiyalari (budilnik va vazifalar) to'g'ri ishlashi uchun zarur bo'lgan minimal ruxsatnomalardan foydalanadi:

1. **Budilnik va Xabarnomalar (`USE_EXACT_ALARM`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `USE_FULL_SCREEN_INTENT`)**:
   - Budilnik belgilangan vaqtda aniq jiringlashi va ekran bloklangan holatda ham to'liq ekranda ko'rinishi uchun ishlatiladi.
2. **Kamera (`android.permission.CAMERA`)**:
   - Faqat budilnikni o'chirish uchun belgilangan **QR-kod yoki shtrix-kodni skanerlash** vazifasida ishlatiladi.
   - Kamera orqali olingan tasvirlar faqat qurilmaning o'zida bir zumda (oflayn ML Kit) tahlil qilinadi, hech qayerda saqlanmaydi va uzatilmaydi.
3. **Jismoniy faollik / Qadam o'lchagich (`android.permission.ACTIVITY_RECOGNITION`)**:
   - Budilnikni o'chirish uchun tanlangan **"Yurish vazifasi" (qadam sanash)** paytida foydalanuvchi belgilangan qadamlarni bajarganligini aniqlash uchun ishlatiladi.
4. **Vibratsiya va Uyqu rejimi (`VIBRATE`, `WAKE_LOCK`)**:
   - Budilnik jiringlagan vaqtda telefon tebranishi va ekranning yonishi uchun zarur.

---

### 3. Ma'lumotlarni saqlash
Budilnik vaqtlari, tanlangan ohanglar va foydalanuvchi sozlamalari faqat qurilmaning xotirasida (lokal SQLite / Hive omborida) shifrlangan holatda saqlanadi. Ilova o'chirilganda barcha mahalliy sozlamalar birgalikda o'chib ketadi.

---

### 4. Bolalar maxfiyligi (Children's Privacy)
Ilova har qanday yoshdagi foydalanuvchilar uchun xavfsiz bo'lib, bolalardan hech qanday shaxsiy ma'lumot to'plamaydi.

---

### 5. Bog'lanish
Ushbu Maxfiylik Siyosati bo'yicha savollaringiz bo'lsa, quyidagi manzil orqali bog'lanishingiz mumkin:
- **Email:** kamoliddinmirzaboyev2005@gmail.com
- **Dasturchi:** Kamoliddin Mirzaboyev

---

# Privacy Policy (English Version)

**Last updated:** October 12, 2026

This Privacy Policy applies to the **"Waky"** mobile application (package: `uz.waky.app`).

### 1. Information Collection and Use
- **100% Offline Application:** Waky operates completely offline. It does not require or utilize the Internet permission (`android.permission.INTERNET`).
- **No Data Collection:** We do not collect, store, transmit, or share any personal information, usage analytics, or telemetry.

### 2. Device Permissions
- **Alarm & Full Screen (`USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `POST_NOTIFICATIONS`)**: Essential for scheduling and displaying alarm alerts over the lock screen.
- **Camera (`android.permission.CAMERA`)**: Used solely for scanning user-selected QR codes or barcodes to dismiss alarms. Images are processed locally on-device and are never saved or transmitted.
- **Physical Activity (`android.permission.ACTIVITY_RECOGNITION`)**: Used strictly to count steps during the "Walk to wake up" challenge.

### 3. Contact
For questions or inquiries regarding this Privacy Policy, please contact:
- **Email:** kamoliddinmirzaboyev2005@gmail.com

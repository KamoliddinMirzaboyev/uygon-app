# 🚀 Google Play Console — Yuklash va Nashr Qilish Bo'yicha To'liq Qo'llanma

Loyihangiz Google Play Market talablariga 100% to'liq tayyorlandi. Quyida Google Play Console orqali ilovani birinchi marta muammosiz nashr qilish bo'yicha batafsil ko'rsatmalar keltirilgan.

---

## 📦 1. Tayyor Fayllar (Yuklash uchun)

| Fayl | Joylashuvi | Tavsifi |
| :--- | :--- | :--- |
| **Android App Bundle (.aab)** | `Waky-play-release.aab` *(Root papkada)* | Google Play uchun imzolangan va optimallashtirilgan asosiy fayl (~66 MB) |
| **Ilova belgisi (App Icon)** | `playstore/icon_512.png` | 512x512 px, 32-bit PNG |
| **Bosh banner (Feature Graphic)** | `playstore/feature_graphic_1024x500.png` | 1024x500 px, Google Play vitrinasi uchun rasmiy banner |
| **Maxfiylik Siyosati (HTML)** | `playstore/privacy_policy.html` | Google Play talab qiladigan Privacy Policy (veb-saytga yoki GitHub Pages'ga qo'yish uchun) |

---

## 🔑 2. Keystore (Imzolash kaliti) Ma'lumotlari

> [!CAUTION]
> **DIQQAT: Ushbu kalit va parollarni hech qachon yo'qotmang!** Google Play kelajakdagi har bir yangilanishda faqat shu kalit bilan imzolangan versiyalarni qabul qiladi.

- **Keystore fayli:** `/Users/kamoliddin/.uygon-keystore/upload-keystore.jks` (xavfsiz PKCS12 formati)
- **Konfiguratsiya fayli:** `android/key.properties` (GitHub'ga yuklanmaydi, `.gitignore`da)
- **Key Alias:** `upload`
- **Key & Store Password:** `PdMV9soIxYmCedpzZ7vfj65x`
- **Amal qilish muddati:** 2054-yilgacha (28 yil)

---

## 📝 3. Google Play Vitrina Matnlari (Store Listing)

### O'zbek tilida:

- **Ilova nomi (Title, max 30 belgi):**
  ```
  Uyg'on — Aqlli Budilnik
  ```

- **Qisqa tavsif (Short Description, max 80 belgi):**
  ```
  Masalalar va vazifalar bilan erta va oson uyg'otuvchi aqlli budilnik.
  ```

- **To'liq tavsif (Full Description, max 4000 belgi):**
  ```
  Uyg'on — tongda o'z vaqtida, tetik va kechikmasdan uyg'onishingizga yordam beruvchi eng ishonchli va aqlli budilnik!

  Oddiy budilnikni uyqusirab o'chirib qo'yib, yana uxlab qolishdan charchadingizmi? "Uyg'on" sizga to'liq uyg'onmaguningizcha signalni o'chirishga yo'l qo'ymaydigan qiziqarli va samarali vazifalarni taklif etadi.

  🌟 ASOSIY IMKONIYATLAR:

  🧠 1. Matematik Masalalar
  Miyangizni ishga tushirish uchun misollarni yeching: oson qo'shish-ayirishdan tortib murakkab arifmetikkacha (Oson, O'rta, Qiyin).

  📱 2. Telefonni Silkitish (Shake)
  Jismoniy harakat orqali tetiklaning: telefonni belgilangan marta (masalan, 30 marta) faol silkiting.

  ⌨️ 3. Matn Terish Vazifasi
  Ekranda ko'ringan ibratli va ilhomlantiruvchi jumlalarni xatosiz yozib chiqing.

  📷 4. QR-kod va Shtrix-kod
  Ilovani to'xtatish uchun yotoqxonadan chiqib, vannadagi tish pastasi yoki oshxonadagi choy qutisining kodini skanerlang!

  🚶 5. Yurish Vazifasi (Step Counter)
  Haqiqatan o'rningizdan turganingizga ishonch hosil qilish uchun ma'lum miqdordagi qadamlarni bosib o'ting.

  🎶 6. Keng Qamrovli Ohanglar
  Telefoningizdagi sevimli musiqalarni yoki ilovaning baland ovozli maxsus signallarini tanlang.

  ✨ INTERFEYS VA DIZAYN:
  • Nafis, minimalist va ko'zni charchatmaydigan qorong'u rejim (Dark theme).
  • Qulay va zamonaviy boshqaruv (iOS uslubidagi animatsiyalar).
  • 100% Oflayn va Xavfsiz — internet talab qilinmaydi, shaxsiy ma'lumotlar qurilmangizdan tashqariga chiqmaydi.

  Ertangi kuningizni "Uyg'on" bilan unumli va reja asosida boshlang!
  ```

---

### Rus tilida (Ixtiyoriy / Qo'shimcha til):

- **Название (Title):**
  ```
  Uyg'on — Умный Будильник
  ```

- **Краткое описание (Short Description):**
  ```
  Умный будильник с математическими задачами, шагами и QR-сканером.
  ```

---

## 🛡️ 4. Data Safety (Xavfsizlik deklaratsiyasi) Javoblari

Google Play Console'dagi "Data safety" bo'limida quyidagilarni belgilang:
1. **Does your app collect or share user data?** $\rightarrow$ **No** (Ilova hech qanday ma'lumot to'plamaydi va ulashmaydi).
2. **Permissions (Ruxsatnomalar):**
   - **Camera:** Faqat QR/shtrix-kodni oflayn skanerlash uchun (hech narsa saqlanmaydi).
   - **Physical Activity:** Yurish vazifasida qadamlarni faqat qurilmada sanash uchun.
   - **Notifications / Alarms:** Budilnik xabarnomasi uchun.

---

## 🎯 5. Content Rating (Yosh toifasi)
- So'rovnomada "Utility / Productivity / Clock" toifasini tanlang.
- Hech qanday zo'ravonlik, nojo'ya so'zlar yoki kontent yo'q deb belgilang.
- Natijada ilova **PEGI 3 / Everyone (Hamma uchun)** toifasini oladi.

---

## 🔄 Kelgusida yangi versiya chiqarish (Update qilish) tartibi

1. `pubspec.yaml` faylidagi versiyani oshiring:
   ```yaml
   version: 1.0.1+2  # (+1 dan +2 ga oshirish shart)
   ```
2. Yangi `.aab` faylni yig'ing:
   ```bash
   flutter build appbundle --flavor play --release
   ```
3. `build/app/outputs/bundle/playRelease/app-play-release.aab` faylini Google Play Console'dagi "Production" bo'limiga yuklang.

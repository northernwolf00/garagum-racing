<div align="center">

<img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.webp" alt="Garagum Racing" width="128" height="128" />

# 🏜️ Garagum Racing

**Türkmenistanyň çägeliklerinde hill-climb ýaryş oýny**

Gum gerişlerinden aşyp, teňňe ýygnap, ýangyjy tygşytlap — 4 dürli kartada 55 turdan geç!

<br/>

![Flutter](https://img.shields.io/badge/Flutter-3.38-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Flame](https://img.shields.io/badge/Flame_Engine-1.35-FF6B00?style=for-the-badge&logo=flame&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android_%7C_iOS-3DDC84?style=for-the-badge&logo=android&logoColor=white)

</div>

---

## 📖 Mazmun

- [Oýun barada](#-oýun-barada)
- [Aýratynlyklar](#-aýratynlyklar)
- [Kartalar](#️-kartalar)
- [Ulaglar](#-ulaglar)
- [Oýun mehanikasy](#-oýun-mehanikasy)
- [Monetizasiýa](#-monetizasiýa)
- [Tehnologiýalar](#-tehnologiýalar)
- [Proýektiň gurluşy](#-proýektiň-gurluşy)
- [Işläp başlamak](#-işläp-başlamak)
- [Reliz üçin sazlama](#-reliz-üçin-sazlama)

---

## 🎮 Oýun barada

**Garagum Racing** — Türkmenistanyň tebigatyndan ylham alnan 2D fizika-esasly hill-climb
ýaryş oýny. Oýunçy ulagyny gum gerişlerinden, gaýalardan we gaz kraterlerinden geçirip,
ýolda teňňe ýygnamaly hem ýangyjyny gutartman finişe ýetmeli.

Oýun **Flame** oýun-hereketlendirijisi we **Forge2D** fizika ulgamy bilen guruldy;
sesler üç gatlakly hakyky motor modeli bilen çalynýar.

---

## ✨ Aýratynlyklar

| | |
|---|---|
| 🏜️ **4 tematiki karta** | Garagum, Aşgabat, Ýaňňykala, Derweze — hersi öz görnüşi, päsgelçilikleri we sazy bilen |
| 🚙 **4 dürli ulag** | Buggy, UAZ, Pikap, Ak ulag — hersiniň motory, asmasy, tekerleri, ýangyç tanky başga |
| 🪙 **Teňňe ulgamy** | Ýolda teňňe ýygna, täze turlary aç, ulaglary satyn al |
| ⛽ **Ýangyç mehanikasy** | Ýangyjyňy tygşytla, ýoldaky bidonlary al — bak gutarsa oýun tamamlanýar |
| 🏁 **55 tur** | Kartalara bölünen, kynçylygy ýuwaş-ýuwaşdan artýan turlar |
| 🎵 **Dinamiki ses** | 3 gatlakly motor sesi (idle / mid / rev) tizlige görä garyşýar |
| 💰 **Monetizasiýa** | AdMob reklama + RevenueCat satyn alyşlar (aşakda serediň) |
| 💾 **Ýerli ýatda saklama** | Teňňe we üstünlik `SharedPreferences`-de saklanýar |

---

## 🗺️ Kartalar

| Karta | Beýany | Turlar |
|---|---|:---:|
| 🏜️ **Garagum çöli** | Giň çägelikler hem gum gerişleri, kanal köprüleri | 10 |
| 🏛️ **Aşgabat** | Ak mermer köçeler hem belent binalar | 15 |
| 🪨 **Ýaňňykala** | Dik gaýalar hem kanyon geçelgeleri | 15 |
| 🔥 **Derweze (Gaz krateri)** | Gije, alaw hem gapanak päsgelçilikler (faralar ýanýar) | 15 |

---

## 🚙 Ulaglar

| Ulag | Motor | Ýangyç tanky | Häsiýeti |
|---|:---:|:---:|---|
| 🏎️ **Buggy** | ★★☆☆☆ | ★★☆☆☆ | Ýeňil we çalt başlangyç ulag |
| 🚙 **UAZ** | ★★★☆☆ | ★★★★☆ | Deňagramly, uzak ýola ýangyçly |
| 🛻 **Pikap** | ★★★★☆ | ★★★★☆ | Güýçli motor, agyr ýerlere gowy |
| 🚗 **Ak ulag** | ★★★☆☆ | ★★★☆☆ | Şäher üçin çeýe ulag |

> Her ulagyň `engine`, `suspension`, `tires`, `fuel` görkezijileri oýnuň fizikasyna
> täsir edýär — `lib/models/vehicle_config.dart`.

---

## 🎯 Oýun mehanikasy

### Ýangyç ⛽
- Motor başdan ýangyç ýakýar; gaz/tormoz basylanda has köp.
- Ýangyç **25%**-e ýetende duýduryş berilýär we ýakynda bir bidon peýda bolýar.
- Bak doly gutarsa **"Ýangyç gutardy"** ekrany açylýar (reklama görüp dowam edip bolýar).

### Teňňe 🪙
- Ýolda teňňe ýygnalýar; her turuň öz **gerekli teňňe** çägi bar.
- Toplanan teňňe umumy balansa goşulýar (crash/finiş — parhy ýok, ýygnanan teňňe ýatda galýar).

### Turlar 🏁
- Finiş çyzygyna ýet **we** gerekli teňňäni topla → tur tamamlanýar we indiki açylýar.
- Her karta öz turlaryny aýratyn saklaýar.

---

## 💰 Monetizasiýa

Oýunda **AdMob** (reklama) we **RevenueCat** (satyn alyş/abuna) bilelikde işleýär.
Reklama syýasaty oýunçyny gaçyrmaz ýaly ätiýaçly gurnaldy.

### 📺 Reklama (AdMob)

| Görnüş | Nirede | Düzgün |
|---|---|---|
| 🎁 **Rewarded** — Dowam et | Ýangyç gutaranda | Reklama gör → bak dolýar (1 ýörişde 1 gezek) |
| 🎁 **Rewarded** — 2× teňňe | Netije ekranynda | Reklama gör → teňňäň iki esse (1 gezek) |
| 📺 **Interstitial** | Ýörişden soň menýu/turlara çykylanda | Ilkinji 5 ýöriş ýok, soň her 3-nji ýöriş |
| 🏷️ **Banner** | Diňe menýu we garaž | Oýnuň içinde hiç haçan |

### 🛒 Satyn alyşlar (RevenueCat)

| Entitlement | Näme berýär |
|---|---|
| `no_ads` | Banner + interstitial aýrylýar (**rewarded galýar**) |
| `unlock_all_maps` | Ähli kartalary açýar |
| `vip` | Reklamasyz + günlük teňňe + 2× teňňe + VIP reňkler |

> **Reklamasyz** oýunçylara-da rewarded düwmeleri galdyrylýar — olar öz islegi bilen basýar.
> Paywall dizaýny **RevenueCat Paywalls v2** arkaly dashboard-dan üýtgedip bolýar (koda degmän).

---

## 🛠️ Tehnologiýalar

| Gatlak | Ulanylýan |
|---|---|
| **Framework** | Flutter (Dart) |
| **Oýun hereketlendirijisi** | [Flame](https://flame-engine.org/) `1.35` |
| **Fizika** | Forge2D (`flame_forge2d`) |
| **Ses** | `flame_audio` (3 gatlakly motor modeli) |
| **Ýatda saklama** | `shared_preferences` |
| **Reklama** | `google_mobile_ads` |
| **Satyn alyş** | `purchases_flutter` + `purchases_ui_flutter` |

**State management:** ýönekeý `setState` + `ValueNotifier` (goşmaça paket ýok).
**Servisler:** `GameProgressService`, `PurchaseService`, `AdService` — singleton nagşynda,
`main()`-de bir gezek `init()` edilýär.

---

## 📁 Proýektiň gurluşy

```
lib/
├── main.dart                     # Başlangyç — servisleri init edýär
├── game/
│   ├── garagum_racing_game.dart  # Esasy Flame oýny (fizika, ýangyç, kamera)
│   ├── audio/audio_manager.dart  # 3 gatlakly motor sesi + SFX
│   ├── components/               # Ulag, teňňe, ýangyç bidony, päsgelçilik
│   └── world/                    # Ýer, köpri, parallaks fon, dekor (her karta)
├── models/
│   ├── map_theme.dart            # 4 karta enum
│   ├── round_config.dart         # 55 turuň sazlamalary
│   └── vehicle_config.dart       # 4 ulagyň görkezijileri
├── screens/
│   ├── menu/                     # Baş menýu + sazlamalar
│   ├── garage/                   # Garaž (ulag saýlamak)
│   ├── levels/                   # Tur saýlamak (her karta)
│   ├── race_screen.dart          # Ýaryş ekrany + overlaylar
│   └── game_over/                # Oýun gutardy ekrany
├── services/
│   ├── game_progress_service.dart# Teňňe + tur üstünligi (SharedPreferences)
│   ├── purchase_service.dart     # RevenueCat (entitlement, paywall)
│   └── ad_service.dart           # AdMob (banner/interstitial/rewarded)
└── widgets/
    └── ad_banner.dart            # Özüni dolandyrýan banner widjeti
```

---

## 🚀 Işläp başlamak

### Talaplar
- Flutter SDK `3.10+` (synag edilen: `3.38`)
- Android Studio / Xcode (enjam ýa emulator üçin)

### Gurnamak we işletmek

```bash
# Baglylyklary ýükle
flutter pub get

# Enjamda ýa emulatorda işlet
flutter run

# Reliz APK ýygna (Android)
flutter build apk --release
```

> ⚠️ **Bellik:** Reklama we satyn alyşlar diňe **hakyky Android/iOS enjamda** işleýär
> (web/desktopda däl). Häzir **test** ID-ler goýlan — "Test Ad" bolup görünýär.

---

## 🔑 Reliz üçin sazlama

Dükana çykarmazdan öň şu ýerlerdäki **test ID-lerini** hakyky bilen çalşyň:

| Faýl | Çalyşmaly |
|---|---|
| `lib/services/purchase_service.dart` | `_androidApiKey` / `_iosApiKey` → RevenueCat public key-ler |
| `lib/services/ad_service.dart` | Banner / interstitial / rewarded unit ID-leri |
| `android/app/src/main/AndroidManifest.xml` | AdMob **App ID** meta-data |
| `ios/Runner/Info.plist` | `GADApplicationIdentifier` + `SKAdNetworkItems` |

Soňra **RevenueCat dashboard**-da şu entitlement-leri we önümleri dörediň:
`no_ads`, `unlock_all_maps`, `vip` + teňňe paketleri (`coins_10000`, `coins_50000`, `coins_200000`).

---

<div align="center">

**Garagum Racing** 🏜️ — Türkmenistanyň çägeliklerinde ýarş!

<sub>Flutter · Flame · Forge2D bilen guruldy</sub>

</div>

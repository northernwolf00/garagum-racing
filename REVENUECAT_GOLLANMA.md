# RevenueCat sazlama gollanmasy — Garagum Racing

> Satyn alyşlary (IAP + abuna) işletmek üçin ädime-ädim. **Tertip möhüm** —
> RevenueCat store-dan (Play/App Store) maglumat okaýar, şoňa görä ilki store
> taýýar bolmaly.

## 0. Öňünden bilmeli zat ⚠️

RevenueCat özi töleg almaýar — ol **Google Play** we **App Store**-daky
önümleri dolandyrýar we tölegleri barlaýar. Şoňa görä şular zerur:

- **Google Play Console** — bir gezeklik **$25** (Android üçin)
- **Apple Developer** — ýylda **$99** (iOS üçin, diňe iOS-a çykarjak bolsaň)
- **Töleg kabul edýän hasap** (bank/salgy). ⚠️ Türkmenistanda Google Play /
  Apple developer hasaby açmak we töleg almak **çäklendirilen bolup biler** —
  ilki muny barla (köplenç daşary ýurt hasaby / kompaniýa gerek).

Diňe **Android**-dan başlamak has aňsat — aşakda şoňa görä.

---

## Koddaky takyk atlar (store-da DEŇ bolmaly)

Bu atlar `purchase_service.dart`-da hard코d edilen — store-da edil şu ID-ler
bilen döret:

| Önüm ID | Görnüş (Play/Apple) | Näme berýär |
|---|---|---|
| `coins_10000` | Consumable | 10 000 teňňe |
| `coins_50000` | Consumable | 50 000 teňňe |
| `coins_200000` | Consumable | 200 000 teňňe |
| `starter_pack` | Non-consumable | 25 000 + UAZ + 3 gün reklamasyz |
| `remove_ads` | Non-consumable | banner+interstitial ýok |
| `unlock_all_maps` | Non-consumable | ähli kartalar |
| `vip` | Subscription (auto-renew) | reklamasyz + günde 5000 + 2× |

**Entitlement-ler** (RevenueCat-da):

| Entitlement | Haýsy önümler bagly |
|---|---|
| `no_ads` | `remove_ads` + `vip` |
| `unlock_all_maps` | `unlock_all_maps` + `vip` |
| `vip` | `vip` |

---

## 1-nji BÖLÜM — Google Play Console (Android)

### 1.1 Hasap we app
1. https://play.google.com/console → **$25 töle**, developer hasaby aç.
2. **Create app** → ady (Garagum Racing), dili, mugt/tölegli → **Free**.

### 1.2 App-y iň az derejede taýýarla
Önümler işjeňleşmegi üçin app-yň **iň az bir build-i** synag trekine ýüklenen
bolmaly:
1. Kody build et:
   ```
   flutter build appbundle --release
   ```
2. Play Console → **Testing → Internal testing → Create release** → `.aab`
   faýly ýükle.
3. **Package name** (`com.googadev.garagum_racing`) — bu RevenueCat-a gerek
   bolar.

### 1.3 Önümleri döret
1. **Monetize → Products → In-app products** → şulary döret (Consumable):
   - `coins_10000`, `coins_50000`, `coins_200000`, `starter_pack`,
     `remove_ads`, `unlock_all_maps`
   - Her biri üçin baha goý (mysal: coins_10000 = $0.99).
   - ⚠️ ID edil ýokardaky ýaly bolmaly.
2. **Monetize → Subscriptions** → `vip` döret, **base plan** goş (aýlyk,
   auto-renew, $2.99).
3. Ählisini **Activate** et.

### 1.4 RevenueCat üçin rugsat (iň tehniki ädim)
RevenueCat Google-yň satyn alyşlaryny barlamak üçin **Service Account**
açary gerek:
1. Google Play Console → **Setup → API access**.
2. **Google Cloud project** dörediş/bagla.
3. **Service account** döret → JSON açar faýlyny ýükle.
4. Şol service account-a Play Console-da **"View financial data" +
   "Manage orders"** rugsadyny ber.
5. Bu JSON faýly soň RevenueCat-a ýüklärsiň.

> Bu ädim çylşyrymly — RevenueCat-yň resmi gollanmasy kömek edýär:
> https://www.revenuecat.com/docs/google-play-store

---

## 2-nji BÖLÜM — App Store Connect (iOS) — diňe iOS üçin

> iOS-a çykarmajak bolsaň, bu bölümi geç.

1. **Apple Developer** ($99/ýyl) → https://developer.apple.com
2. **App Store Connect** → app döret (bundle ID koddaky bilen deň).
3. **In-App Purchases** → consumable + non-consumable önümleri döret (edil
   ýokardaky ID-ler bilen).
4. **Subscriptions** → `vip` döret.
5. **Agreements, Tax, and Banking** → salgy/bank maglumatyny doldur (bolmasa
   önümler işlemeýär).
6. RevenueCat üçin **App Store Connect API key** (ýa shared secret) döret.

---

## 3-nji BÖLÜM — RevenueCat

1. https://app.revenuecat.com → hasap aç → **Create Project** ("Garagum
   Racing").
2. **Project settings → Apps → + New app**:
   - **Android:** package `com.googadev.garagum_racing` + 1.4-däki
     **service account JSON**-y ýükle.
   - **iOS:** bundle ID + App Store Connect açary.
3. **API keys** → şulary göçür:
   - Android: `goog_...`
   - iOS: `appl_...`
4. **Products** → store-dan önümleri import et / goş (ýokardaky 7 ID).
5. **Entitlements** → 3 sany döret we önümleri bagla:
   - `no_ads` ← `remove_ads`, `vip`
   - `unlock_all_maps` ← `unlock_all_maps`, `vip`
   - `vip` ← `vip`
6. **Offerings** → "default" offering döret, **Packages** goş (teňňe
   paketleri + starter + remove_ads + vip). Kod paketleri şu offering-den okaýar.
7. **Paywalls** → Paywalls v2 bilen dizaýn et (kod `presentPaywall()`
   çagyranda şu görüner).

---

## 4-nji BÖLÜM — Kod (iň aňsat ädim)

`lib/services/purchase_service.dart`-da diňe 2 setir:
```dart
static const String _androidApiKey = 'goog_SENIŇ_ACHARYN';
static const String _iosApiKey = 'appl_SENIŇ_ACHARYN';
```
Şu ýerde `goog_REPLACE_ME` / `appl_REPLACE_ME` ýerine hakyky açarlary goý.
Başga hiç zat üýtgetmeli däl — galan ähli logika taýýar.

---

## 5-nji BÖLÜM — Synag (sandbox)

- **Android:** Play Console → **License testing** → test hasaplaryny goş.
  Internal testing trekinden appy şol hasap bilen aç → hakyky pul tölemän
  satyn al.
- **iOS:** App Store Connect → **Sandbox testers** → sandbox hasap bilen synag.

Satyn alanyňdan soň barla:
- Teňňe goşuldymy (paketler)
- Banner ýitdimi (`remove_ads`)
- Paywall görünýärmi

---

## Gysga tertip (checklist)

- [ ] Google Play $25 hasap + app
- [ ] `.aab` build → internal testing
- [ ] 6 in-app önüm + `vip` subscription (dogry ID-ler)
- [ ] Service account JSON (RevenueCat üçin)
- [ ] RevenueCat project + app + API keys
- [ ] Entitlements + Offering + Paywall
- [ ] Açarlary koda goý (`purchase_service.dart`)
- [ ] Sandbox synag

> **Iň kyn ýerler:** service account (1.4) we store önümleriniň işjeňleşmegi
> (birnäçe sagat garaşmak). Galan zat aňsat.

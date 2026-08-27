# Garagum Racing — Ykdysadyýet hasaby (60 tur gurluşy)

> Bu faýl `BIZNES_MEYILNAMA_monetizasiya.md`-daky pelsepäni **60 tura** (4 karta × 15)
> görä täzeden hasaplanan anyk sanlar bilen üstüni ýetirýär. Sanlar ýörişme-ýöriş
> simulýasiýa bilen barlanan (içki-baglanyşykly).

## 0. Gurluş üýtgemesi

- Öňki: 10 / 15 / 15 / 15 = **55 tur** (deň däl)
- Täze: **15 / 15 / 15 / 15 = 60 tur** — Garagum kartasyna **+5 tur** goşulýar
- Teňňe akymy indi **60 tura yzygiderli ösýär** (öň her karta 43-den täzeden başlaýardy).
  Bu ösýän girdeji → uly derwezeler ahyrky kartalarda başarnykly duýulýar.

## 1. Üç ýol — barlanan wagt (60 tur)

| Ýol | Kim | Doly geçmek | Nirede direýär |
|---|---|---|---|
| **A — reklamasyz** | töleg/reklama ýok | ~92 gün | 3-nji karta (Ýaňňykala) derwezesinde |
| **B — reklama bilen** | 2× reklama görýän | **~49 gün** | ähli 60 tury geçýär (sagdyn F2P) |
| **C — töleg** | satyn alýan | 3–7 gün | derrew |

Reklama girdejini **~1,9×** köpeldýär. Işjeň oýunçy günde ~20 ýöriş (~30 min).

## 2. Bir ýörişde ýygnalýan teňňe (basgançak)

| Karta | Turlar (global) | Reklamasyz/ýöriş | 2× reklama bilen | Ýöriş wagty |
|---|---|---|---|---|
| Garagum | 1–15 | ~105–320 | ~200–615 | 60–90 sek |
| Aşgabat | 16–30 | ~325–385 | ~620–1050 | 90–120 sek |
| Ýaňňykala | 31–45 | ~570–860 | ~1080–1640 | 2–2,5 min |
| Derweze | 46–60 | ~880–1290 | ~1680–2450 | 2,5–3 min |

## 3. Derwezeler (gate) — 10 sany

Ilkinji **5 tur mugt** (onboarding). Soň 10 derweze; iň ulylary täze karta açýanlar.

| # | Tur (global) | Baha | Näme açylýar |
|---|:---:|---:|---|
| — | 1–5 | **MUGT** | oýunçy öwrenişýär |
| 1 | 6 | 600 | ilkinji kiçi bökdençlik |
| 2 | 11 | 3 500 | Garagum soňky bölegi |
| 3 | 16 | 12 000 | **Aşgabat kartasy** |
| 4 | 21 | 26 000 | Aşgabat 2-nji bölegi |
| 5 | 26 | 48 000 | Aşgabat soňky bölegi |
| 6 | 31 | 80 000 | **Ýaňňykala kartasy** |
| 7 | 36 | 120 000 | Ýaňňykala 2-nji bölegi |
| 8 | 41 | 165 000 | Ýaňňykala soňky bölegi |
| 9 | 46 | 230 000 | **Derweze kartasy** |
| 10 | 51 | 310 000 | Derweze 2-nji bölegi |
| — | 56–60 | free | tury gutaryp açylýar |
| | **Jemi** | **995 100** | |

> Her karta içinde derwezeleriň arasyndaky turlar öňküsini gutaryp **mugt** açylýar
> (häzirki logika). Diňe 10 nokatда teňňe soralýar → oýunçy gaharlanmaýar.

## 4. Ulaglar (güýç boýunça tertip)

Kod häzir 4 ulagy hem mugt (`unlockCost:0`) berýär. Täze bahalar (güýç boýunça):

| Ulag | Häsiýet (engine) | Baha |
|---|:---:|---:|
| **Buggy** | 0.35 (başlangyç) | **MUGT** |
| **UAZ** | 0.55 | 15 000 |
| **Ak ulag** | 0.60 | 40 000 |
| **Pikap** | 0.70 | 90 000 |
| | **Jemi** | **145 000** |

> Bellik: meýilnamada «UAZ mugt → Buggy 60k» diýilýär, ýöne kodda **Buggy iň gowşak**.
> Şonuň üçin güýç tertibine görä Buggy = başlangyç mugt ulag edildi.

## 5. Upgrade ulgamy

Her ulag üçin 4 görnüş × 5 dereje (6 basgançak, 0-njy = başlangyç):

| Upgrade | Derejeler | Bir ulag jemi |
|---|:---:|---:|
| Hereketlendiriji | 5 | ~24 000 |
| Amortizator | 5 | ~18 000 |
| Tigirler | 5 | ~16 000 |
| Ýangyç bagy | 5 | ~22 000 |
| **Bir ulag jemi** | | **~80 000** |

Oýunçy hakykatda ~1,5 ulagy doly kämilleşdirýär → **täsirli ~120 000 teňňe**.

## 6. Oýny doly geçmek — jemi teňňe

| Çeşme | Jemi |
|---|---:|
| Derwezeler | 995 100 |
| Ulaglar | 145 000 |
| Upgrade (real) | ~120 000 |
| **JEMI** | **~1 260 000 teňňe** |

## 7. Progressiýa nokatlary (B ýoly, barlanan)

| Ýetiş | Jemi ýöriş | ≈ Gün |
|---|:---:|:---:|
| Tur 5 (mugt zona gutarýar) | 8 | 0,4 |
| Tur 15 (Garagum doly) | 60 | 3,0 |
| Tur 30 (Aşgabat doly) | 268 | 13,4 |
| Tur 45 (Ýaňňykala doly) | 607 | 30,4 |
| Tur 60 (oýun doly) | 974 | **48,7** |

## 8. IAP paketleriniň gymmaty (B girdejisine görä)

| Önüm | Baha | Näçe güne barabar |
|---|---:|---|
| Starter pack | $1.99 | 25 000 teňňe + UAZ + 3 gün reklamasyz |
| Teňňe 10 000 | $0.99 | ~0,7 gün ösüş |
| Teňňe 50 000 | $3.99 | ~3,3 gün ösüş |
| Teňňe 200 000 | $9.99 | ~13 gün ösüş |
| `remove_ads` | $2.99 | banner+interstitial ýok (baýrakly galýar) |
| `unlock_all_maps` | $4.99 | 4 karta açyk (derwezeler галýar) |
| **Garagum VIP** | $2.99/aý | reklamasyz + günde 5 000 + 2× + VIP reňkler |

VIP: günde 5 000 + 2× → ~günde 20 000 teňňe → oýny ~30 günde geçýär (bir aýlyk abuna).

## 9. Her turuň teňňe sanlary (round_config üçin)

`totalCoins` (road) 60 tura yzygiderli ösýär, `requiredCoins` = ~55%.

### Garagum (1–15)
| tur | road | gerek | | tur | road | gerek |
|:-:|:-:|:-:|-|:-:|:-:|:-:|
| 1 | 140 | 77 | | 9 | 285 | 157 |
| 2 | 155 | 85 | | 10 | 310 | 170 |
| 3 | 170 | 94 | | 11 | 335 | 184 |
| 4 | 180 | 99 | | 12 | 360 | 198 |
| 5 | 195 | 107 | | 13 | 380 | 209 |
| 6 | 210 | 116 | | 14 | 405 | 223 |
| 7 | 235 | 129 | | 15 | 430 | 237 |
| 8 | 260 | 143 | | | | |

### Aşgabat (16–30, lokal 1–15)
| tur | road | gerek | | tur | road | gerek |
|:-:|:-:|:-:|-|:-:|:-:|:-:|
| 1 | 435 | 239 | | 9 | 605 | 333 |
| 2 | 455 | 250 | | 10 | 625 | 344 |
| 3 | 475 | 261 | | 11 | 645 | 355 |
| 4 | 500 | 275 | | 12 | 665 | 366 |
| 5 | 520 | 286 | | 13 | 690 | 380 |
| 6 | 540 | 297 | | 14 | 710 | 391 |
| 7 | 560 | 308 | | 15 | 730 | 402 |
| 8 | 580 | 319 | | | | |

### Ýaňňykala (31–45, lokal 1–15)
| tur | road | gerek | | tur | road | gerek |
|:-:|:-:|:-:|-|:-:|:-:|:-:|
| 1 | 760 | 418 | | 9 | 980 | 539 |
| 2 | 785 | 432 | | 10 | 1010 | 556 |
| 3 | 815 | 448 | | 11 | 1040 | 572 |
| 4 | 840 | 462 | | 12 | 1065 | 586 |
| 5 | 870 | 479 | | 13 | 1095 | 602 |
| 6 | 900 | 495 | | 14 | 1125 | 619 |
| 7 | 925 | 509 | | 15 | 1150 | 632 |
| 8 | 955 | 525 | | | | |

### Derweze (46–60, lokal 1–15)
| tur | road | gerek | | tur | road | gerek |
|:-:|:-:|:-:|-|:-:|:-:|:-:|
| 1 | 1180 | 649 | | 9 | 1490 | 820 |
| 2 | 1220 | 671 | | 10 | 1525 | 839 |
| 3 | 1255 | 690 | | 11 | 1565 | 861 |
| 4 | 1295 | 712 | | 12 | 1605 | 883 |
| 5 | 1335 | 734 | | 13 | 1640 | 902 |
| 6 | 1370 | 754 | | 14 | 1680 | 924 |
| 7 | 1410 | 776 | | 15 | 1720 | 946 |
| 8 | 1450 | 798 | | | | |

## 10. Ýyldyz baýragy (goşmaça teňňe çeşmesi) — KODA GEÇDI

| Ýyldyz | Şert | Bir gezeklik baýrak |
|---|---|---|
| ⭐ | tury gutar (finişe ýet) | — |
| ⭐⭐ | gerekli teňňäni ýygna (tury geç) | +5% road coin |
| ⭐⭐⭐ | road teňňäniň ≥90%-ini ýygna | +10% road coin (jemi +15%) |

> Bellik: meýilnamada ⭐⭐⭐ «agdarylman gutar» diýlipdi, ýöne oýunda agdarylma
> (flip) yzarlaýyş ýok. Şoňa görä ⭐⭐⭐ **teňňe-ussatlyk** (road-yň 90%-i) edildi —
> goşmaça fizika gerek däl, gaýtadan oýnamaga şonuň ýaly güýçli sebäp.

Baýrak diňe **iň gowy ýyldyz artanda** we bir gezek berilýär (gaýtalap oýnasaň
täzeden tölenmeýär). 3 ýyldyz → kontent 60 turdan effektiw ~150-ä uzalýar.

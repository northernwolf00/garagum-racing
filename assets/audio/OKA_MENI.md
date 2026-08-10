# Garagum Racing — ses toplumy (hemmesi ýörite sintez edildi)

Ähli faýllar 44.1 kHz, 16-bit. SFX — WAV (gijikmesi az), saz — OGG/MP3/WAV.
Awtorlyk hukugy meselesi ýok: hiç bir daşarky nusga ulanylmady.

---

## music/ — sazlar (loop edilýär, başy-soňy kesiksiz)

| Faýl | Dowamlylyk | Nirede |
|---|---|---|
| **menu_theme** | 38.4 s | Baş menýu, karta/dereje saýlaýyş ekrany |
| **garage_theme** | 25.3 s | Garaž — ýuwaş, giň, tüýdükli |
| **race_theme** | 29.1 s | Ýaryşyň dowamynda (islege görä) |

Üçüsi-de **D minor / frigiý** ladynda, türkmen öwüşginli: dutar (Karplus-Strong),
gyjak, tüýdük we **dep** (deprek) partiýasy: DUM · tek · DUM tek · tek.

> **Loop üçin OGG ulan.** MP3 formaty faýlyň başyna/soňuna boş kadr goşýar,
> şol sebäpli gaýtalananda kiçijik dyngy eşidilýär. OGG-de beýle mesele ýok.

---

## sfx/ — hereketlendirijiler (her ulag üçin aýry)

Fizika modeli bilen täzeden ýasaldy: **ýanma impulslary → egzoz/kuzow rezonatorlary
→ turbanyň comb öwüşgini → sorujy şowhun**. Silindrler biri-birinden az-kem
tapawutlanýar, şonuň üçin boş aýlawda hakyky "brmm-brmm" lüpüldisi eşidilýär.

Her ulagyň **5 faýly** bar:

```
engine_start_<ulag>.wav   otlanma: starter → tutuşma → idle-a düşmek (bir gezek)
engine_idle_<ulag>.wav    LOOP — boş aýlaw (820–1150 rpm), pes we lüpüldili
engine_mid_<ulag>.wav     LOOP — orta aýlaw (1950–4100 rpm)
engine_rev_<ulag>.wav     LOOP — ýokary aýlaw (3150–7000 rpm), ýiti
engine_blip_<ulag>.wav    gysga gaz urgusy: gaz → aýlawyň düşmegi → idle
```

| Ulag | Silindr / aýlaw | Sesiniň häsiýeti |
|---|---|---|
| **uaz** | 4 sil. benzin · 820 / 2300 / 3900 | gödek, pes, silindrleri deň işlemeýär, ýeňil takyrdyly |
| **ak_ulag** | 4 sil. benzin · 870 / 2700 / 4800 | arassa, ýumşak, sesi ýapyk (bogulan egzoz) |
| **pikap** | 4 sil. dizel · 740 / 1950 / 3150 | iň pes we agyr, güýçli mehaniki takyrdy |
| **buggy** | ýokary aýlawly · 1150 / 4100 / 7000 | gysga egzoz, hyžžyldyly we ýiti |

**Nähili birleşdirmeli (iň hakyky netije):**
üç loop-y hem bir wagtda goýber we gaz (throttle 0→1) boýunça göwrümlerini geçir:

| throttle | idle | mid | rev |
|---|---|---|---|
| 0.0 | 1.0 | 0 | 0 |
| 0.5 | 0 | 1.0 | 0 |
| 1.0 | 0 | 0 | 1.0 |

Aralykda çyzykly garyşdyr (mysal üçin throttle 0.25 → idle 0.5 / mid 0.5).
Goşmaça, tizlige görä üç loop-yň hem `playbackRate`-ini **0.85–1.5** aralygynda
üýtget — şonda aýlaw sanynyň üznüksiz üýtgeýşi duýulýar.
Ulag ýerden üzülende (böküşde) `rev`-e geçir, ýere düşende gysga wagtlyk `blip` goşup bolýar.

## sfx/ — oýun effektleri

| Faýl | Haçan |
|---|---|
| coin_pickup | teňňe alnanda |
| coin_bonus | uly teňňe / bonus |
| gem_pickup | göwher alnanda |
| fuel_low_warning | ýangyç azalanda (1.2 s, gaýtalap goýberilýär) |
| fuel_refill | ýangyç kanistri alnanda |
| out_of_fuel | ýangyç gutaryp motor öçende |
| gas_button_press | gaz düwmesine basylanda |
| button_tap | islendik UI düwmesi |
| button_select | dereje / karta / ulag saýlananda (tassyklaýjy) |
| button_back | yza gaýtmak |
| button_locked | gulplanan zada basylanda |
| crash | çaknyşyk / agdarylmak |
| bump | kiçi urgy |
| wheel_skid_loop | tigirler süýşende (loop) |
| ground_roll_loop | ýer üstünde tigirlemek (loop) |
| level_complete | dereje tamamlananda |
| game_over | oýun gutaranda |
| unlock_vehicle | täze ulag açylanda / satyn alnanda |

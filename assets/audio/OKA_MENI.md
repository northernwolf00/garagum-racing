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

Her ulagyň 3 faýly bar: **start** (bir gezek), **idle** we **rev** (ikisi-de loop).

| Ulag | Häsiýeti |
|---|---|
| **uaz** | köne benzin 4 silindr — gödek, pes, ýeňil takyrdyly |
| **ak_ulag** | döwrebap sedan — arassa, ýumşak, ýokary tonly |
| **pikap** | dizel — agyr, iň pes, güýçli takyrdy bilen |
| **buggy** | sport, ýokary aýlawly — hyžžyldyly, iň ýiti |

```
engine_start_<ulag>.wav     otlanma (starter → tutuşma → idle-a düşmek)
engine_idle_<ulag>.wav      2 s loop — maşyn duran ýerinde işläp durka
engine_rev_<ulag>.wav       2 s loop — gaza basylanda
engine_throttle_blip.wav    gysga gaz urgusy (islendik ulaga goşup bolýar)
```

**Nädip ulanmaly:** `engine_idle` bilen `engine_rev` ikisini-de bir wagtda loop-da
goýber, gaz (throttle 0→1) boýunça göwrümlerini çalyş: idle = 1−throttle, rev = throttle.
Goşmaça, tizlige görä `playbackRate`-i 0.85–1.6 aralygynda üýtget — şonda RPM duýulýar.

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

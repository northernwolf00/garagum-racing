# Garagum Racing — assetler v2 (Hill Climb Racing stilinde)

Ähli faýllar PNG, aç-açan fonly. Stil: galyň gara konturly (flat cartoon),
Garagum çölüniň reňkleri + türkmen haly nagyşlary.

## vehicles/ — üsti açyk ulag + milli lybasly sürüji
| Faýl | Ölçeg | Bellik |
|---|---|---|
| car_body.png | 1024x512 | üsti açyk kuzow: oturgyç, rul, roll-bar, ätiýaç tigir, antennadaky milli baýdakjyk, ýan tarapynda haly nagşy |
| car_wheel.png | 256x256 | off-road tigir, merkezinde haly güli — aýlanma üçin merkezi doly ortada |
| driver_body.png | 320x320 | gyzyl **don**, altyn guşak, ýakada krem nagyş, gollar rulda |
| driver_head.png | 320x320 | gara **telpek**, sakgal — aýry faýl (böküşde titretmek üçin) |
| car_preview.png | — | diňe görkezmek üçin |

**Ýerleşdiriş (car_body.png 1024x512 ölçeginde):**
- öň tigir merkezi: x=252, y=400 · yz tigir merkezi: x=772, y=400 · tigir radiusy ≈ 115
- driver_body merkezi ≈ x=512, y=170 (masştab ~0.62 · kuzowa görä)
- driver_head driver_body-niň üstünde ≈ 28px ýokarda

## terrain/
- **terrain_fill.png** (512x512) — ýeriň içi, 4 tarapa seamless
- **terrain_top.png** (512x128) — ýer üsti: açyk çäge gatlagy + guran çöl oty (selin), gorizontal seamless
- **canal_water.png** (512x256) — Garagum kanalynyň suwy, gorizontal seamless
- **deco_gamys.png** — kanal kenaryndaky gamyş

## bridge/ — Garagum kanalyndan geçýän köpri
- **bridge_deck.png** (512x128) — üst plita, gorizontal gaýtalanýar
- **bridge_railing.png** (512x128) — germew + X-baglaýjylar, arasy aç-açan
- **bridge_pillar.png** (160x512) — suwuň içindäki sütün
- **bridge_ramp_left.png** (256x160) — girelge pandusy (sag tarap üçin flipX)
- **bridge_gate.png** (512x384) — milli nagyşly derweze arkasy

## obstacles/ — pasgelçilikler
rock_big, rock_small, sand_ramp (tramplin), sand_mound (gum depejigi),
log_sazak (sazak köki), barrel (nagyşly bochka), tyre_stack, crate, signpost

## ui/
| Faýl | Bellik |
|---|---|
| pedal_gas / pedal_gas_pressed | "GAZ" pedaly (256x360), basylanda gyşarýan görnüşi |
| pedal_brake / pedal_brake_pressed | "TORMOZ" pedaly |
| gauge_rpm, gauge_boost | sifirblat (256x256) |
| gauge_needle | dil — **pivot nokady: çep gyrasyndaky tegelek (x=64,y=64 · 256x128 ölçegde)**, şony gauge-yň merkezine goý we rotate et |
| btn_boost | boost topy |
| fuel_bar_bg + fuel_bar_fill | ýangyç zolagy (fill-i ini boýunça kesip doldur) |
| icon_fuel, coin, gem, btn_pause | HUD |

## Öňi-görnüşler
- _preview_scene.png — köpri, kanal, pasgelçilikler we HUD bilelikde
- _preview_all_assets.png — ähli assetleriň sanawy

# Ýaňňykala kartasy + Pikap — surat assetleri

Gorizontal gatlakly gaýalar (ak-krem → sary → mämişi → gyzyl → goýy gyzyl),
dik gyralar, dar geçelgeler. Böküşiň uzynlygyna gönükdirilen karta.

## vehicles/ — Pikap
| Faýl | Ölçeg | Bellik |
|---|---|---|
| pikap_body.png | 1024x520 | hakyky görnüşli goşa kabinaly pikap: radiator paneli, burçly fara, duman çyrasy, gara plastik tigir gyralary (flare), basgançak, ýangyç gapagy, antenna — nagyşsyz |
| pikap_wheel.png | 256x256 | hakyky legirlenen disk: 5 goşa spisa, 6 bolt, kümüş göbek |
| dust_particle.png | 128x128 | tozan bölejigi |
| pikap_preview.png | — | görkezmek üçin |

Tigir merkezleri (1024x520 ölçegde): öň x=252 y=400, yz x=772 y=400, radius ≈ 112.
Öňki kartalaryň ulaglary bilen **birmeňzeş rig**.

## parallax/ (2048 giň, gorizontal seamless)
| Faýl | Tizlik |
|---|---|
| yangykala_sky.png (2048x768) | 0.05 |
| mesa_far.png (2048x460) — dumanly, tekiz depeli gaýalar | 0.15 |
| mesa_mid.png (2048x440) | 0.30 |
| mesa_near.png (2048x400) — doly reňkli gatlaklar | 0.55 |

## terrain/
- **rock_layers_fill.png** (512x512) — gorizontal gatlakly gaýa, gorizontal seamless
- **rock_top.png** (512x128) — ýeriň gaty gabygy + çöl oty
- **gravel_track.png** (512x96) — çagylly ýol

## cliffs/ — dik gyralar we geçelgeler
| Faýl | Näme |
|---|---|
| cliff_wall_left / cliff_wall_right (320x640) | dik diwar — **dikligine gaýtalanýar**, islendik beýiklikde ýygnalýar |
| narrow_gate.png (520x520) | dar geçelge — iki diwar ýüzbe-ýüz |
| rock_pillar.png (220x640) | aýry duran sütün-gaýa |
| rock_arch.png (400x470) | tebigy arka (aşagyndan geçilýär) |
| jump_ramp.png (340x264) | böküş tramplini — gaýanyň gyrasy |
| ledge_platform.png (440x240) | böküşden soň düşülýän tekiz meýdança |

**Böküş gurluşy:** jump_ramp → jayryk (boşluk) → ledge_platform.
Aralygy uzaltmak üçin jayryk-yň giňligini üýtgetmek ýeterlik.

## obstacles/
cukur (ýoldaky çukur) · jayryk (böküş boşlugy) · gaya_uly · gaya_kici ·
opurylan_gaya (opurylan gaýa üýşmegi) · gum_depejik · agac_koki · bochka ·
tigir_uysmegi · aralyk_baydajyk (böküş uzynlygyny bellemek üçin) · yol_belgi

## props/ — çöl durmuşy
ak_oy · gara_oy · duye · duye_yatan · goyun · goyun_suri · copan_it ·
sazak · ojak_gazan · guyy
(Derweze kartasy bilen umumy — stil we ölçeg birmeňzeş)

## Öňi-görnüşler
_preview_scene.png · _preview_all_assets.png

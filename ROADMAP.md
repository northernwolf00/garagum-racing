# Garagum Racing — Roadmap

Physics-based Hill Climb Racing clone with a Turkmen theme. Flat-silhouette
art direction, procedural terrain, Forge2D vehicle physics.

## Status

- [x] Phase 1 — Prototype: Forge2D world, procedural dune terrain
      (`lib/game/world/terrain.dart`), boxy physics car with two
      motorised wheel joints (`lib/game/components/car.dart`), gas/brake
      pedal HUD (`lib/game/input/pedal_button.dart`,
      `lib/screens/race_screen.dart`). No sprites/audio/menus yet.
- [ ] Phase 2 — Physics tuning
- [ ] Phase 3 — Core loop
- [ ] Phase 4 — Art + audio
- [ ] Phase 5 — Meta game
- [ ] Phase 6 — Monetization
- [ ] Phase 7 — Polish + release

## Tech stack

```yaml
dependencies:
  flame: ^1.35            # engine
  flame_forge2d: ^0.19    # Box2D physics: car, wheels, terrain
  flame_audio:             # engine sound, coin sfx — Phase 4
  flame_bloc: / riverpod    # UI state — Phase 5
  hive_ce:                  # save data (coins, upgrades, unlocked maps)
  purchases_flutter:        # RevenueCat — Phase 6
  google_mobile_ads:        # ads — Phase 6
```

Vehicle rig (Forge2D):
- Chassis = single `PolygonShape` dynamic body
- 2 wheels = `CircleShape` dynamic bodies, each attached to the chassis
  with a `RevoluteJoint` (motor enabled)
- Gas/brake = `joint.setMotorSpeed(...)`, `maxMotorTorque` caps torque
- Terrain = `ChainShape` built from a generated point list
- Flipping/rolling comes for free from the physics — no scripted logic

Terrain height function (rolling dunes, matches reference art):
`sin(x*0.09)*3 + sin(x*0.03)*6 + sin(x*0.005+1.7)*2.5`

## Phase plan

| Phase | Scope | Est. |
|---|---|---|
| 1. Prototype | Forge2D world, flat ground, cube car, gas/brake. No art. | 1 wk |
| 2. Physics tuning | Wheel friction, suspension feel, flip/rollover, smooth camera follow, procedural terrain | 1–2 wk |
| 3. Core loop | Fuel system, coin pickups, run-over conditions (out of fuel / head hits ground), distance counter | 1 wk |
| 4. Art + audio | Reference art style: 3–4 layer parallax, car sprites, dust particles, engine sound | 2 wk |
| 5. Meta game | Garage, 4 upgrade categories, map unlocks, leaderboard | 2 wk |
| 6. Monetization | RevenueCat + AdMob integration, remote config | 1 wk |
| 7. Polish + release | Onboarding, settings, TM/RU/EN localization, store assets, QA | 2 wk |

Total: ~8–10 weeks solo, 2–3 hrs/day.

## Maps (national theme, unlock order)

1. **Garagum** — starter, gentle dunes (free)
2. **Ýaňňykala** — steep cliffs, narrow paths
3. **Derweze (gas crater)** — night, fire glow, balloon physics props
4. **Köpetdag** — steep climbs, icy/slippery ground
5. **Hazar kenary (Caspian coast)** — soft sand, wheels sink
6. **Köwata cave** — covered ceiling, stalactite obstacles
7. **Aşgabat at night** — city, curbs and stairs
8. **Silk Road ruins** — old walls, jump ramps
9. **Icy pass** — most slippery map
10. **Moon surface** (bonus) — low gravity, long jumps

Per map: unlock cost (coins), fuel-canister density, ground "roughness" param.

**Vehicles (8–10):** Tractor → UAZ → Pickup → Buggy → Motorcycle → Monster
Truck → Truck → Tank → Rocket sled.

**Upgrades (4 per vehicle):** Engine · Suspension · Tires · Fuel tank.

## Monetization (RevenueCat)

Non-consumable:
- `remove_ads` — $2.99 — removes banner + interstitial (rewarded ads stay)
- `unlock_all_maps` — $4.99

Consumable:
- Coin packs: 10k / 50k / 200k — $0.99 / $3.99 / $9.99
- `starter_pack` — $1.99, first-24h only, one-time: coins + car + 3 days no ads

Subscription:
- **Garagum VIP** — $2.99/mo — no ads + 5000 coins/day + 2x coin multiplier
  + VIP car colors

Integration points:
```dart
await Purchases.configure(PurchasesConfiguration(apiKey));
final info = await Purchases.getCustomerInfo();
final isVip = info.entitlements.active.containsKey('vip');
final noAds = info.entitlements.active.containsKey('no_ads');
```
Paywall triggers: not enough coins in garage, selecting a locked map,
"remove ads" in settings, once after the 3rd death (soft prompt).

Consider RevenueCat Paywalls v2 (dashboard-editable paywalls, no app
update needed for price/copy tests).

## Ads

Rewarded (primary revenue, player-friendly):
- "Out of fuel → continue" — once per run, highest-value placement
- "2x your coins" — on the results screen
- Daily free chest — every 4h
- "Try this premium car for one run"
- "50% off next upgrade" — once per day

Interstitial:
- Only every 3rd run, after closing the results screen
- Never mid-run
- Never in the first 5 runs (let the player learn the game first)

Banner:
- Main menu and garage screens only
- Never during gameplay

Rule: players who bought `remove_ads` never see banner/interstitial, but
keep rewarded-ad buttons available — those are opt-in and still earn
revenue.

## Notes

- RevenueCat Shipaton runs Aug–Sep. If phases 1–5 land during August,
  this project could be submitted in September.

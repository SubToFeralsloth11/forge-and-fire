# Forge & Fire

A gun-building sandbox for Godot 4.7, in the spirit of Trailmakers. Put a gun together from parts in the workshop, then take it to a proving ground. There you can shoot paper, steel out to 1,500 m, dummies, armour plates, ballistic gel and a destruction yard. Every mesh, sound and texture is generated in code, so the project has no asset files and runs as soon as you open it.

All lengths are in centimetres and metres.

## Run

Open the folder in Godot 4.7 and press Play, or run `godot --path .`

## Workshop

- **Platform (18):** striker pistol, 1911-style hammer pistol, magnum revolver, machine pistol, roller-delayed SMG, compact PDW, direct-impingement rifle, long-stroke piston rifle, battle rifle, bullpup, belt-fed LMG, bolt action, anti-materiel rifle, pump shotgun, box-fed auto shotgun, double-barrel, lever action, revolving 40 mm grenade launcher.
- **Calibres (21):** 9x19, .45 ACP, 10mm, 5.7x28, .357, .44 Mag, .500 S&W, 5.56, 5.45, .300 BLK, 7.62x39, 7.62x51, 6.5 CM, .30-06, .300 WM, .338 LM, .30-30, .45-70, .50 BMG, 12 ga, 40 mm.
- **Loads:** FMJ, hollow point, AP, match, tracer, subsonic, +P, API. For 12 gauge: 00 buck, #4 buck, birdshot, slug, flechette, dragon's breath. For 40 mm: HE, HEDP, smoke.
- **Parts (about 150):** barrels (seven rifle profiles plus pistol, revolver, shotgun and launcher barrels), muzzle devices (flash hiders, brakes, comps, five suppressors, chokes), handguards (rail lengths adjust in cm), stocks (collapsible, precision, folders, wood hunting stocks, chassis), grips, magazines (10 rounds up to 100-round drums, tubes, belts), optics (irons, red dots, holo, prism, 4x, LPVO 1-6x, 3-9x, 10x, 5-25x), underbarrel parts (grips, bipod, 40 mm launcher, shotgun, light), lasers and lights, and trigger groups.
- **Finishes (31):** cerakote colours, anodised and stainless metal, gold, chrome, four woods, camo patterns, carbon fibre and Damascus.
- Click a slot in the list or a blue dot on the gun. Hover over a part to see how it changes every stat, shown in green or red. Barrel length is a slider in cm.
- The stats come from physics. Muzzle velocity follows the barrel length you set (fitted to chronograph data). Recoil is free-recoil energy from bullet and powder momentum against the gun's weight, reduced by brakes, stocks and grips. Penetration, effective range and a drop table at 100/300/500/1000 m come from a drag model.
- **Controls:** Ctrl+Z / Ctrl+Y undo and redo. Right-drag orbits the camera and the wheel zooms. Enter goes to TEST FIRE. Save keeps the design under My Designs; **Surprise me** builds a random gun.

## Proving ground controls

| Input | Action |
|---|---|
| WASD / Shift / Space | Move / sprint / jump |
| C / Z | Crouch / prone (a bipod deploys when crouched or prone) |
| Mouse, LMB, RMB | Look, fire, aim down sights |
| Shift while aiming | Hold your breath to steady the scope (about 6 s) |
| R | Reload, or clear a jam |
| B | Fire mode (semi / burst / auto, depending on the trigger group) |
| T | Scope zoom step / flip the magnifier |
| PgUp/PgDn or wheel while aiming | Zero distance (scopes up to 1,500 m) |
| G / L / V | Underbarrel launcher or shotgun / weapon light / inspect |
| E | Start the timed drill (stand at the red post) |
| N / Shift+N | Next / previous preset or saved design |
| F5, Tab, Esc, H | Reset targets, back to the workshop, menu, hide help |

## Ballistics

- Bullets are simulated as point masses with quadratic drag, gravity and wind at 240 Hz. The zero is solved for the sight height of your optic.
- Scope reticles are drawn in true milliradians at every zoom, so holdovers work. A laser rangefinder readout shows while you are scoped.
- Bullets penetrate by material and thickness (steel, armour, concrete, wood, glass, gel, sheet metal on the car). They ricochet at grazing angles. The plate rack shows the steel thickness a round could defeat and what it needed.
- Each hit reports distance, impact velocity, energy, drop below the line of sight and time of flight.
- Barrels heat up and groups open; heavy profiles and vented handguards resist this. Jams are rarer on piston guns and more common with drums and suppressors.

## Developer checks

```sh
godot --headless --path . -- --check      # assemble and rate every preset and 108 random builds
godot --headless --path . -- --simtest    # fire every preset at steel, reload, cycle actions, plate and grenade tests
godot --path . -- --shots                 # screenshots into tools/out/
```

class_name Cal
extends RefCounted
## Cartridge and load data. Velocities follow v(L) = vmax * (1 - exp(-L / tau))
## with L the barrel length in centimetres, fitted to published chronograph numbers.
##
## Fields: name, cls (pistol/intermediate/full/magnum/amr/shotgun/grenade), g (bullet
## grams), d (bullet diameter mm), vmax (m/s), tau (cm), cd (drag coefficient),
## cl (cartridge length mm), cw (case head diameter mm), taper (magazine curve),
## pw (powder grams), pen (mm mild steel at 800 m/s-equivalent energy reference),
## pellets (shot count), hull (casing look: brass/steel/hull/none).
const DATA := {
	"9mm": {"name": "9x19mm Parabellum", "cls": "pistol", "g": 7.45, "d": 9.0, "vmax": 432.0, "tau": 6.6, "cd": 0.4, "cl": 29.7, "cw": 9.9, "taper": 0.15, "pw": 0.4, "pen": 3.0, "hull": "brass"},
	"45acp": {"name": ".45 ACP", "cls": "pistol", "g": 14.9, "d": 11.5, "vmax": 300.0, "tau": 5.6, "cd": 0.45, "cl": 32.4, "cw": 12.2, "taper": 0.0, "pw": 0.33, "pen": 2.5, "hull": "brass"},
	"10mm": {"name": "10mm Auto", "cls": "pistol", "g": 11.7, "d": 10.2, "vmax": 420.0, "tau": 6.6, "cd": 0.42, "cl": 32.0, "cw": 10.8, "taper": 0.0, "pw": 0.55, "pen": 3.5, "hull": "brass"},
	"57": {"name": "5.7x28mm", "cls": "pistol", "g": 2.0, "d": 5.7, "vmax": 800.0, "tau": 10.2, "cd": 0.3, "cl": 40.5, "cw": 7.9, "taper": 0.1, "pw": 0.4, "pen": 6.0, "hull": "brass"},
	"357": {"name": ".357 Magnum", "cls": "magnum", "g": 10.2, "d": 9.1, "vmax": 560.0, "tau": 8.9, "cd": 0.42, "cl": 40.0, "cw": 11.2, "taper": 0.0, "pw": 1.0, "pen": 4.0, "hull": "brass"},
	"44mag": {"name": ".44 Magnum", "cls": "magnum", "g": 15.6, "d": 10.9, "vmax": 600.0, "tau": 10.2, "cd": 0.45, "cl": 40.9, "cw": 13.1, "taper": 0.0, "pw": 1.4, "pen": 5.0, "hull": "brass"},
	"500sw": {"name": ".500 S&W Magnum", "cls": "magnum", "g": 22.7, "d": 12.7, "vmax": 700.0, "tau": 12.7, "cd": 0.45, "cl": 57.0, "cw": 13.9, "taper": 0.0, "pw": 2.6, "pen": 7.0, "hull": "brass"},
	"556": {"name": "5.56x45mm NATO", "cls": "intermediate", "g": 4.0, "d": 5.7, "vmax": 955.0, "tau": 15.2, "cd": 0.29, "cl": 57.4, "cw": 9.6, "taper": 0.25, "pw": 1.62, "pen": 9.0, "hull": "brass"},
	"545": {"name": "5.45x39mm", "cls": "intermediate", "g": 3.4, "d": 5.6, "vmax": 960.0, "tau": 16.5, "cd": 0.28, "cl": 57.0, "cw": 10.0, "taper": 0.35, "pw": 1.45, "pen": 9.0, "hull": "steel"},
	"300blk": {"name": ".300 Blackout", "cls": "intermediate", "g": 8.1, "d": 7.82, "vmax": 720.0, "tau": 11.4, "cd": 0.32, "cl": 57.0, "cw": 9.6, "taper": 0.25, "pw": 1.2, "pen": 6.0, "hull": "brass"},
	"762x39": {"name": "7.62x39mm", "cls": "intermediate", "g": 7.9, "d": 7.9, "vmax": 770.0, "tau": 12.7, "cd": 0.33, "cl": 56.0, "cw": 11.3, "taper": 0.9, "pw": 1.6, "pen": 7.0, "hull": "steel"},
	"762x51": {"name": "7.62x51mm NATO", "cls": "full", "g": 9.5, "d": 7.82, "vmax": 900.0, "tau": 17.8, "cd": 0.28, "cl": 71.0, "cw": 11.9, "taper": 0.12, "pw": 2.9, "pen": 9.5, "hull": "brass"},
	"65cm": {"name": "6.5 Creedmoor", "cls": "full", "g": 9.1, "d": 6.7, "vmax": 900.0, "tau": 20.3, "cd": 0.24, "cl": 71.8, "cw": 11.9, "taper": 0.12, "pw": 2.7, "pen": 9.0, "hull": "brass"},
	"3006": {"name": ".30-06 Springfield", "cls": "full", "g": 11.7, "d": 7.82, "vmax": 900.0, "tau": 20.3, "cd": 0.28, "cl": 84.8, "cw": 11.9, "taper": 0.12, "pw": 3.6, "pen": 10.0, "hull": "brass"},
	"300wm": {"name": ".300 Winchester Magnum", "cls": "magnum_rifle", "g": 12.3, "d": 7.82, "vmax": 950.0, "tau": 22.9, "cd": 0.25, "cl": 84.8, "cw": 13.0, "taper": 0.1, "pw": 4.8, "pen": 12.0, "hull": "brass"},
	"338lm": {"name": ".338 Lapua Magnum", "cls": "magnum_rifle", "g": 16.2, "d": 8.6, "vmax": 950.0, "tau": 22.9, "cd": 0.24, "cl": 93.5, "cw": 14.9, "taper": 0.1, "pw": 6.0, "pen": 14.0, "hull": "brass"},
	"3030": {"name": ".30-30 Winchester", "cls": "full", "g": 9.7, "d": 7.82, "vmax": 760.0, "tau": 17.8, "cd": 0.4, "cl": 64.8, "cw": 12.9, "taper": 0.0, "pw": 2.0, "pen": 7.0, "hull": "brass"},
	"4570": {"name": ".45-70 Government", "cls": "full", "g": 26.2, "d": 11.6, "vmax": 520.0, "tau": 15.2, "cd": 0.45, "cl": 64.8, "cw": 15.5, "taper": 0.0, "pw": 3.6, "pen": 6.0, "hull": "brass"},
	"50bmg": {"name": ".50 BMG", "cls": "amr", "g": 42.0, "d": 12.95, "vmax": 960.0, "tau": 30.5, "cd": 0.26, "cl": 138.0, "cw": 20.4, "taper": 0.1, "pw": 15.0, "pen": 22.0, "hull": "brass"},
	"12ga": {"name": "12 Gauge 2-3/4\"", "cls": "shotgun", "g": 3.5, "d": 8.4, "vmax": 430.0, "tau": 15.2, "cd": 0.47, "cl": 70.0, "cw": 20.0, "taper": 0.0, "pw": 2.0, "pen": 2.0, "pellets": 9, "hull": "hull"},
	"40mm": {"name": "40x46mm Grenade", "cls": "grenade", "g": 230.0, "d": 40.0, "vmax": 78.0, "tau": 7.6, "cd": 0.35, "cl": 99.0, "cw": 44.0, "taper": 0.0, "pw": 0.4, "pen": 1.0, "hull": "none", "explosive": 5.0},
}

## Ammunition loads. Multipliers apply to the cartridge's base numbers.
## v: velocity, g: bullet mass, pen: penetration, dmg: tissue damage,
## moa: group size, cd: drag, tracer, subsonic cap, recoil.
const AMMO := {
	"fmj": {"name": "FMJ Ball", "for": ["pistol", "magnum", "intermediate", "full", "magnum_rifle", "amr"]},
	"hp": {"name": "Hollow Point", "for": ["pistol", "magnum", "intermediate", "full", "magnum_rifle"], "pen": 0.55, "dmg": 1.3, "cd": 1.05},
	"ap": {"name": "Armor Piercing", "for": ["pistol", "intermediate", "full", "magnum_rifle", "amr"], "pen": 1.8, "dmg": 0.92, "v": 1.02},
	"match": {"name": "Match OTM", "for": ["intermediate", "full", "magnum_rifle", "amr", "magnum"], "moa": 0.55, "cd": 0.88, "g": 1.08, "v": 0.98},
	"tracer": {"name": "Tracer", "for": ["pistol", "intermediate", "full", "magnum_rifle", "amr"], "tracer": true, "pen": 0.9},
	"subsonic": {"name": "Subsonic Heavy", "for": ["pistol", "intermediate", "full"], "sub": 315.0, "g": 1.45, "dmg": 0.9},
	"plusp": {"name": "+P Hot Load", "for": ["pistol", "magnum"], "v": 1.08, "recoil": 1.2, "dmg": 1.1},
	"api": {"name": "API (Incendiary)", "for": ["amr", "magnum_rifle"], "pen": 1.6, "dmg": 1.15, "tracer": true, "incendiary": true},
	"buck": {"name": "00 Buckshot", "for": ["shotgun"]},
	"buck4": {"name": "#4 Buckshot", "for": ["shotgun"], "pellets": 27, "g": 0.4, "d": 0.75, "dmg": 0.6},
	"bird": {"name": "Birdshot #7.5", "for": ["shotgun"], "pellets": 40, "g": 0.023, "d": 0.29, "dmg": 0.18, "v": 0.93},
	"slug": {"name": "Rifled Slug", "for": ["shotgun"], "pellets": 1, "g": 8.0, "d": 2.2, "v": 1.05, "pen": 2.5, "dmg": 1.0},
	"flechette": {"name": "Flechette", "for": ["shotgun"], "pellets": 20, "g": 0.2, "d": 0.3, "pen": 2.2, "cd": 0.5, "dmg": 0.55},
	"dragon": {"name": "Dragon's Breath", "for": ["shotgun"], "pellets": 14, "g": 0.25, "d": 0.6, "dmg": 0.35, "tracer": true, "incendiary": true, "v": 0.8},
	"he": {"name": "HE Grenade", "for": ["grenade"]},
	"hedp": {"name": "HEDP", "for": ["grenade"], "pen": 50.0, "dmg": 1.1},
	"smoke": {"name": "Smoke", "for": ["grenade"], "smoke": true, "dmg": 0.0},
}


static func get_cal(id: String) -> Dictionary:
	return DATA.get(id, DATA["556"])


static func ammo_for(cal_id: String) -> Array:
	var cls: String = get_cal(cal_id).cls
	var out := []
	for k in AMMO:
		if cls in AMMO[k]["for"]:
			out.append(k)
	return out


## Resolves the projectile a cartridge + load + barrel length produces.
static func projectile(cal_id: String, ammo_id: String, barrel_cm: float) -> Dictionary:
	var c := get_cal(cal_id)
	var a: Dictionary = AMMO.get(ammo_id, {})
	var v: float = c.vmax * (1.0 - exp(-maxf(barrel_cm, 1.0) / c.tau)) * a.get("v", 1.0)
	var g: float = c.g * a.get("g", 1.0)
	if a.has("sub"):
		v = minf(v, a.sub)
	var d_mm: float = c.d * a.get("d", 1.0)
	var pellets: int = a.get("pellets", c.get("pellets", 1))
	return {
		"v": v, "kg": g / 1000.0, "d": d_mm / 1000.0, "cd": c.cd * a.get("cd", 1.0),
		"pellets": pellets, "pen": c.pen * a.get("pen", 1.0), "dmg": a.get("dmg", 1.0),
		"moa": a.get("moa", 1.0), "tracer": a.get("tracer", false), "incendiary": a.get("incendiary", false),
		"explosive": c.get("explosive", 0.0) if not a.get("smoke", false) else 0.0, "smoke": a.get("smoke", false),
		"recoil": a.get("recoil", 1.0), "powder": c.pw, "cls": c.cls,
	}


## Drag constant k (1/m) so that dv/dt = -k * |v| * v.
static func drag_k(p: Dictionary) -> float:
	var area := PI * pow(p.d * 0.5, 2.0)
	return 0.5 * 1.2 * p.cd * area / maxf(p.kg, 1e-5)

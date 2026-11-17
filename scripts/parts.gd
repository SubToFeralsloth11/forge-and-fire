class_name Parts
extends RefCounted
## Catalogue of platforms (receivers) and every attachable part.
## Lengths shown to the player are in centimetres; models work in metres.
##
## A build is {"rcv": id, "cal": id, "ammo": id, "name": str, "fin": finish,
## "parts": {slot: {"id": part, "p": {param: value}, "f": finish}}}.
## Each receiver maps slots to a compatibility tag; a part fits when the tag is
## in its "fits" list.

const SLOTS := ["barrel", "trigger", "grip", "stock", "mag", "handguard", "muzzle", "under", "side", "optic"]
const SLOT_NAMES := {
	"barrel": "Barrel", "trigger": "Trigger Group", "grip": "Pistol Grip", "stock": "Stock",
	"mag": "Magazine / Feed", "handguard": "Handguard / Forend", "muzzle": "Muzzle Device",
	"under": "Underbarrel", "side": "Side Rail", "optic": "Optic / Sights",
}
const CATS := ["Pistols", "Submachine Guns", "Rifles", "Precision", "Shotguns", "Heavy", "Launchers"]

## Receivers. blen = barrel length range/default in cm. cap = fixed capacity
## when the gun has no magazine slot.
const RCV := {
	"striker": {"name": "Striker Pistol", "cat": "Pistols", "fam": "pistol", "action": "semi", "cals": ["9mm", "10mm", "45acp", "57"], "rpm": 1100, "moa": 3.5, "kg": 0.45, "blen": [7.5, 15.0, 10.2], "recoil": 1.0, "jam": 0.0006, "reload": 1.6, "fin": "Black",
		"slots": {"barrel": "pistol", "muzzle": "pistol", "mag": "pistol", "optic": "slide", "under": "pistol_rail", "trigger": "trig"},
		"def": {"barrel": "brl_pistol", "mag": "mag_std", "trigger": "trig_std"},
		"desc": "Polymer-framed, striker-fired service pistol. Light, simple and tough."},
	"hammer": {"name": "Hammer Pistol 1911", "cat": "Pistols", "fam": "pistol", "action": "semi", "cals": ["45acp", "9mm", "10mm"], "rpm": 900, "moa": 2.8, "kg": 0.85, "blen": [8.5, 15.0, 12.7], "recoil": 0.92, "jam": 0.0012, "reload": 1.7, "fin": "Blued Steel",
		"slots": {"barrel": "pistol", "muzzle": "pistol", "mag": "pistol1", "optic": "slide", "under": "pistol_rail", "trigger": "trig_m", "grip": "panel"},
		"def": {"barrel": "brl_pistol", "mag": "mag_std", "trigger": "trig_std", "grip": "pnl_wood"},
		"desc": "All-steel single-action pistol. Heavy, crisp trigger, single-stack magazine."},
	"revolver": {"name": "Magnum Revolver", "cat": "Pistols", "fam": "revolver", "action": "revolver", "cals": ["357", "44mag", "500sw"], "rpm": 300, "moa": 2.5, "kg": 1.0, "blen": [5.0, 25.0, 15.2], "recoil": 1.05, "jam": 0.0, "reload": 2.6, "cap": 6, "fin": "Stainless",
		"slots": {"barrel": "revolver", "optic": "rail", "under": "pistol_rail", "trigger": "trig_m", "grip": "rgrip"},
		"def": {"barrel": "brl_rev", "trigger": "trig_std", "grip": "rg_rubber"},
		"desc": "Double-action six-shooter. No magazine: reload with a speedloader."},
	"mpistol": {"name": "Machine Pistol", "cat": "Submachine Guns", "fam": "pistol", "action": "semi", "cals": ["9mm", "57"], "rpm": 1150, "moa": 4.0, "kg": 0.62, "blen": [10.0, 17.0, 11.4], "recoil": 1.0, "jam": 0.001, "reload": 1.7, "fin": "Black",
		"slots": {"barrel": "pistol", "muzzle": "pistol", "mag": "pistol", "optic": "slide", "under": "pistol_rail", "trigger": "trig", "stock": "brace"},
		"def": {"barrel": "brl_pistol", "mag": "mag_ext", "trigger": "trig_sel", "muzzle": "mz_pcomp"},
		"desc": "Select-fire pistol with an extended slide. Very fast cyclic rate."},
	"smg": {"name": "Roller-Delayed SMG", "cat": "Submachine Guns", "fam": "smg", "action": "semi", "cals": ["9mm", "10mm", "45acp"], "rpm": 800, "moa": 2.2, "kg": 2.1, "blen": [11.0, 30.0, 22.5], "recoil": 0.75, "jam": 0.0005, "reload": 2.2, "fin": "Black",
		"slots": {"barrel": "smg", "muzzle": "smg", "mag": "smg", "optic": "rail", "handguard": "smg", "stock": "smg", "grip": "pg", "trigger": "trig"},
		"def": {"barrel": "brl_gov", "mag": "mag_std", "handguard": "hg_smg_slim", "stock": "stk_smg_fixed", "grip": "gr_a2", "trigger": "trig_sel", "optic": "opt_irons"},
		"desc": "Closed-bolt, roller-delayed blowback. Smooth, accurate and controllable."},
	"pdw": {"name": "Compact PDW", "cat": "Submachine Guns", "fam": "pdw", "action": "semi", "cals": ["9mm", "57", "45acp", "300blk"], "rpm": 900, "moa": 2.4, "kg": 2.0, "blen": [11.0, 35.0, 16.5], "recoil": 0.8, "jam": 0.0007, "reload": 2.0, "fin": "Graphite",
		"slots": {"barrel": "smg", "muzzle": "smg", "mag": "smg", "optic": "rail", "handguard": "ar", "stock": "buffer", "grip": "pg", "trigger": "trig"},
		"def": {"barrel": "brl_gov", "mag": "mag_std", "handguard": "hg_mlok", "stock": "stk_pdw", "grip": "gr_ergo", "trigger": "trig_sel", "optic": "opt_holo"},
		"desc": "Short-stroke piston PDW. Compact, light, built to run suppressed."},
	"ar": {"name": "Direct Impingement Rifle", "cat": "Rifles", "fam": "ar", "action": "semi", "cals": ["556", "300blk", "545"], "rpm": 750, "moa": 1.6, "kg": 1.35, "blen": [19.0, 61.0, 36.8], "recoil": 0.8, "jam": 0.0006, "reload": 2.3, "fin": "Black",
		"slots": {"barrel": "rifle", "muzzle": "rifle", "mag": "stanag", "optic": "rail", "handguard": "ar", "stock": "buffer", "grip": "pg", "trigger": "trig", "under": "", "side": ""},
		"def": {"barrel": "brl_gov", "mag": "mag_std", "handguard": "hg_mlok", "stock": "stk_m4", "grip": "gr_a2", "trigger": "trig_sel", "muzzle": "mz_a2", "optic": "opt_reddot"},
		"desc": "The modular flat-top rifle. Light, accurate, takes every accessory there is."},
	"ak": {"name": "Long-Stroke Piston Rifle", "cat": "Rifles", "fam": "ak", "action": "semi", "cals": ["762x39", "545", "556"], "rpm": 620, "moa": 3.2, "kg": 2.3, "blen": [21.0, 59.0, 41.5], "recoil": 0.95, "jam": 0.0002, "reload": 2.4, "fin": "Parkerized",
		"slots": {"barrel": "rifle", "muzzle": "rifle", "mag": "ak", "optic": "rail", "handguard": "ak", "stock": "ak", "grip": "pg", "trigger": "trig"},
		"def": {"barrel": "brl_gov", "mag": "mag_std", "handguard": "hg_ak_wood", "stock": "stk_ak_wood", "grip": "gr_ak_wood", "trigger": "trig_sel", "muzzle": "mz_akbrake", "optic": "opt_irons"},
		"desc": "Stamped receiver, loose tolerances, runs through anything. Hits hard, groups wide."},
	"ar10": {"name": "Battle Rifle", "cat": "Rifles", "fam": "ar10", "action": "semi", "cals": ["762x51", "65cm"], "rpm": 650, "moa": 1.3, "kg": 2.2, "blen": [30.0, 66.0, 50.8], "recoil": 0.82, "jam": 0.0007, "reload": 2.5, "fin": "Black",
		"slots": {"barrel": "rifle", "muzzle": "rifle", "mag": "ar10", "optic": "rail", "handguard": "ar", "stock": "buffer", "grip": "pg", "trigger": "trig"},
		"def": {"barrel": "brl_med", "mag": "mag_std", "handguard": "hg_quad", "stock": "stk_a2", "grip": "gr_a2", "trigger": "trig_sel", "muzzle": "mz_3prong", "optic": "opt_acog"},
		"desc": "Full-power .308-class rifle on a large-frame flat-top receiver."},
	"bullpup": {"name": "Bullpup Rifle", "cat": "Rifles", "fam": "bullpup", "action": "semi", "cals": ["556", "300blk", "762x39"], "rpm": 780, "moa": 1.9, "kg": 2.6, "blen": [25.0, 61.0, 45.7], "recoil": 0.82, "jam": 0.0006, "reload": 2.8, "fin": "OD Green",
		"slots": {"barrel": "rifle", "muzzle": "rifle", "mag": "stanag", "optic": "rail", "handguard": "bullpup", "trigger": "trig"},
		"def": {"barrel": "brl_gov", "mag": "mag_std", "handguard": "hg_bp_short", "trigger": "trig_sel", "muzzle": "mz_a2", "optic": "opt_holo"},
		"desc": "Action behind the grip: a full-length barrel in a carbine-sized gun."},
	"lmg": {"name": "Belt-Fed LMG", "cat": "Heavy", "fam": "lmg", "action": "semi", "cals": ["556", "762x51"], "rpm": 780, "moa": 2.8, "kg": 5.2, "blen": [33.0, 56.0, 46.5], "recoil": 0.72, "jam": 0.0008, "reload": 5.5, "fin": "Black",
		"slots": {"barrel": "rifle", "muzzle": "rifle", "mag": "belt", "optic": "rail", "handguard": "lmg", "stock": "lmg", "grip": "pg", "trigger": "trig", "under": "lmg"},
		"def": {"barrel": "brl_heavy", "mag": "belt_200", "handguard": "hg_lmg", "stock": "stk_lmg", "grip": "gr_a2", "trigger": "trig_auto", "muzzle": "mz_a2", "optic": "opt_irons", "under": "ub_bipod"},
		"desc": "Open-bolt, belt-fed squad gun. Heavy and slow to reload; it never stops shooting."},
	"bolt": {"name": "Bolt-Action Rifle", "cat": "Precision", "fam": "bolt", "action": "bolt", "cals": ["762x51", "65cm", "3006", "300wm", "338lm"], "rpm": 50, "moa": 0.6, "kg": 1.3, "blen": [40.0, 76.0, 61.0], "recoil": 1.0, "jam": 0.0, "reload": 2.6, "fin": "Stainless",
		"slots": {"barrel": "rifle", "muzzle": "rifle", "mag": "bolt", "optic": "rail", "stock": "bolt", "grip": "pg", "trigger": "trig_m", "handguard": "bolt"},
		"def": {"barrel": "brl_heavy", "mag": "mag_std", "stock": "stk_chassis", "grip": "gr_target", "trigger": "trig_match", "muzzle": "mz_brake", "optic": "opt_525", "handguard": "hg_arca"},
		"desc": "Push-feed bolt action with a free-floated barrel. The accuracy king."},
	"amr": {"name": "Anti-Materiel Rifle", "cat": "Heavy", "fam": "amr", "action": "semi", "cals": ["50bmg"], "rpm": 160, "moa": 1.4, "kg": 8.5, "blen": [50.0, 74.0, 73.7], "recoil": 0.7, "jam": 0.0006, "reload": 3.4, "fin": "Flat Dark Earth",
		"slots": {"barrel": "amr", "muzzle": "amr", "mag": "amr", "optic": "rail", "stock": "amr", "grip": "pg", "trigger": "trig_m", "handguard": "amr", "under": "lmg"},
		"def": {"barrel": "brl_fluted", "mag": "mag_std", "stock": "stk_amr", "grip": "gr_a2", "trigger": "trig_std", "muzzle": "mz_50brake", "optic": "opt_10x", "handguard": "hg_amr", "under": "ub_bipod"},
		"desc": "Recoil-operated semi-auto .50 BMG. A 14 kg hammer that reaches 2 km."},
	"pump": {"name": "Pump Shotgun", "cat": "Shotguns", "fam": "pump", "action": "pump", "cals": ["12ga"], "rpm": 70, "moa": 3.0, "kg": 2.3, "blen": [35.0, 76.0, 47.0], "recoil": 1.0, "jam": 0.0, "reload": 0.55, "fin": "Parkerized",
		"slots": {"barrel": "shotgun", "muzzle": "shotgun", "mag": "tube", "optic": "rail", "stock": "shotgun", "grip": "pg", "trigger": "trig_m", "handguard": "pump"},
		"def": {"barrel": "brl_sg", "mag": "tube_6", "stock": "stk_sg_syn", "trigger": "trig_std", "handguard": "hg_pump_syn", "muzzle": "ch_cyl", "optic": "opt_irons"},
		"desc": "Tube-fed pump action. Load shells one at a time; rack after every shot."},
	"autoshotgun": {"name": "Box-Fed Auto Shotgun", "cat": "Shotguns", "fam": "ak", "action": "semi", "cals": ["12ga"], "rpm": 330, "moa": 3.2, "kg": 3.4, "blen": [33.0, 61.0, 48.0], "recoil": 0.85, "jam": 0.0015, "reload": 2.6, "fin": "Black",
		"slots": {"barrel": "shotgun", "muzzle": "shotgun", "mag": "box12", "optic": "rail", "stock": "ak", "grip": "pg", "trigger": "trig", "handguard": "ak"},
		"def": {"barrel": "brl_sg", "mag": "mag_std", "stock": "stk_ak_poly", "grip": "gr_ergo", "trigger": "trig_std", "handguard": "hg_ak_quad", "muzzle": "ch_mod", "optic": "opt_holo"},
		"desc": "Gas-operated 12 gauge on a long-stroke action. Mag-fed, devastating up close."},
	"double": {"name": "Double-Barrel Shotgun", "cat": "Shotguns", "fam": "double", "action": "break", "cals": ["12ga"], "rpm": 300, "moa": 3.0, "kg": 2.6, "blen": [30.0, 76.0, 71.0], "recoil": 1.05, "jam": 0.0, "reload": 2.0, "cap": 2, "fin": "Blued Steel",
		"slots": {"barrel": "double", "muzzle": "shotgun", "stock": "shotgun", "trigger": "trig_m", "handguard": "double"},
		"def": {"barrel": "brl_sg", "stock": "stk_sg_wood", "trigger": "trig_std", "handguard": "hg_dbl", "muzzle": "ch_mod"},
		"desc": "Side-by-side break action. Two shots, two triggers, reload by hand."},
	"lever": {"name": "Lever-Action Rifle", "cat": "Precision", "fam": "lever", "action": "lever", "cals": ["3030", "4570", "357", "44mag"], "rpm": 90, "moa": 2.0, "kg": 2.4, "blen": [40.0, 61.0, 51.0], "recoil": 1.0, "jam": 0.0, "reload": 0.6, "fin": "Blued Steel",
		"slots": {"barrel": "lever", "muzzle": "rifle", "mag": "ltube", "optic": "rail", "stock": "lever", "trigger": "trig_m", "handguard": "lever"},
		"def": {"barrel": "brl_gov", "mag": "tube_6", "stock": "stk_lever", "trigger": "trig_std", "handguard": "hg_lev_wood", "optic": "opt_irons"},
		"desc": "Classic tube-fed lever gun. Work the lever between shots."},
	"gl": {"name": "Revolving Grenade Launcher", "cat": "Launchers", "fam": "gl", "action": "revolver", "cals": ["40mm"], "rpm": 120, "moa": 8.0, "kg": 4.6, "blen": [30.0, 30.0, 30.0], "recoil": 0.8, "jam": 0.0, "reload": 4.0, "cap": 6, "fin": "Flat Dark Earth",
		"slots": {"barrel": "gl", "optic": "rail", "stock": "buffer", "grip": "pg", "trigger": "trig_m", "under": ""},
		"def": {"barrel": "brl_gl", "stock": "stk_m4", "grip": "gr_a2", "trigger": "trig_std", "optic": "opt_holo"},
		"desc": "Six-round 40 mm launcher. Lob high-explosive grenades in an arc."},
}

## Magazine capacities per magazine tag and part.
const CAPS := {
	"stanag": {"mag_short": 10, "mag_std": 30, "mag_ext": 40, "mag_quad": 60, "mag_drum": 100},
	"ak": {"mag_short": 10, "mag_std": 30, "mag_ext": 45, "mag_quad": 60, "mag_drum": 75},
	"ar10": {"mag_short": 10, "mag_std": 20, "mag_ext": 25, "mag_drum": 50},
	"pistol": {"mag_short": 10, "mag_std": 17, "mag_ext": 21, "mag_quad": 33, "mag_drum": 50},
	"pistol1": {"mag_short": 6, "mag_std": 8, "mag_ext": 10},
	"smg": {"mag_short": 15, "mag_std": 30, "mag_ext": 40, "mag_drum": 100},
	"bolt": {"mag_short": 5, "mag_std": 10},
	"amr": {"mag_short": 5, "mag_std": 10},
	"box12": {"mag_short": 5, "mag_std": 8, "mag_ext": 12, "mag_drum": 20},
	"tube": {"tube_4": 4, "tube_6": 6, "tube_8": 8},
	"ltube": {"tube_4": 5, "tube_6": 8, "tube_8": 10},
	"belt": {"belt_100": 100, "belt_200": 200, "mag_std": 30},
}

static var _parts := {}


static func all() -> Dictionary:
	if _parts.is_empty():
		_init_parts()
	return _parts


static func get_part(id: String) -> Dictionary:
	return all().get(id, {})


static func _add(id: String, slot: String, name: String, fits: Array, kg: float, mods := {}, extra := {}) -> void:
	var d := {"id": id, "slot": slot, "name": name, "fits": fits, "kg": kg, "m": mods, "desc": extra.get("desc", ""), "fin": extra.get("fin", "Black"), "p": extra.get("p", {}), "mdl": extra.get("mdl", id)}
	for k in extra:
		if not d.has(k):
			d[k] = extra[k]
	_parts[id] = d


static func _init_parts() -> void:
	var RIF := ["rifle", "amr", "lever"]
	# ---------------- Barrels (kg per cm in "kgcm") ----------------
	_add("brl_pencil", "barrel", "Pencil Profile", ["rifle", "smg", "lever"], 0.0, {"moa": 1.12, "heat": 1.5, "sway": 0.92}, {"kgcm": 0.010, "desc": "Thin and light. Points fast, heats fast and groups open up when hot."})
	_add("brl_gov", "barrel", "Government Profile", ["rifle", "smg", "lever"], 0.0, {"moa": 1.0, "heat": 1.0}, {"kgcm": 0.0145, "desc": "The standard step-down military profile."})
	_add("brl_med", "barrel", "Medium Contour", ["rifle", "smg", "amr", "lever"], 0.0, {"moa": 0.88, "heat": 0.8}, {"kgcm": 0.018, "desc": "A balance of weight and stiffness."})
	_add("brl_heavy", "barrel", "Heavy Contour", ["rifle", "amr", "lever"], 0.0, {"moa": 0.74, "heat": 0.55, "sway": 1.06}, {"kgcm": 0.026, "desc": "Thick, stiff and slow to heat. Tight groups, nose-heavy."})
	_add("brl_fluted", "barrel", "Fluted Heavy", ["rifle", "amr"], 0.0, {"moa": 0.78, "heat": 0.6}, {"kgcm": 0.019, "desc": "Heavy contour with milled flutes: stiffness without all the weight."})
	_add("brl_carbon", "barrel", "Carbon-Wrapped", ["rifle", "amr"], 0.0, {"moa": 0.8, "heat": 0.7, "sway": 0.9}, {"kgcm": 0.0105, "fin": "Carbon Fiber", "desc": "Steel liner wrapped in carbon fibre. Light, stiff, sheds heat."})
	_add("brl_bull", "barrel", "Straight Bull", ["rifle", "amr"], 0.0, {"moa": 0.66, "heat": 0.45, "sway": 1.12}, {"kgcm": 0.034, "fin": "Stainless", "desc": "A straight cylinder of steel. Benchrest accuracy, brutal weight."})
	_add("brl_pistol", "barrel", "Pistol Barrel", ["pistol"], 0.0, {}, {"kgcm": 0.008, "desc": "Standard pistol barrel. The slide grows with it."})
	_add("brl_pistol_thr", "barrel", "Threaded Pistol Barrel", ["pistol"], 0.0, {"noise": 0.0}, {"kgcm": 0.0085, "fin": "Bronze", "desc": "Gold-tone TiN barrel that sticks out past the slide."})
	_add("brl_pistol_port", "barrel", "Ported Pistol Barrel", ["pistol"], 0.0, {"climb": 0.8, "flash": 1.4, "noise": 2.0}, {"kgcm": 0.0085, "desc": "Gas ports at the muzzle push the slide down."})
	_add("brl_rev", "barrel", "Full Underlug Barrel", ["revolver"], 0.0, {"climb": 0.9}, {"kgcm": 0.03, "desc": "Full-length underlug adds weight up front to tame flip."})
	_add("brl_rev_slim", "barrel", "Tapered Barrel", ["revolver"], 0.0, {"climb": 1.05}, {"kgcm": 0.02, "desc": "Classic tapered barrel with an ejector-rod shroud."})
	_add("brl_rev_vent", "barrel", "Vent-Rib Barrel", ["revolver"], 0.0, {"climb": 0.92, "moa": 0.9}, {"kgcm": 0.032, "desc": "Ventilated top rib and full lug: a target barrel."})
	_add("brl_sg", "barrel", "Plain Shotgun Barrel", ["shotgun", "double"], 0.0, {}, {"kgcm": 0.016, "desc": "Smooth-bore 12 gauge barrel with a bead sight."})
	_add("brl_sg_rib", "barrel", "Vent-Rib Shotgun Barrel", ["shotgun", "double"], 0.0, {"moa": 0.9}, {"kgcm": 0.018, "desc": "Raised ventilated rib for fast pointing."})
	_add("brl_sg_rifled", "barrel", "Rifled Slug Barrel", ["shotgun"], 0.0, {"moa": 0.5, "pellet": 1.5}, {"kgcm": 0.02, "desc": "Rifled bore: slugs group tight, buckshot spreads wide."})
	_add("brl_gl", "barrel", "40 mm Launcher Tube", ["gl"], 0.0, {}, {"kgcm": 0.025, "desc": "Rifled 40 mm tube."})
	# ---------------- Muzzle devices ----------------
	_add("mz_a2", "muzzle", "Birdcage Flash Hider", ["rifle", "smg"], 0.08, {"flash": 0.4, "climb": 0.95}, {"desc": "Closed-bottom flash hider. Hides flash and kicks up less dust."})
	_add("mz_3prong", "muzzle", "Three-Prong Flash Hider", ["rifle", "amr", "smg"], 0.09, {"flash": 0.25}, {"desc": "Open tines that eat almost all muzzle flash."})
	_add("mz_brake", "muzzle", "Tactical Muzzle Brake", ["rifle", "amr"], 0.12, {"recoil": 0.62, "noise": 5.0, "flash": 1.3}, {"desc": "Side-ported brake: much less recoil, much more blast."})
	_add("mz_akbrake", "muzzle", "Slant Compensator", ["rifle", "smg"], 0.05, {"climb": 0.85, "recoil": 0.95}, {"desc": "Slanted cut vents gas up and right to fight climb."})
	_add("mz_comp", "muzzle", "Linear Compensator", ["rifle", "smg", "pistol"], 0.1, {"climb": 0.72, "recoil": 0.88, "noise": 1.5}, {"desc": "Ported on top: holds the muzzle down in rapid fire."})
	_add("mz_linear", "muzzle", "Blast Can", ["rifle", "smg"], 0.15, {"noise": -2.0, "flash": 0.5}, {"desc": "Throws the blast forward, away from you."})
	_add("mz_supp", "muzzle", "Compact Suppressor", ["rifle", "smg", "pistol"], 0.32, {"supp": true, "noise": -26.0, "flash": 0.05, "recoil": 0.85, "v": 1.01, "jam": 1.3}, {"len": 0.14, "desc": "Short sound suppressor. Trims about 26 dB."})
	_add("mz_supp_long", "muzzle", "Full-Size Suppressor", ["rifle", "smg"], 0.5, {"supp": true, "noise": -32.0, "flash": 0.02, "recoil": 0.8, "v": 1.015, "jam": 1.4, "sway": 1.05}, {"len": 0.2, "fin": "Graphite", "desc": "Long can, hearing-safe on subsonic loads."})
	_add("mz_supp_pistol", "muzzle", "Pistol Suppressor", ["pistol", "smg"], 0.24, {"supp": true, "noise": -28.0, "flash": 0.05, "recoil": 0.88}, {"len": 0.17, "desc": "Booster-equipped pistol can."})
	_add("mz_oil", "muzzle", "Integral Wipe Can", ["smg", "pistol"], 0.28, {"supp": true, "noise": -30.0, "flash": 0.03, "recoil": 0.86, "v": 0.97}, {"len": 0.19, "fin": "Black", "desc": "Long wipe-style can: very quiet, slightly slows the bullet."})
	_add("mz_50brake", "muzzle", "Dual-Chamber .50 Brake", ["amr", "rifle"], 0.5, {"recoil": 0.55, "noise": 6.0, "flash": 1.5}, {"desc": "Huge two-chamber brake. Absorbs most of the kick."})
	_add("mz_pcomp", "muzzle", "Pistol Compensator", ["pistol"], 0.06, {"climb": 0.7, "noise": 1.5, "flash": 1.2}, {"desc": "Bolt-on comp that keeps the dot on target."})
	_add("ch_cyl", "muzzle", "Cylinder Choke", ["shotgun"], 0.04, {"pellet": 1.0}, {"desc": "No constriction: widest pattern."})
	_add("ch_mod", "muzzle", "Modified Choke", ["shotgun"], 0.04, {"pellet": 0.75}, {"desc": "Medium constriction."})
	_add("ch_full", "muzzle", "Full Choke", ["shotgun"], 0.05, {"pellet": 0.55}, {"desc": "Tight constriction: dense pattern at range."})
	_add("ch_breach", "muzzle", "Breacher Choke", ["shotgun"], 0.12, {"pellet": 0.95, "climb": 0.85}, {"desc": "Toothed stand-off breaching choke with gas ports."})
	_add("mz_sgsupp", "muzzle", "Shotgun Suppressor", ["shotgun"], 0.55, {"supp": true, "noise": -22.0, "flash": 0.05, "recoil": 0.85, "pellet": 1.0}, {"len": 0.24, "desc": "Fat 12 gauge can."})
	# ---------------- Handguards ----------------
	var hgp := {"len": [15.0, 50.0, 1.0, 33.0, "cm"]}
	_add("hg_classic", "handguard", "Ribbed Round Handguard", ["ar", "lmg"], 0.3, {"moa": 1.05}, {"desc": "Classic two-piece heat-shielded handguard."})
	_add("hg_quad", "handguard", "Quad Rail", ["ar", "lmg"], 0.42, {"moa": 1.0}, {"p": hgp, "desc": "Rails at 12, 3, 6 and 9 o'clock."})
	_add("hg_mlok", "handguard", "Slim M-LOK Rail", ["ar", "lmg"], 0.28, {"moa": 0.9}, {"p": hgp, "desc": "Free-float, light and slim."})
	_add("hg_keymod", "handguard", "KeyMod Rail", ["ar", "lmg"], 0.31, {"moa": 0.9}, {"p": hgp, "fin": "Flat Dark Earth", "desc": "Free-float with keyhole slots."})
	_add("hg_carbon", "handguard", "Carbon Tube", ["ar", "lmg"], 0.2, {"moa": 0.9, "sway": 0.95}, {"p": hgp, "fin": "Carbon Fiber", "desc": "Featherweight free-float tube."})
	_add("hg_vent", "handguard", "Vented Competition Rail", ["ar", "lmg"], 0.3, {"moa": 0.9, "heat": 0.85}, {"p": hgp, "fin": "Cobalt", "desc": "Large vents: barrel cools faster."})
	_add("hg_ak_wood", "handguard", "AK Wood Handguard", ["ak"], 0.32, {"moa": 1.0}, {"fin": "Walnut", "desc": "Laminated wood with a gas tube cover."})
	_add("hg_ak_poly", "handguard", "AK Polymer Handguard", ["ak"], 0.28, {"moa": 1.0}, {"fin": "Black", "desc": "Plum or black polymer furniture."})
	_add("hg_ak_quad", "handguard", "AK Quad Rail", ["ak"], 0.45, {"moa": 1.0}, {"desc": "Drop-in rail with gas tube rail on top."})
	_add("hg_ak_mlok", "handguard", "AK M-LOK Rail", ["ak"], 0.33, {"moa": 0.92}, {"fin": "Flat Dark Earth", "desc": "Long M-LOK handguard for AK pattern rifles."})
	_add("hg_smg_slim", "handguard", "Slimline Handguard", ["smg"], 0.15, {}, {"desc": "Thin ribbed polymer handguard."})
	_add("hg_smg_wide", "handguard", "Tropical Handguard", ["smg"], 0.2, {"sway": 0.95}, {"desc": "Wide fluted handguard, good grip."})
	_add("hg_smg_rail", "handguard", "Railed Handguard", ["smg"], 0.25, {}, {"desc": "Three-rail aluminium handguard."})
	_add("hg_pump_syn", "handguard", "Synthetic Pump", ["pump"], 0.2, {}, {"desc": "Ribbed polymer slide."})
	_add("hg_pump_wood", "handguard", "Wood Corncob Pump", ["pump"], 0.25, {}, {"fin": "Walnut", "desc": "Grooved wooden forend."})
	_add("hg_pump_rail", "handguard", "Railed Pump", ["pump"], 0.3, {}, {"desc": "Pump forend with an under rail."})
	_add("hg_lev_wood", "handguard", "Wood Forend", ["lever"], 0.2, {}, {"fin": "Walnut", "desc": "Classic barrel-banded forend."})
	_add("hg_lev_mlok", "handguard", "M-LOK Lever Forend", ["lever"], 0.25, {"moa": 0.95}, {"desc": "Modern aluminium forend with slots."})
	_add("hg_arca", "handguard", "ARCA Chassis Forend", ["bolt"], 0.5, {"moa": 0.9}, {"p": {"len": [25.0, 50.0, 1.0, 38.0, "cm"]}, "desc": "Free-float forend with ARCA rail for bipods."})
	_add("hg_amr", "handguard", "Ventilated .50 Shroud", ["amr"], 0.9, {}, {"desc": "Big perforated barrel shroud."})
	_add("hg_lmg", "handguard", "Heat-Shield Handguard", ["lmg"], 0.4, {}, {"desc": "Ribbed LMG handguard with carry handle."})
	_add("hg_bp_short", "handguard", "Bullpup Short Rail", ["bullpup"], 0.12, {}, {"desc": "Short under-rail section."})
	_add("hg_bp_long", "handguard", "Bullpup Extended Rail", ["bullpup"], 0.25, {"moa": 0.95}, {"desc": "Free-float extension with side rails."})
	_add("hg_dbl", "handguard", "Splinter Forend", ["double"], 0.15, {}, {"fin": "Walnut", "desc": "Slim wooden forend."})
	_add("hg_dbl_beaver", "handguard", "Beavertail Forend", ["double"], 0.22, {"sway": 0.95}, {"fin": "Walnut", "desc": "Wide forend that fills the hand."})
	# ---------------- Stocks ----------------
	_add("stk_m4", "stock", "Collapsible Carbine Stock", ["buffer", "ak", "smg", "shotgun", "lmg"], 0.35, {"recoil": 0.9, "ads": 1.0}, {"p": {"lop": [0.0, 8.0, 1.0, 4.0, "cm"]}, "desc": "Six-position telescoping stock."})
	_add("stk_crane", "stock", "Battery Crane Stock", ["buffer", "ak", "smg", "shotgun", "lmg"], 0.45, {"recoil": 0.86, "sway": 0.95}, {"p": {"lop": [0.0, 8.0, 1.0, 4.0, "cm"]}, "desc": "Wider cheek weld with battery tubes."})
	_add("stk_a2", "stock", "Fixed Rifle Stock", ["buffer", "lmg"], 0.5, {"recoil": 0.84, "sway": 0.9, "ads": 1.04}, {"desc": "Full-length fixed stock."})
	_add("stk_prs", "stock", "Precision Adjustable Stock", ["buffer", "bolt", "ak"], 0.75, {"recoil": 0.8, "sway": 0.72, "ads": 1.1}, {"p": {"cheek": [0.0, 3.0, 0.5, 1.0, "cm"]}, "desc": "Adjustable cheek riser and length. Rock steady."})
	_add("stk_skel", "stock", "Skeleton Stock", ["buffer", "ak", "smg"], 0.22, {"recoil": 0.96, "ads": 0.95}, {"desc": "Minimal open-frame stock."})
	_add("stk_pdw", "stock", "PDW Telescoping Stock", ["buffer", "smg", "brace"], 0.25, {"recoil": 1.0, "ads": 0.92, "sway": 1.05}, {"p": {"lop": [0.0, 10.0, 1.0, 6.0, "cm"]}, "desc": "Twin-rod stock that collapses flush."})
	_add("stk_brace", "stock", "Pistol Stabilizing Brace", ["buffer", "brace", "smg"], 0.2, {"recoil": 1.1, "ads": 0.9, "sway": 1.12}, {"desc": "Forearm brace. Better than nothing."})
	_add("stk_ak_wood", "stock", "AK Wood Stock", ["ak"], 0.45, {"recoil": 0.88}, {"fin": "Walnut", "desc": "Fixed laminated wood stock."})
	_add("stk_ak_poly", "stock", "AK Polymer Stock", ["ak"], 0.4, {"recoil": 0.88}, {"desc": "Fixed polymer stock."})
	_add("stk_underfold", "stock", "AK Underfolder", ["ak"], 0.4, {"recoil": 1.0, "ads": 0.96}, {"fin": "Parkerized", "desc": "Steel under-folding stock."})
	_add("stk_sidefold", "stock", "Triangle Side-Folder", ["ak", "smg", "buffer"], 0.38, {"recoil": 0.95}, {"desc": "Triangular folding polymer stock."})
	_add("stk_smg_fixed", "stock", "SMG Fixed Stock", ["smg"], 0.35, {"recoil": 0.9, "sway": 0.95}, {"desc": "Solid polymer stock."})
	_add("stk_smg_wire", "stock", "SMG Retractable Stock", ["smg", "brace"], 0.3, {"recoil": 0.97, "ads": 0.94}, {"fin": "Parkerized", "desc": "Steel sliding stock."})
	_add("stk_hunter", "stock", "Monte Carlo Wood Stock", ["bolt"], 1.3, {"recoil": 0.85, "sway": 0.85}, {"fin": "Walnut", "grip": true, "forend": true, "desc": "Full hunting stock with integral grip and forend."})
	_add("stk_thumb", "stock", "Thumbhole Laminate Stock", ["bolt"], 1.4, {"recoil": 0.83, "sway": 0.8}, {"fin": "Laminate", "grip": true, "forend": true, "desc": "Thumbhole grip, stiff laminate."})
	_add("stk_chassis", "stock", "Precision Chassis Stock", ["bolt"], 1.1, {"recoil": 0.78, "sway": 0.7, "ads": 1.08}, {"fin": "Sniper Grey", "p": {"cheek": [0.0, 3.0, 0.5, 1.5, "cm"]}, "desc": "Folding chassis butt with cheek and LOP adjustment."})
	_add("stk_sg_wood", "stock", "Wood Shotgun Stock", ["shotgun", "lever"], 0.6, {"recoil": 0.85}, {"fin": "Walnut", "grip": true, "desc": "Classic wood stock with a recoil pad."})
	_add("stk_sg_syn", "stock", "Synthetic Shotgun Stock", ["shotgun"], 0.5, {"recoil": 0.85}, {"grip": true, "desc": "Polymer stock with a thick pad."})
	_add("stk_lever", "stock", "Straight Lever Stock", ["lever"], 0.55, {"recoil": 0.9}, {"fin": "Walnut", "grip": true, "desc": "Straight-grip walnut stock with a crescent butt plate."})
	_add("stk_amr", "stock", "AMR Recoil Butt", ["amr"], 1.4, {"recoil": 0.75, "sway": 0.85}, {"desc": "Spring-cushioned butt with a monopod."})
	_add("stk_lmg", "stock", "LMG Fixed Stock", ["lmg", "buffer"], 0.6, {"recoil": 0.82, "sway": 0.9}, {"desc": "Hollow polymer stock with a shoulder strap loop."})
	# ---------------- Grips ----------------
	_add("gr_a2", "grip", "A2 Grip", ["pg"], 0.07, {}, {"desc": "Standard ribbed pistol grip."})
	_add("gr_ergo", "grip", "Ergonomic Grip", ["pg"], 0.09, {"hip": 0.92, "ads": 0.97}, {"desc": "Rubberised, palm swell."})
	_add("gr_vert", "grip", "Steep Angle Grip", ["pg"], 0.08, {"ads": 0.95, "sway": 1.03}, {"desc": "Upright grip for a squared-up stance."})
	_add("gr_ak_wood", "grip", "AK Wood Grip", ["pg"], 0.08, {}, {"fin": "Walnut", "desc": "Slim wooden pistol grip."})
	_add("gr_ak_poly", "grip", "AK Polymer Grip", ["pg"], 0.07, {}, {"desc": "Bakelite-style grip."})
	_add("gr_skel", "grip", "Skeleton Grip", ["pg"], 0.05, {"ads": 0.95, "hip": 1.05}, {"fin": "Crimson", "desc": "Cut-out aluminium grip."})
	_add("gr_target", "grip", "Precision Target Grip", ["pg"], 0.15, {"sway": 0.9, "moa": 0.96}, {"desc": "Thumb shelf and palm rest."})
	_add("pnl_wood", "grip", "Walnut Grip Panels", ["panel"], 0.05, {}, {"fin": "Walnut", "desc": "Checkered walnut."})
	_add("pnl_g10", "grip", "G10 Grip Panels", ["panel"], 0.04, {"hip": 0.95}, {"fin": "Ranger Green", "desc": "Aggressive G10 texture."})
	_add("pnl_ivory", "grip", "Ivory Grip Panels", ["panel"], 0.05, {}, {"fin": "Bone White", "desc": "Smooth ivory-look panels."})
	_add("rg_rubber", "grip", "Rubber Finger-Groove Grip", ["rgrip"], 0.12, {"recoil": 0.92}, {"desc": "Soaks up magnum recoil."})
	_add("rg_wood", "grip", "Wood Target Grip", ["rgrip"], 0.14, {"moa": 0.95}, {"fin": "Walnut", "desc": "Hand-filling walnut grip."})
	_add("rg_bird", "grip", "Birdshead Grip", ["rgrip"], 0.08, {"recoil": 1.1, "ads": 0.92}, {"fin": "Bone White", "desc": "Small rounded grip, quick to draw."})
	# ---------------- Magazines ----------------
	var MAGS := ["stanag", "ak", "ar10", "pistol", "pistol1", "smg", "bolt", "amr", "box12", "belt"]
	_add("mag_short", "mag", "Short Magazine", MAGS, 0.0, {"reload": 0.95}, {"desc": "Low-profile magazine. Get down lower when prone."})
	_add("mag_std", "mag", "Standard Magazine", MAGS, 0.0, {}, {"desc": "Standard-capacity magazine."})
	_add("mag_ext", "mag", "Extended Magazine", ["stanag", "ak", "ar10", "pistol", "pistol1", "smg", "box12"], 0.0, {"reload": 1.08}, {"desc": "Longer magazine, more rounds."})
	_add("mag_quad", "mag", "Quad-Stack Magazine", ["stanag", "ak", "pistol"], 0.0, {"reload": 1.15, "jam": 1.4}, {"desc": "Four-column magazine: double the rounds, same length."})
	_add("mag_drum", "mag", "Drum Magazine", ["stanag", "ak", "ar10", "pistol", "smg", "box12"], 0.0, {"reload": 1.45, "jam": 1.6, "sway": 1.05}, {"desc": "Big round drum. Heavy and slow to swap."})
	_add("tube_4", "mag", "Short Tube", ["tube", "ltube"], 0.05, {}, {"desc": "Short magazine tube."})
	_add("tube_6", "mag", "Standard Tube", ["tube", "ltube"], 0.08, {}, {"desc": "Full-length tube."})
	_add("tube_8", "mag", "Extended Tube", ["tube", "ltube"], 0.12, {"sway": 1.04}, {"desc": "Tube extension past the barrel clamp."})
	_add("belt_100", "mag", "100-Round Belt Pouch", ["belt"], 0.1, {"reload": 0.9}, {"desc": "Soft pouch with a 100-round belt."})
	_add("belt_200", "mag", "200-Round Ammo Box", ["belt"], 0.25, {"sway": 1.06}, {"desc": "Hard box with a 200-round belt."})
	# ---------------- Optics ----------------
	var RAIL := ["rail"]
	_add("opt_irons", "optic", "Flip-Up Iron Sights", ["rail"], 0.12, {"ads": 0.88}, {"zoom": [1.0], "kind": "irons", "desc": "Aperture rear and post front."})
	_add("opt_reddot", "optic", "Red Dot (30 mm)", RAIL, 0.2, {"ads": 0.95}, {"zoom": [1.0], "kind": "dot", "desc": "Tube red dot on a cantilever mount."})
	_add("opt_minidot", "optic", "Mini Red Dot", ["rail", "slide"], 0.05, {"ads": 0.9}, {"zoom": [1.0], "kind": "dot", "desc": "Open-emitter reflex sight."})
	_add("opt_holo", "optic", "Holographic Sight", RAIL, 0.32, {"ads": 0.97}, {"zoom": [1.0], "kind": "holo", "desc": "Big window, 68 MOA ring with a centre dot."})
	_add("opt_holomag", "optic", "Holo + 3x Magnifier", RAIL, 0.62, {"ads": 1.08}, {"zoom": [1.0, 3.0], "kind": "holo", "desc": "Holographic sight with a flip magnifier. Press T to flip."})
	_add("opt_prism", "optic", "Prism Scope 2.5x", RAIL, 0.3, {"ads": 1.04}, {"zoom": [2.5], "kind": "scope", "desc": "Compact etched-reticle prism."})
	_add("opt_acog", "optic", "Combat Scope 4x", RAIL, 0.45, {"ads": 1.08}, {"zoom": [4.0], "kind": "scope", "desc": "Fixed 4x with a bullet-drop reticle."})
	_add("opt_lpvo", "optic", "LPVO 1-6x", RAIL, 0.6, {"ads": 1.1}, {"zoom": [1.0, 2.0, 4.0, 6.0], "kind": "scope", "desc": "Low-power variable. Press T to change zoom."})
	_add("opt_39", "optic", "Hunting Scope 3-9x", RAIL, 0.5, {"ads": 1.12}, {"zoom": [3.0, 6.0, 9.0], "kind": "scope", "desc": "Classic duplex hunting scope."})
	_add("opt_10x", "optic", "Tactical Scope 10x", RAIL, 0.7, {"ads": 1.16}, {"zoom": [10.0], "kind": "scope", "desc": "Fixed 10x with a mil-dot reticle."})
	_add("opt_525", "optic", "Long-Range Scope 5-25x", RAIL, 0.95, {"ads": 1.2, "sway": 1.03}, {"zoom": [5.0, 10.0, 15.0, 25.0], "kind": "scope", "desc": "First-focal-plane mil reticle for 1,000 m+."})
	# ---------------- Underbarrel ----------------
	_add("ub_vgrip", "under", "Vertical Foregrip", ["rail"], 0.1, {"recoil": 0.92, "hip": 0.9, "ads": 1.03}, {"desc": "Straight foregrip."})
	_add("ub_agrip", "under", "Angled Foregrip", ["rail"], 0.07, {"climb": 0.9, "ads": 0.97}, {"desc": "Angled grip: faster aim, less climb."})
	_add("ub_stop", "under", "Hand Stop", ["rail"], 0.03, {"climb": 0.95}, {"desc": "Small stop for a C-clamp hold."})
	_add("ub_bipod", "under", "Folding Bipod", ["rail", "lmg"], 0.38, {"ads": 1.06, "sway": 1.04}, {"bipod": true, "desc": "Deploys when you crouch or go prone: recoil and sway nearly vanish."})
	_add("ub_gl", "under", "Underbarrel 40 mm Launcher", ["rail"], 1.4, {"ads": 1.15, "sway": 1.15}, {"ubgl": true, "desc": "Single-shot launcher. Press G to fire a grenade."})
	_add("ub_sg", "under", "Underbarrel Shotgun", ["rail"], 1.1, {"ads": 1.12, "sway": 1.12}, {"ubsg": true, "desc": "Three-shell straight-pull shotgun. Press G to fire."})
	_add("ub_light", "under", "Weapon Light", ["rail", "pistol_rail"], 0.12, {}, {"light": true, "desc": "1,000 lumen light. Press L."})
	_add("ub_laser", "under", "Pistol Laser", ["pistol_rail"], 0.06, {"hip": 0.75}, {"laser": true, "desc": "Red laser: tighter hip fire."})
	# ---------------- Side rail ----------------
	_add("sd_laser", "side", "Visible Laser", ["rail"], 0.08, {"hip": 0.72}, {"laser": true, "desc": "Red aiming laser. Hip fire lands near the dot."})
	_add("sd_light", "side", "Scout Light", ["rail"], 0.12, {}, {"light": true, "desc": "Compact weapon light. Press L."})
	_add("sd_peq", "side", "Laser/Light Box", ["rail"], 0.2, {"hip": 0.75}, {"laser": true, "light": true, "fin": "Flat Dark Earth", "desc": "Combined laser and light module."})
	# ---------------- Trigger groups ----------------
	_add("trig_std", "trigger", "Standard Trigger", ["trig", "trig_m"], 0.05, {}, {"modes": ["semi"], "desc": "Semi-automatic only."})
	_add("trig_match", "trigger", "Two-Stage Match Trigger", ["trig", "trig_m"], 0.05, {"moa": 0.85}, {"modes": ["semi"], "desc": "Crisp 1.5 kg break: tighter groups."})
	_add("trig_flat", "trigger", "Flat-Face Competition", ["trig", "trig_m"], 0.05, {"moa": 0.92, "split": 0.8}, {"modes": ["semi"], "fin": "Crimson", "desc": "Short reset: faster follow-ups."})
	_add("trig_sel", "trigger", "Select-Fire Group", ["trig"], 0.06, {}, {"modes": ["semi", "auto"], "desc": "Semi and full auto. Press B to switch."})
	_add("trig_burst", "trigger", "Burst Group", ["trig"], 0.06, {"climb": 0.95}, {"modes": ["semi", "burst"], "desc": "Semi and 3-round burst."})
	_add("trig_three", "trigger", "Three-Position Selector", ["trig"], 0.06, {}, {"modes": ["semi", "burst", "auto"], "desc": "Semi, burst and auto."})
	_add("trig_auto", "trigger", "Open-Bolt Auto Group", ["trig"], 0.06, {"moa": 1.1}, {"modes": ["auto"], "desc": "Fires from an open bolt: auto only, no cook-offs."})


## Compatible part ids for a slot on a receiver.
static func options(rcv_id: String, slot: String) -> Array:
	var r: Dictionary = RCV[rcv_id]
	if not r.slots.has(slot):
		return []
	var tag: String = r.slots[slot]
	if slot in ["under", "side"] and tag == "":
		tag = "rail"
	var out := []
	for id in all():
		var p: Dictionary = _parts[id]
		if p.slot == slot and tag in p.fits:
			out.append(id)
	return out


static func required(rcv_id: String, slot: String) -> bool:
	return slot in ["barrel", "trigger"] or (slot == "mag" and RCV[rcv_id].slots.has("mag"))


static func capacity(build: Dictionary) -> int:
	var r: Dictionary = RCV[build.rcv]
	if r.has("cap"):
		var c: int = r.cap
		if build.rcv == "revolver" and build.cal == "500sw":
			c = 5
		return c
	var m: Dictionary = build.parts.get("mag", {})
	if m.is_empty():
		return 1
	var tag: String = r.slots.mag
	return CAPS.get(tag, {}).get(m.id, 10)

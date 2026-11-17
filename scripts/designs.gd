class_name Designs
extends RefCounted
## Preset builds. Each part entry is [part id, finish, params].

const MatsLib := preload("res://scripts/mats.gd")

const PRESETS := [
	["Patrol Carbine", "ar", "556", "fmj", 36.8, "Black", {"barrel": ["brl_gov"], "trigger": ["trig_sel"], "grip": ["gr_a2"], "stock": ["stk_m4"], "mag": ["mag_std", "Flat Dark Earth"], "handguard": ["hg_mlok", "Black", {"len": 33.0}], "muzzle": ["mz_a2"], "optic": ["opt_reddot"], "under": ["ub_agrip"], "side": ["sd_peq", "Flat Dark Earth"]}],
	["Desert Recce", "ar", "556", "match", 45.7, "Flat Dark Earth", {"barrel": ["brl_med"], "trigger": ["trig_match", "Black"], "grip": ["gr_ergo", "Black"], "stock": ["stk_crane", "Flat Dark Earth"], "mag": ["mag_std", "Black"], "handguard": ["hg_mlok", "Flat Dark Earth", {"len": 38.0}], "muzzle": ["mz_supp", "Flat Dark Earth"], "optic": ["opt_lpvo", "Black"], "under": ["ub_bipod"]}],
	["Quiet Professional", "ar", "300blk", "subsonic", 22.9, "Ranger Green", {"barrel": ["brl_gov"], "trigger": ["trig_flat", "Crimson"], "grip": ["gr_ergo", "Black"], "stock": ["stk_pdw", "Black"], "mag": ["mag_std", "Black"], "handguard": ["hg_mlok", "Ranger Green", {"len": 20.0}], "muzzle": ["mz_supp_long", "Ranger Green"], "optic": ["opt_holo", "Black"], "under": ["ub_stop", "Black"]}],
	["Kalash Classic", "ak", "762x39", "fmj", 41.5, "Parkerized", {"barrel": ["brl_gov"], "trigger": ["trig_sel"], "grip": ["gr_ak_wood", "Walnut"], "stock": ["stk_ak_wood", "Walnut"], "mag": ["mag_std", "Bronze"], "handguard": ["hg_ak_wood", "Walnut"], "muzzle": ["mz_akbrake"], "optic": ["opt_irons"]}],
	["Modern Kalash", "ak", "545", "fmj", 41.5, "Black", {"barrel": ["brl_gov"], "trigger": ["trig_sel"], "grip": ["gr_ergo"], "stock": ["stk_crane"], "mag": ["mag_std", "Crimson"], "handguard": ["hg_ak_mlok", "Black"], "muzzle": ["mz_comp"], "optic": ["opt_holo"], "under": ["ub_vgrip"]}],
	["Battle Rifle", "ar10", "762x51", "fmj", 50.8, "OD Green", {"barrel": ["brl_med"], "trigger": ["trig_sel"], "grip": ["gr_a2"], "stock": ["stk_a2", "OD Green"], "mag": ["mag_std"], "handguard": ["hg_quad", "Black", {"len": 38.0}], "muzzle": ["mz_3prong"], "optic": ["opt_acog"], "under": ["ub_vgrip"]}],
	["Marksman DMR", "ar10", "65cm", "match", 55.9, "Sniper Grey", {"barrel": ["brl_fluted"], "trigger": ["trig_match", "Black"], "grip": ["gr_target", "Black"], "stock": ["stk_prs", "Sniper Grey"], "mag": ["mag_std"], "handguard": ["hg_carbon", "Carbon Fiber", {"len": 38.0}], "muzzle": ["mz_brake", "Black"], "optic": ["opt_525", "Black"], "under": ["ub_bipod"]}],
	["Bullpup Assault", "bullpup", "556", "fmj", 45.7, "OD Green", {"barrel": ["brl_gov"], "trigger": ["trig_three"], "mag": ["mag_std", "Black"], "handguard": ["hg_bp_long", "OD Green"], "muzzle": ["mz_a2"], "optic": ["opt_holomag", "Black"], "under": ["ub_agrip", "Black"]}],
	["Squad Automatic", "lmg", "556", "fmj", 46.5, "Black", {"barrel": ["brl_heavy"], "trigger": ["trig_auto"], "grip": ["gr_a2"], "stock": ["stk_lmg"], "mag": ["belt_200", "OD Green"], "handguard": ["hg_lmg"], "muzzle": ["mz_a2"], "optic": ["opt_irons"], "under": ["ub_bipod"]}],
	["Precision Bolt", "bolt", "338lm", "match", 68.6, "Sniper Grey", {"barrel": ["brl_fluted"], "trigger": ["trig_match"], "grip": ["gr_target", "Black"], "stock": ["stk_chassis", "Sniper Grey"], "mag": ["mag_std", "Black"], "handguard": ["hg_arca", "Sniper Grey", {"len": 40.0}], "muzzle": ["mz_brake", "Black"], "optic": ["opt_525", "Black"], "under": ["ub_bipod"]}],
	["Deer Hunter", "bolt", "3006", "hp", 61.0, "Blued Steel", {"barrel": ["brl_gov"], "trigger": ["trig_match"], "stock": ["stk_hunter", "Walnut"], "mag": ["mag_short", "Blued Steel"], "optic": ["opt_39", "Black"]}],
	["Magnum Hunter", "bolt", "300wm", "match", 66.0, "Stainless", {"barrel": ["brl_carbon", "Carbon Fiber"], "trigger": ["trig_match"], "stock": ["stk_thumb", "Laminate"], "mag": ["mag_short", "Black"], "muzzle": ["mz_brake", "Stainless"], "optic": ["opt_525", "Black"], "under": ["ub_bipod"]}],
	["Big Fifty", "amr", "50bmg", "fmj", 73.7, "Flat Dark Earth", {"barrel": ["brl_fluted"], "trigger": ["trig_std"], "grip": ["gr_a2", "Black"], "stock": ["stk_amr"], "mag": ["mag_std"], "handguard": ["hg_amr"], "muzzle": ["mz_50brake"], "optic": ["opt_10x", "Black"], "under": ["ub_bipod"]}],
	["Service Pistol", "striker", "9mm", "fmj", 10.2, "Black", {"barrel": ["brl_pistol"], "trigger": ["trig_std"], "mag": ["mag_std"]}],
	["Competition Race Gun", "striker", "9mm", "match", 12.7, "Cobalt", {"barrel": ["brl_pistol_thr", "Gold"], "trigger": ["trig_flat", "Gold"], "mag": ["mag_ext", "Cobalt"], "muzzle": ["mz_pcomp", "Gold"], "optic": ["opt_minidot", "Black"]}],
	["Classic .45", "hammer", "45acp", "fmj", 12.7, "Blued Steel", {"barrel": ["brl_pistol"], "trigger": ["trig_match"], "grip": ["pnl_wood", "Walnut"], "mag": ["mag_std"]}],
	["Machine Pistol", "mpistol", "9mm", "fmj", 11.4, "Black", {"barrel": ["brl_pistol_thr"], "trigger": ["trig_sel"], "mag": ["mag_quad"], "muzzle": ["mz_pcomp"], "stock": ["stk_brace"], "optic": ["opt_minidot"], "under": ["ub_laser"]}],
	["Magnum Revolver", "revolver", "357", "hp", 15.2, "Stainless", {"barrel": ["brl_rev"], "trigger": ["trig_std"], "grip": ["rg_rubber", "Black"]}],
	["Hand Cannon", "revolver", "500sw", "fmj", 21.6, "Chrome", {"barrel": ["brl_rev_vent"], "trigger": ["trig_match"], "grip": ["rg_wood", "Mahogany"], "optic": ["opt_prism", "Black"]}],
	["Roller SMG", "smg", "9mm", "fmj", 22.5, "Black", {"barrel": ["brl_gov"], "trigger": ["trig_three"], "grip": ["gr_a2"], "stock": ["stk_smg_wire", "Parkerized"], "mag": ["mag_std"], "handguard": ["hg_smg_wide"], "optic": ["opt_irons"]}],
	["Suppressed SMG", "smg", "9mm", "subsonic", 14.6, "Black", {"barrel": ["brl_gov"], "trigger": ["trig_three"], "grip": ["gr_ergo"], "stock": ["stk_smg_fixed"], "mag": ["mag_std"], "handguard": ["hg_smg_rail"], "muzzle": ["mz_oil"], "optic": ["opt_reddot"], "side": ["sd_light"]}],
	["Compact PDW", "pdw", "57", "ap", 16.5, "Graphite", {"barrel": ["brl_gov"], "trigger": ["trig_sel"], "grip": ["gr_ergo"], "stock": ["stk_pdw"], "mag": ["mag_std"], "handguard": ["hg_mlok", "Graphite", {"len": 15.0}], "muzzle": ["mz_supp_pistol"], "optic": ["opt_holo"], "under": ["ub_agrip"]}],
	["Riot Pump", "pump", "12ga", "buck", 47.0, "Parkerized", {"barrel": ["brl_sg"], "trigger": ["trig_std"], "stock": ["stk_sg_syn"], "mag": ["tube_6"], "handguard": ["hg_pump_syn"], "muzzle": ["ch_cyl"], "optic": ["opt_irons"], "side": []}],
	["Tactical Pump", "pump", "12ga", "buck", 35.6, "Black", {"barrel": ["brl_sg_rib"], "trigger": ["trig_std"], "stock": ["stk_m4"], "grip": ["gr_ergo"], "mag": ["tube_4"], "handguard": ["hg_pump_rail"], "muzzle": ["ch_breach"], "optic": ["opt_reddot"], "under": ["ub_light"]}],
	["Drum Shotgun", "autoshotgun", "12ga", "buck", 48.0, "Black", {"barrel": ["brl_sg"], "trigger": ["trig_sel"], "grip": ["gr_ergo"], "stock": ["stk_ak_poly"], "mag": ["mag_drum"], "handguard": ["hg_ak_quad"], "muzzle": ["ch_mod"], "optic": ["opt_holo"], "under": ["ub_vgrip"]}],
	["Coach Gun", "double", "12ga", "buck", 50.8, "Blued Steel", {"barrel": ["brl_sg"], "trigger": ["trig_std"], "stock": ["stk_sg_wood", "Walnut"], "handguard": ["hg_dbl", "Walnut"], "muzzle": ["ch_mod"]}],
	["Brush Gun", "lever", "4570", "fmj", 45.7, "Blued Steel", {"barrel": ["brl_gov"], "trigger": ["trig_std"], "stock": ["stk_lever", "Walnut"], "mag": ["tube_6"], "handguard": ["hg_lev_wood", "Walnut"], "optic": ["opt_irons"]}],
	["Thumper", "gl", "40mm", "he", 30.0, "Flat Dark Earth", {"barrel": ["brl_gl"], "trigger": ["trig_std"], "grip": ["gr_a2", "Black"], "stock": ["stk_m4", "Flat Dark Earth"], "optic": ["opt_holo", "Black"]}],
	["Master Key", "ar", "556", "fmj", 36.8, "Woodland Camo", {"barrel": ["brl_gov"], "trigger": ["trig_sel", "Black"], "grip": ["gr_a2", "Black"], "stock": ["stk_m4", "Woodland Camo"], "mag": ["mag_drum", "Black"], "handguard": ["hg_quad", "Black", {"len": 33.0}], "muzzle": ["mz_3prong"], "optic": ["opt_acog", "Black"], "under": ["ub_gl", "Black"]}],
	["Golden Gun", "hammer", "45acp", "plusp", 12.7, "Gold", {"barrel": ["brl_pistol_thr", "Chrome"], "trigger": ["trig_match"], "grip": ["pnl_ivory", "Bone White"], "mag": ["mag_ext", "Gold"], "muzzle": ["mz_pcomp", "Gold"]}],
]


static func names() -> Array:
	var out := []
	for p in PRESETS:
		out.append(p[0])
	return out


static func preset(nm: String) -> Dictionary:
	for p in PRESETS:
		if p[0] == nm:
			var b := {"rcv": p[1], "cal": p[2], "ammo": p[3], "blen": p[4], "fin": p[5], "name": p[0], "parts": {}}
			for slot in p[6]:
				var e: Array = p[6][slot]
				if e.is_empty():
					continue
				var d := Parts.get_part(e[0])
				var params := {}
				for k in d.get("p", {}):
					params[k] = d.p[k][3]
				if e.size() > 2:
					params.merge(e[2], true)
				b.parts[slot] = {"id": e[0], "f": e[1] if e.size() > 1 else d.fin, "p": params}
			Gun.validate(b)
			return b
	return Gun.new_build("ar")


## A random but valid gun: random platform, caliber, parts, paint.
static func random_build() -> Dictionary:
	var rcvs := Parts.RCV.keys()
	var rid: String = rcvs[randi() % rcvs.size()]
	var b := Gun.new_build(rid)
	var r: Dictionary = Parts.RCV[rid]
	b.cal = r.cals[randi() % r.cals.size()]
	var ammo := Cal.ammo_for(b.cal)
	b.ammo = ammo[randi() % ammo.size()]
	b.blen = snappedf(randf_range(r.blen[0], r.blen[1]), 0.5)
	var fins: Array = MatsLib.FINISHES.keys()
	b.fin = fins[randi() % fins.size()]
	b.parts = {}
	for slot in Parts.SLOTS:
		var opts := Parts.options(rid, slot)
		if opts.is_empty():
			continue
		if not Parts.required(rid, slot) and randf() < 0.25:
			continue
		var pick: String = opts[randi() % opts.size()]
		var d := Parts.get_part(pick)
		var params := {}
		for k in d.get("p", {}):
			var spec: Array = d.p[k]
			params[k] = snappedf(randf_range(spec[0], spec[1]), spec[2])
		var f: String = d.fin if randf() < 0.6 else fins[randi() % fins.size()]
		b.parts[slot] = {"id": pick, "f": f, "p": params}
	b.name = "Random " + r.name
	Gun.validate(b)
	return b

class_name Models
extends RefCounted
## Procedural models for every receiver and part. Authored in centimetres
## (helpers convert to metres). Each builder returns an MK.PB with geometry per
## (group, role), sockets for child slots and anchor points.
##
## Roles: "main" takes the part's paint; the rest are fixed materials (see Mats).
## Groups: "" is static; "bolt", "slide", "charge", "cyl", "hammer", "lever",
## "handle" are animated by weapon.gd around the pivot in info.pivots.

const CM := 0.01


# ------------------------------------------------------------------ helpers
static func v(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z) * CM


static func pv(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, a.size(), 2):
		out.append(Vector2(a[i], a[i + 1]) * CM)
	return out


static func T(x := 0.0, y := 0.0, z := 0.0, rot := Vector3.ZERO) -> Transform3D:
	return MK.xf(v(x, y, z), rot)


## Centred rounded box, sizes in cm.
static func bx(st: SurfaceTool, sx: float, sy: float, sz: float, x: float, y: float, z: float, r := 0.15, rot := Vector3.ZERO) -> void:
	MK.box(st, Vector3(sx, sy, sz) * CM, T(x, y, z, rot), r * CM, minf(r, sx * 0.3) * CM)


## Side profile (cm pairs) extruded `w` cm wide around x.
static func ex(st: SurfaceTool, a: Array, w: float, x := 0.0, bevel := 0.15, t := Transform3D.IDENTITY) -> void:
	MK.extrude(st, pv(a), w * CM, t, bevel * CM, x * CM)


static func exv(st: SurfaceTool, p: PackedVector2Array, w: float, x := 0.0, bevel := 0.15, t := Transform3D.IDENTITY) -> void:
	MK.extrude(st, p, w * CM, t, bevel * CM, x * CM)


## Lathe of (r, z) cm pairs, rear to front.
static func lt(st: SurfaceTool, a: Array, segs := 18, t := Transform3D.IDENTITY) -> void:
	MK.lathe(st, pv(a), segs, t)


## Cylinder along Z (before rotation), cm.
static func cy(st: SurfaceTool, r: float, l: float, x: float, y: float, z: float, rot := Vector3.ZERO, segs := 16, ch := 0.0) -> void:
	MK.cyl(st, r * CM, l * CM, T(x, y, z, rot), segs, ch * CM)


static func tb(st: SurfaceTool, ro: float, ri: float, l: float, x: float, y: float, z: float, rot := Vector3.ZERO, segs := 16) -> void:
	MK.tube(st, ro * CM, ri * CM, l * CM, T(x, y, z, rot), segs)


static func band(path: Array, th: float) -> PackedVector2Array:
	return MK.band(pv(path), th * CM)


static func rail(st: SurfaceTool, len_cm: float, x: float, y: float, z: float, rot := Vector3.ZERO) -> void:
	MK.rail(st, len_cm * CM, T(x, y, z, rot))


static func trigger_guard(st: SurfaceTool, front_z: float, back_z: float, top_y: float, bot_y: float, w := 1.2) -> void:
	var p := band([front_z, top_y, front_z + 0.4, bot_y + 0.3, front_z + 1.4, bot_y, back_z - 0.8, bot_y, back_z, bot_y + 0.6, back_z, top_y], 0.42)
	exv(st, p, w, 0.0, 0.12)


# ------------------------------------------------------------------ entry
static func build(id: String, p: Dictionary, ctx: Dictionary) -> MK.PB:
	var pb := MK.PB.new()
	pb.info["pivots"] = {}
	if Parts.RCV.has(id):
		match id:
			"striker", "mpistol": _pistol(pb, ctx, false, id == "mpistol")
			"hammer": _pistol(pb, ctx, true, false)
			"revolver": _revolver(pb, ctx)
			"smg": _smg(pb, ctx)
			"pdw": _ar(pb, ctx, 0.9, true)
			"ar": _ar(pb, ctx, 1.0, false)
			"ar10": _ar(pb, ctx, 1.12, false)
			"ak": _ak(pb, ctx, 1.0)
			"autoshotgun": _ak(pb, ctx, 1.12)
			"bullpup": _bullpup(pb, ctx)
			"lmg": _lmg(pb, ctx)
			"bolt": _bolt(pb, ctx)
			"amr": _amr(pb, ctx)
			"pump": _pump(pb, ctx)
			"double": _double(pb, ctx)
			"lever": _lever(pb, ctx)
			"gl": _gl(pb, ctx)
		return pb
	var d := Parts.get_part(id)
	match d.get("slot", ""):
		"barrel": _barrel(pb, id, ctx)
		"muzzle": _muzzle(pb, id, ctx)
		"handguard": _handguard(pb, id, p, ctx)
		"stock": _stock(pb, id, p, ctx)
		"grip": _grip(pb, id, ctx)
		"mag": _mag(pb, id, ctx)
		"optic": _optic(pb, id, ctx)
		"under", "side": _accessory(pb, id, ctx)
		"trigger": _trigger(pb, id)
	return pb


# ================================================================== RECEIVERS
static func _pistol(pb: MK.PB, ctx: Dictionary, steel: bool, machine: bool) -> void:
	var L: float = ctx.blen * 100.0
	var sl := pb.s("main" if steel else "steel", "slide")
	var frame := pb.s("main")
	var w := 2.25 if steel else 2.5
	var front := -L - 0.2
	# Slide: chamfered top, rounded nose.
	ex(sl, [6.6, 1.7, front + 0.6, 1.7, front, 1.1, front, -1.1, 6.6, -1.1], w, 0, 0.45)
	for i in 7:
		bx(pb.s("bore", "slide"), w + 0.04, 2.0, 0.12, 0, 0.5, 5.9 - i * 0.32, 0.03)
		if not steel:
			bx(pb.s("bore", "slide"), w + 0.04, 2.0, 0.12, 0, 0.5, front + 1.0 + i * 0.32, 0.03)
	bx(pb.s("bore", "slide"), 0.9, 0.3, 3.4, 0.55, 1.62, 1.2, 0.1)
	bx(pb.s("steel2", "slide"), 0.6, 0.6, 2.2, 0.62, 1.38, 1.2, 0.1)
	cy(pb.s("bore", "slide"), 0.48, 0.3, 0, 0, front + 0.1, Vector3.ZERO, 14)
	# Native sights: notch rear, post front.
	bx(pb.s("steel", "slide"), 1.8, 0.55, 0.7, 0, 1.95, 5.8, 0.08)
	bx(pb.s("glow_g", "slide"), 0.2, 0.2, 0.05, 0.42, 2.0, 5.44, 0.0)
	bx(pb.s("glow_g", "slide"), 0.2, 0.2, 0.05, -0.42, 2.0, 5.44, 0.0)
	bx(pb.s("steel", "slide"), 0.32, 0.55, 0.5, 0, 1.95, front + 0.9, 0.08)
	bx(pb.s("glow_g", "slide"), 0.18, 0.18, 0.05, 0, 2.05, front + 0.64, 0.0)
	pb.anchor("native_sight", v(0, 2.08, 5.8))
	pb.anchor("native_front", v(0, 2.08, front + 0.9))
	# Frame / dust cover.
	ex(frame, [6.6, -1.1, front + 1.0, -1.1, front + 1.0, -2.75, -2.8, -2.75, -3.6, -2.4, 6.0, -2.4], w - 0.1, 0, 0.35)
	if not steel:
		for i in 4:
			bx(pb.s("bore"), 0.15, 0.25, 0.95, w * 0.5 - 0.02, -2.75, front + 2.2 + i * 1.15, 0.05)
	# Grip (frame-integral). 1911 panels go on via the grip slot.
	var grip := [7.2, -1.2, 8.1, -2.5, 9.7, -11.6, 9.3, -12.7, 3.6, -12.7, 2.9, -11.7, 2.0, -5.0, 1.6, -2.4]
	if steel:
		grip = [7.6, -1.0, 8.6, -2.0, 7.9, -2.5, 9.4, -11.9, 9.1, -12.6, 3.8, -12.6, 3.0, -11.5, 2.1, -4.9, 1.6, -2.4]
	ex(frame, grip, w - 0.05, 0, 0.55 if not steel else 0.3)
	if not steel:
		for i in 9:
			bx(pb.s("bore"), w + 0.02, 0.06, 2.6, 0, -5.0 - i * 0.8, 5.6 + i * 0.12, 0.02, Vector3(0, 0, 0))
	trigger_guard(frame, -3.4, 1.8, -2.5, -5.0, 1.1)
	pb.sock("trigger", v(0, -2.7, -0.6))
	# Magazine inserted up the grip, tilted back.
	pb.sock("mag", v(0, -1.2, 5.3), Vector3(-17 if not steel else -14, 0, 0))
	pb.anchor("magwell", v(0, -12.6, 6.2))
	pb.anchor("grip", v(0, -6.2, 6.0))
	pb.anchor("support", v(-1.6, -7.5, 5.0))
	pb.sock("barrel", v(0, 0, 0))
	pb.sock("optic", v(0, 1.7, 3.6))
	pb.sock("under", v(0, -2.75, front * 0.55 + 0.6))
	pb.sock("grip", Vector3.ZERO)
	if machine:
		pb.sock("stock", v(0, -3.2, 8.4))
		bx(pb.s("steel"), 0.7, 0.9, 1.2, -1.3, 0.0, 4.5, 0.2)
	if steel:
		var hm := pb.s("steel", "hammer")
		pb.info.pivots["hammer"] = v(0, 0.4, 7.2)
		ex(hm, [0, 0, 0.6, 0.2, 1.4, 1.6, 1.0, 1.8, -0.2, 0.6], 0.6, 0, 0.1)
		ex(pb.s("steel"), [7.4, -1.2, 8.9, -1.8, 9.2, -2.6, 8.2, -2.6], 2.0, 0, 0.3)
		bx(pb.s("steel"), 0.5, 0.6, 1.2, 1.25, -0.4, 6.4, 0.1)
	pb.info["sock_group"] = {"optic": "slide"}
	pb.info["eject"] = v(0.8, 1.4, 1.0)
	pb.info["travel"] = 0.034
	pb.info["move"] = "slide"


static func _revolver(pb: MK.PB, ctx: Dictionary) -> void:
	var f := pb.s("main")
	var cl := 5.4 if ctx.cal_id == "500sw" else 4.2
	var cr := 2.15 if ctx.cal_id == "500sw" else 1.95
	var cyl_y := -1.25
	var z1 := 0.25
	var z2 := z1 + cl
	# Frame: top strap, front, bottom, recoil shield, grip frame.
	ex(f, [-0.8, 1.9, z2 + 2.2, 1.9, z2 + 3.2, 0.6, z2 + 3.6, -2.4, z2 + 3.2, -3.4, -0.8, -3.6, -1.0, -2.6, -0.8, -0.8, z1 - 0.1, -0.8, z1 - 0.1, 1.0], 3.0, 0, 0.45)
	# Window cutout look: dark insets each side where the cylinder sits.
	bx(pb.s("bore"), 3.06, 0.1, cl, 0, 1.0, (z1 + z2) * 0.5, 0.05)
	trigger_guard(f, z2 - 2.8, z2 + 2.6, -3.4, -6.0, 1.1)
	pb.sock("trigger", v(0, -3.6, z2 - 0.4))
	# Cylinder with chambers and flutes.
	var cg := pb.s("main", "cyl")
	pb.info.pivots["cyl"] = v(0, cyl_y, (z1 + z2) * 0.5)
	lt(cg, [0, cl * 0.5, cr - 0.3, cl * 0.5, cr, cl * 0.5 - 0.3, cr, -cl * 0.5 + 0.3, cr - 0.3, -cl * 0.5, 0, -cl * 0.5], 24)
	for i in 6:
		var a := TAU * i / 6.0 + PI * 0.5
		var c := Vector2(cos(a), sin(a)) * (cr - 0.85)
		cy(pb.s("bore", "cyl"), 0.5, 0.2, c.x, c.y, -cl * 0.5 - 0.02, Vector3.ZERO, 12)
		var fa := a + PI / 6.0
		var fp := Vector2(cos(fa), sin(fa)) * (cr - 0.05)
		bx(pb.s("bore", "cyl"), 0.5, 0.5, cl * 0.6, fp.x, fp.y, 0.0, 0.25, Vector3(0, 0, rad_to_deg(fa)))
	cy(pb.s("steel", "cyl"), 0.35, 0.6, 0, 0, -cl * 0.5 - 0.3, Vector3.ZERO, 10)
	# Hammer.
	var hm := pb.s("steel", "hammer")
	pb.info.pivots["hammer"] = v(0, -0.2, z2 + 2.6)
	ex(hm, [-0.4, -0.6, 0.6, -0.4, 1.4, 1.6, 2.2, 2.2, 2.0, 2.6, 0.9, 2.1, -0.3, 0.8], 0.75, 0, 0.12)
	# Rear sight notch on the top strap.
	bx(pb.s("steel"), 1.4, 0.5, 1.4, 0, 2.15, z2 + 1.2, 0.1)
	pb.anchor("native_sight", v(0, 2.45, z2 + 1.4))
	pb.sock("barrel", v(0, 0, 0))
	pb.sock("grip", v(0, -2.6, z2 + 3.2))
	pb.sock("optic", v(0, 1.9, z2 - 0.6))
	pb.sock("under", v(0, -3.6, -ctx.blen * 100.0 * 0.5))
	pb.anchor("grip", v(0, -6.8, z2 + 4.6))
	pb.anchor("support", v(-1.4, -7.8, z2 + 3.6))
	pb.anchor("magwell", v(0, cyl_y, z2 + 1.0))
	pb.info["move"] = "cyl"
	pb.info["eject"] = v(0, cyl_y, z2)


static func _ar(pb: MK.PB, ctx: Dictionary, s: float, pdw: bool) -> void:
	var t := MK.xf(Vector3.ZERO, Vector3.ZERO, s)
	var up := pb.s("main")
	var rl := 15.5 if pdw else 18.0
	# Upper receiver.
	ex(up, [0, 2.0, rl, 2.0, rl, 0.4, rl - 0.6, -1.25, 0, -1.25], 2.8, 0, 0.35, t)
	cy(up, 1.65 * s, 1.6 * s, 0, 0, -0.6 * s, Vector3.ZERO, 20, 0.2)
	rail(pb.s("alu"), (rl - 0.6) * s, 0, 2.42 * s, (rl - 0.3) * s)
	# Ejection port, bolt carrier, forward assist, brass deflector.
	bx(pb.s("bore"), 0.1, 1.5 * s, 6.0 * s, 1.42 * s, 0.55 * s, 9.5 * s, 0.1)
	bx(pb.s("steel2", "bolt"), 0.5 * s, 1.2 * s, 5.6 * s, 1.18 * s, 0.55 * s, 9.5 * s, 0.25)
	if not pdw:
		cy(up, 0.75 * s, 2.6 * s, 1.75 * s, 0.7 * s, 14.6 * s, Vector3(0, -35, 0), 12, 0.2)
		cy(pb.s("steel"), 0.55 * s, 0.5 * s, 2.45 * s, 0.7 * s, 13.6 * s, Vector3(0, -35, 0), 12, 0.1)
	ex(up, [12.5 * s, 1.8 * s, 14.0 * s, 1.8 * s, 14.0 * s, -0.4 * s, 13.0 * s, 0.2 * s], 1.2 * s, 1.7 * s, 0.2)
	# Charging handle.
	var ch := pb.s("main", "charge")
	bx(ch, 1.0 * s, 0.6 * s, 5.0 * s, 0, 1.55 * s, (rl - 1.5) * s, 0.15)
	ex(ch, [rl * s, 1.2 * s, (rl + 1.3) * s, 1.2 * s, (rl + 1.4) * s, 1.95 * s, rl * s, 1.95 * s], 4.4 * s, 0, 0.25)
	# Lower receiver with flared magwell.
	var lo := pb.s("main")
	var lr := rl + 1.0
	var mw0 := 2.6 if not pdw else 3.4
	var mw1 := 9.5 if not pdw else 7.6
	var mwd := -7.8 if not pdw else -7.2
	ex(lo, [0.6, -1.2, lr, -1.2, lr, -3.0, lr - 1.5, -3.6, mw1 + 0.5, -3.3, mw1, -3.3, mw1 - 0.3, mwd + 0.4, mw1 - 0.7, mwd, mw0 + 0.2, mwd, mw0 - 0.2, mwd + 0.6, mw0 - 0.3, -3.4, 1.2, -3.0, 0.6, -2.0], 2.7, 0, 0.3, t)
	bx(pb.s("bore"), 2.75 * s, 0.25 * s, (mw1 - mw0 - 0.4) * s, 0, (mwd + 0.25) * s, (mw0 + mw1) * 0.5 * s, 0.05)
	exv(lo, MK.band(pv([(mw1 + 0.2) * s, -3.2 * s, (mw1 + 0.8) * s, -5.6 * s, (lr - 3.2) * s, -5.6 * s, (lr - 3.0) * s, -3.4 * s]), 0.42 * CM), 1.4 * s)
	cy(pb.s("steel"), 0.45 * s, 0.4 * s, 1.5 * s, -2.5 * s, (mw1 + 0.4) * s, Vector3(0, 90, 0), 12)
	bx(pb.s("steel"), 0.4 * s, 1.3 * s, 2.0 * s, -1.45 * s, -1.8 * s, (mw0 + 0.6) * s, 0.15)
	ex(pb.s("steel"), [(lr - 3.0) * s, -1.8 * s, (lr - 1.4) * s, -1.6 * s, (lr - 1.2) * s, -2.2 * s, (lr - 2.8) * s, -2.3 * s], 0.25 * s, -1.45 * s, 0.05)
	pb.sock("trigger", v(0, -3.3, (mw1 + 2.7)) * s)
	pb.sock("barrel", Vector3.ZERO)
	pb.sock("handguard", Vector3.ZERO)
	pb.sock("stock", v(0, -0.2, lr) * s)
	pb.sock("grip", v(0, -3.2, lr - 2.0) * s)
	pb.sock("mag", v(0, -1.6, (mw0 + mw1) * 0.5) * s, Vector3(-4 if pdw else 0, 0, 0))
	pb.sock("optic", v(0, 2.78, (rl * 0.5 - 0.5)) * s)
	pb.anchor("magwell", v(0, mwd, (mw0 + mw1) * 0.5) * s)
	pb.anchor("grip", v(0, -6.5, lr + 0.5) * s)
	pb.anchor("support", v(-1.5, -2.5, -10.0) * s)
	pb.info["eject"] = v(1.5, 0.5, 9.5) * s
	pb.info["travel"] = 0.075 * s
	pb.info["move"] = "bolt"
	pb.info["flat_top"] = true


static func _ak(pb: MK.PB, ctx: Dictionary, s: float) -> void:
	var t := MK.xf(Vector3.ZERO, Vector3.ZERO, s)
	var m := pb.s("main")
	var R := 24.0
	ex(m, [-1.0, 1.4, R, 1.4, R, -1.2, R - 1.0, -3.0, -1.0, -3.0], 3.0, 0, 0.2, t)
	# Domed top cover with ribs.
	ex(m, [2.0, 1.2, R + 0.6, 1.2, R + 0.8, 1.9, R - 1.5, 2.45, 2.4, 2.45], 2.9, 0, 0.75, t)
	for i in 3:
		bx(pb.s("bore"), 3.0 * s, 0.08 * s, 5.0 * s, 0, 2.38 * s, (7.0 + i * 0.01) * s, 0.04)
	# Trunnion + rear sight block.
	ex(m, [-1.0, 2.0, 2.4, 2.0, 2.4, -3.0, -1.0, -3.0], 3.2, 0, 0.25, t)
	ex(pb.s("steel"), [-8.0, 1.0, -1.0, 1.0, -1.0, 2.6, -3.5, 2.7, -8.0, 1.7], 2.0, 0, 0.3, t)
	bx(pb.s("steel"), 1.2 * s, 0.5 * s, 1.0 * s, 0, 2.85 * s, -2.0 * s, 0.1)
	pb.anchor("native_sight", v(0, 3.1, -2.0) * s)
	# Ejection port, reciprocating carrier with charging handle.
	bx(pb.s("bore"), 0.1, 1.7 * s, 7.0 * s, 1.52 * s, 0.4 * s, 12.0 * s, 0.1)
	var bo := pb.s("steel2", "bolt")
	bx(bo, 0.4 * s, 0.9 * s, 7.4 * s, 1.36 * s, 0.6 * s, 12.0 * s, 0.2)
	cy(bo, 0.32 * s, 2.6 * s, 2.4 * s, 0.6 * s, 8.6 * s, Vector3(0, 90, 0), 10)
	cy(pb.s("steel", "bolt"), 0.48 * s, 0.9 * s, 3.6 * s, 0.6 * s, 8.6 * s, Vector3(0, 90, 0), 12, 0.2)
	# Safety lever.
	ex(pb.s("steel"), [10.0, 0.0, R - 3.5, 0.6, R - 3.4, -0.6, 10.0, -0.8, 9.0, -1.8, 8.6, -1.4], 0.22, 1.6 * s, 0.05, t)
	# Magwell + mag catch + trigger guard.
	ex(m, [2.2, -3.0, 9.4, -3.0, 9.4, -3.6, 2.2, -3.6], 3.1, 0, 0.1, t)
	bx(pb.s("steel"), 1.6 * s, 0.6 * s, 0.9 * s, 0, -3.7 * s, 9.9 * s, 0.1)
	exv(pb.s("steel"), MK.band(pv([10.4 * s, -3.0 * s, 10.8 * s, -5.6 * s, 16.4 * s, -5.6 * s, 17.0 * s, -3.0 * s]), 0.45 * CM * s), 1.3 * s)
	pb.sock("trigger", v(0, -3.2, 13.2) * s)
	pb.sock("barrel", Vector3.ZERO)
	pb.sock("handguard", Vector3.ZERO)
	pb.sock("stock", v(0, -0.6, R) * s)
	pb.sock("grip", v(0, -3.0, 18.0) * s)
	pb.sock("mag", v(0, -2.2, 5.8) * s)
	var has_optic: bool = ctx.optic != "" and ctx.optic != "opt_irons"
	if has_optic:
		# Side-mount bridge on the left rail.
		ex(pb.s("alu"), [8.0, -1.0, 18.0, -1.0, 18.0, 3.2, 8.0, 3.2], 0.5, -1.75 * s, 0.1, t)
		ex(pb.s("alu"), [8.0, 2.4, 18.0, 2.4, 18.0, 3.6, 8.0, 3.6], 3.0, -0.4 * s, 0.1, t)
		rail(pb.s("alu"), 10.0 * s, 0, 4.0 * s, 18.0 * s)
	pb.sock("optic", v(0, 4.36, 13.0) * s)
	pb.anchor("magwell", v(0, -9.0, 6.0) * s)
	pb.anchor("grip", v(0, -6.4, 19.0) * s)
	pb.anchor("support", v(-1.5, -3.0, -10.0) * s)
	pb.info["eject"] = v(1.6, 0.5, 12.0) * s
	pb.info["travel"] = 0.1 * s
	pb.info["move"] = "bolt"


static func _smg(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("steel")
	var R := 26.0
	ex(pb.s("main"), [0, 2.0, R, 2.0, R, -1.6, 0, -1.6], 3.0, 0, 0.9)
	# Cocking tube over the barrel, front sight hood.
	cy(m, 0.95, 15.0, 0, 2.1, -7.0, Vector3.ZERO, 14, 0.2)
	tb(m, 1.25, 1.05, 1.6, 0, 3.0, -13.6, Vector3.ZERO, 16)
	bx(m, 0.25, 1.0, 0.25, 0, 3.0, -13.6, 0.03)
	bx(m, 1.2, 1.8, 1.4, 0, 2.2, -13.6, 0.2)
	var ch := pb.s("steel", "charge")
	cy(ch, 0.3, 2.2, -1.9, 2.1, -11.0, Vector3(0, 90, 0), 10)
	cy(ch, 0.45, 0.9, -3.1, 2.1, -11.0, Vector3(0, 90, 0), 12, 0.15)
	# Rear drum sight.
	cy(m, 1.05, 1.8, 0, 3.0, R - 2.8, Vector3(0, 90, 0), 16, 0.2)
	bx(m, 1.6, 1.0, 2.0, 0, 2.3, R - 2.8, 0.1)
	pb.anchor("native_sight", v(0, 3.0, R - 2.8))
	# Ejection port and bolt.
	bx(pb.s("bore"), 0.1, 1.4, 4.0, 1.52, 0.4, 7.0, 0.1)
	bx(pb.s("steel2", "bolt"), 0.4, 1.0, 3.6, 1.36, 0.4, 7.0, 0.2)
	# Polymer trigger pack + magwell.
	var lo := pb.s("main")
	ex(lo, [9.5, -1.4, R - 1.0, -1.4, R - 1.0, -2.6, R - 4.0, -3.4, 12.0, -3.4, 10.2, -2.8], 2.8, 0, 0.4)
	trigger_guard(lo, 12.0, R - 5.4, -3.2, -5.8, 1.6)
	ex(pb.s("steel"), [1.6, -1.4, 7.4, -1.4, 7.2, -5.2, 2.2, -5.2], 2.6, 0, 0.2)
	pb.sock("trigger", v(0, -3.3, 15.2))
	pb.sock("barrel", v(0, 0, 0))
	pb.sock("handguard", Vector3.ZERO)
	pb.sock("stock", v(0, 0.4, R))
	pb.sock("grip", v(0, -3.2, R - 4.2))
	pb.sock("mag", v(0, -1.4, 4.4))
	var has_optic: bool = ctx.optic != "" and ctx.optic != "opt_irons"
	if has_optic:
		bx(pb.s("alu"), 2.2, 1.2, 9.0, 0, 2.6, 12.0, 0.2)
		rail(pb.s("alu"), 9.0, 0, 3.6, 16.5)
	pb.sock("optic", v(0, 3.96, 12.0))
	pb.anchor("magwell", v(0, -9.0, 4.4))
	pb.anchor("grip", v(0, -6.4, R - 3.0))
	pb.anchor("support", v(-1.5, -3.0, -9.0))
	pb.info["eject"] = v(1.5, 0.5, 7.0)
	pb.info["travel"] = 0.045
	pb.info["move"] = "bolt"


static func _bullpup(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("main")
	# Long polymer shell: front grip frame, magwell behind, butt.
	ex(m, [0, 2.0, 30.0, 2.0, 34.0, 1.6, 45.0, 1.4, 45.5, -1.0, 45.0, -11.0, 41.0, -11.0, 34.0, -4.4, 26.0, -4.4, 25.0, -3.2, 11.0, -3.0, 0, -2.6], 4.4, 0, 1.1)
	# Pistol grip + full-hand guard.
	ex(m, [7.4, -2.8, 11.0, -2.8, 12.6, -12.4, 9.4, -12.4, 8.6, -11.0], 2.9, 0, 0.8)
	ex(m, [-0.6, -2.4, 0.8, -2.6, 2.8, -12.2, 8.8, -12.2, 9.6, -11.0, 3.6, -11.0, 1.6, -3.0], 2.0, 0, 0.5)
	bx(pb.s("rubber"), 4.4, 12.2, 1.1, 0, -4.8, 45.8, 0.6)
	ex(pb.s("rubber"), [30.0, 1.9, 42.0, 1.6, 42.0, 0.6, 30.0, 0.8], 4.5, 0, 0.6)
	rail(pb.s("alu"), 25.0, 0, 2.42, 26.0)
	bx(pb.s("bore"), 0.1, 1.6, 6.0, 2.22, 0.4, 28.0, 0.1)
	bx(pb.s("steel2", "bolt"), 0.4, 1.2, 5.4, 2.0, 0.4, 28.0, 0.2)
	var ch := pb.s("steel", "charge")
	bx(ch, 0.6, 0.9, 2.2, -2.5, 1.0, 4.0, 0.2)
	pb.sock("trigger", v(0, -3.0, 4.6))
	pb.sock("barrel", v(0, 0, 27.0))
	pb.sock("handguard", Vector3.ZERO)
	pb.sock("mag", v(0, -2.6, 30.0))
	pb.sock("optic", v(0, 2.78, 14.0))
	pb.anchor("magwell", v(0, -10.0, 30.0))
	pb.anchor("grip", v(0, -7.0, 10.6))
	pb.anchor("support", v(-1.5, -3.6, -6.0))
	pb.anchor("butt", v(0, -4.0, 46.0))
	pb.anchor("cheek", v(0, 2.0, 37.0))
	pb.info["eject"] = v(2.3, 0.4, 28.0)
	pb.info["travel"] = 0.07
	pb.info["move"] = "bolt"
	pb.info["flat_top"] = true


static func _lmg(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var R := 30.0
	ex(m, [-1.0, 2.8, R, 2.8, R, -1.6, R - 1.5, -2.8, -1.0, -2.8], 4.0, 0, 0.3)
	# Feed tray cover (raised, hinged) with rail.
	var fc := pb.s("main", "cover")
	ex(fc, [1.0, 2.6, 17.0, 2.6, 17.0, 4.0, 15.0, 4.6, 1.0, 4.6], 4.1, 0, 0.35)
	rail(pb.s("alu", "cover"), 13.0, 0, 5.02, 15.5)
	bx(pb.s("steel"), 0.6, 0.6, 4.0, 2.2, 0.0, 11.0, 0.15)
	# Feed tray opening on the left, ejection port under the right.
	bx(pb.s("bore"), 0.1, 1.8, 3.0, -2.02, 0.8, 6.0, 0.1)
	bx(pb.s("bore"), 2.0, 0.1, 4.0, 1.0, -2.82, 9.0, 0.1)
	var ch := pb.s("steel", "charge")
	bx(ch, 0.6, 1.2, 2.4, 2.4, 0.6, 7.0, 0.2)
	bx(pb.s("steel2", "bolt"), 1.6, 0.6, 4.0, 1.0, -2.6, 9.0, 0.15)
	ex(m, [17.0, -2.6, 25.0, -2.6, 24.0, -3.8, 18.0, -3.8], 3.0, 0, 0.3)
	trigger_guard(m, 15.2, 23.0, -3.6, -6.0, 1.6)
	pb.sock("trigger", v(0, -3.7, 17.6))
	pb.sock("barrel", Vector3.ZERO)
	pb.sock("handguard", Vector3.ZERO)
	pb.sock("stock", v(0, -0.2, R))
	pb.sock("grip", v(0, -3.6, 23.0))
	pb.sock("mag", v(-1.2, -2.6, 6.0))
	pb.sock("optic", v(0, 5.38, 9.0))
	pb.sock("under", v(0, -2.8, -2.0))
	pb.info["sock_group"] = {"optic": "cover"}
	pb.anchor("magwell", v(-1.2, -8.0, 6.0))
	pb.anchor("grip", v(0, -7.0, 24.5))
	pb.anchor("support", v(-2.0, -3.0, -6.0))
	pb.info["eject"] = v(1.0, -3.0, 9.0)
	pb.info["eject_down"] = true
	pb.info["travel"] = 0.06
	pb.info["move"] = "bolt"


static func _bolt(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var R := 22.0
	lt(m, [0, R, 1.55, R, 1.75, R - 0.3, 1.75, 0.6, 1.5, 0, 0, 0], 22)
	rail(pb.s("alu"), R - 1.0, 0, 2.17, R - 0.5)
	bx(pb.s("bore"), 0.1, 1.5, 6.5, 1.72, 0.5, 9.0, 0.1)
	# Bottom metal, trigger guard, magwell.
	ex(pb.s("steel"), [4.0, -1.4, 19.0, -1.4, 19.0, -2.6, 4.0, -2.6], 2.6, 0, 0.2)
	trigger_guard(pb.s("steel"), 12.0, 18.6, -2.4, -5.0, 1.4)
	pb.sock("trigger", v(0, -2.5, 14.6))
	# Bolt: body + handle (rotates and slides).
	var hd := pb.s("steel2", "handle")
	pb.info.pivots["handle"] = v(0, 0, 17.0)
	cy(hd, 1.3, 9.0, 0, 0, -3.5, Vector3.ZERO, 16, 0.2)
	cy(pb.s("steel", "handle"), 0.3, 4.0, 2.3, -0.6, 0.6, Vector3(0, 90, -15), 10)
	MK.sphere(pb.s("steel", "handle"), 0.95 * CM, T(4.4, -1.2, 0.6), 14, 8)
	cy(pb.s("steel", "handle"), 1.4, 2.5, 0, 0, 2.2, Vector3.ZERO, 16, 0.2)
	pb.sock("barrel", Vector3.ZERO)
	pb.sock("handguard", Vector3.ZERO)
	pb.sock("stock", v(0, -0.6, R))
	pb.sock("grip", v(0, -2.6, 19.4))
	pb.sock("mag", v(0, -2.0, 8.0))
	pb.sock("optic", v(0, 2.53, 11.0))
	pb.anchor("magwell", v(0, -9.0, 8.0))
	pb.anchor("grip", v(0, -6.4, 21.0))
	pb.anchor("support", v(-1.5, -4.0, -18.0))
	pb.anchor("bolt_knob", v(4.4, -1.2, 17.6))
	pb.info["eject"] = v(1.8, 0.5, 9.0)
	pb.info["travel"] = 0.09
	pb.info["move"] = "handle"
	pb.info["flat_top"] = true


static func _amr(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var R := 55.0
	ex(m, [0, 3.2, R - 6.0, 3.2, R, 2.0, R, -1.8, 0, -1.8], 5.2, 0, 0.5)
	ex(m, [8.0, -1.6, 48.0, -1.6, 48.0, -3.8, 40.0, -5.2, 22.0, -5.2, 20.0, -3.8, 8.0, -3.6], 5.0, 0, 0.5)
	ex(m, [9.0, -3.4, 20.0, -3.4, 20.0, -5.4, 9.0, -5.4], 5.4, 0, 0.3)
	rail(pb.s("alu"), 42.0, 0, 3.62, 46.0)
	bx(pb.s("bore"), 0.1, 2.6, 9.0, 2.62, 0.6, 20.0, 0.15)
	bx(pb.s("steel2", "bolt"), 0.6, 2.0, 8.4, 2.3, 0.6, 20.0, 0.3)
	var ch := pb.s("steel", "charge")
	ex(ch, [24.0, 0.0, 30.0, 0.0, 30.0, 1.4, 25.0, 1.4], 1.0, 3.0, 0.3)
	ex(pb.s("steel"), [30.0, -5.0, 39.0, -5.0, 39.5, -8.2, 30.6, -8.2], 0.5, 0, 0.1)
	trigger_guard(m, 29.0, 38.0, -5.0, -8.0, 1.8)
	pb.sock("trigger", v(0, -5.1, 32.0))
	pb.sock("barrel", Vector3.ZERO)
	pb.sock("handguard", Vector3.ZERO)
	pb.sock("stock", v(0, 0.6, R))
	pb.sock("grip", v(0, -5.0, 38.5))
	pb.sock("mag", v(0, -3.4, 14.5))
	pb.sock("optic", v(0, 3.98, 26.0))
	pb.sock("under", v(0, -1.8, 2.0))
	pb.anchor("magwell", v(0, -14.0, 14.5))
	pb.anchor("grip", v(0, -9.0, 40.0))
	pb.anchor("support", v(-2.0, -5.5, 20.0))
	pb.info["eject"] = v(2.7, 0.6, 20.0)
	pb.info["travel"] = 0.1
	pb.info["move"] = "bolt"
	pb.info["flat_top"] = true


static func _pump(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var R := 21.0
	ex(m, [0, 1.4, 2.0, 2.2, R - 2.0, 2.2, R, 1.2, R, -3.2, 0, -3.2], 3.3, 0, 0.9)
	bx(pb.s("bore"), 0.1, 1.6, 5.4, 1.67, 0.6, 7.5, 0.15)
	bx(pb.s("bore"), 1.8, 0.1, 6.0, 0, -3.22, 8.0, 0.15)
	bx(pb.s("steel2", "bolt"), 0.4, 1.2, 5.0, 1.45, 0.6, 7.5, 0.15)
	ex(m, [9.0, -3.0, R - 1.0, -3.0, R - 2.0, -4.4, 10.0, -4.4], 2.6, 0, 0.3)
	trigger_guard(m, 12.0, R - 3.0, -4.2, -6.6, 1.4)
	cy(pb.s("steel"), 0.5, 1.2, 0, -3.7, R - 2.0, Vector3(0, 90, 0), 12)
	pb.sock("trigger", v(0, -4.2, 14.2))
	pb.sock("barrel", v(0, 0, 0))
	pb.sock("mag", v(0, -2.3, 0))
	pb.sock("handguard", v(0, -1.6, -6.0))
	pb.sock("stock", v(0, -0.6, R))
	pb.sock("grip", v(0, -3.6, R - 2.0))
	var has_optic: bool = ctx.optic != "" and ctx.optic != "opt_irons"
	if has_optic:
		rail(pb.s("alu"), 14.0, 0, 2.62, 17.0)
	pb.sock("optic", v(0, 2.98, 10.0))
	pb.anchor("native_sight", v(0, 2.6, 18.0))
	pb.anchor("magwell", v(0, -3.4, 6.0))
	pb.anchor("grip", v(0, -6.4, R + 2.0))
	pb.anchor("support", v(-1.8, -4.2, -16.0))
	pb.info["eject"] = v(1.7, 0.6, 7.5)
	pb.info["travel"] = 0.08
	pb.info["move"] = "pump"


static func _double(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("main")
	ex(m, [0, 1.2, 4.0, 1.4, 9.0, 0.6, 9.0, -2.6, 2.0, -2.8, 0, -2.4], 4.2, 0, 0.6)
	ex(pb.s("steel2"), [1.0, 0.6, 7.0, 0.8, 7.0, -2.0, 1.0, -2.2], 4.3, 0, 0.2)
	bx(pb.s("steel"), 0.6, 0.8, 2.0, 0, 1.4, 6.8, 0.2)
	trigger_guard(pb.s("steel"), 6.0, 12.0, -2.6, -5.2, 1.2)
	pb.sock("trigger", v(0, -2.7, 8.6))
	pb.sock("barrel", Vector3.ZERO)
	pb.sock("handguard", v(0, -1.6, -2.0))
	pb.sock("stock", v(0, -0.4, 9.0))
	pb.anchor("hinge", v(0, -2.2, -0.4))
	pb.anchor("native_sight", v(0, 2.2, 6.0))
	pb.anchor("magwell", v(0, 0.0, 0.0))
	pb.anchor("grip", v(0, -5.4, 13.0))
	pb.anchor("support", v(-1.8, -3.6, -14.0))
	pb.info["eject"] = v(0, 0, 0)
	pb.info["move"] = "break"


static func _lever(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var R := 18.0
	ex(m, [0, 1.6, R - 2.0, 1.6, R, 0.6, R, -2.6, 0, -2.6], 2.6, 0, 0.5)
	ex(pb.s("brass"), [4.0, -0.6, 8.0, -0.6, 8.0, -2.0, 4.0, -2.0], 0.1, 1.32, 0.05)
	bx(pb.s("bore"), 0.1, 1.4, 4.0, 1.32, 0.8, 10.0, 0.15)
	# Lever loop.
	var lv := pb.s("steel", "lever")
	pb.info.pivots["lever"] = v(0, -2.6, 3.0)
	var loop := band([0.2, 0.0, 1.2, -1.6, 5.0, -2.4, 9.0, -2.2, 12.0, -3.2, 13.0, -5.0, 11.0, -6.0, 6.0, -5.6, 3.0, -4.6], 0.6)
	exv(lv, loop, 1.1, 0, 0.15)
	ex(lv, [9.0, -0.2, 14.0, -0.2, 13.0, -1.6, 9.0, -1.4], 1.1, 0, 0.1)
	var hm := pb.s("steel", "hammer")
	pb.info.pivots["hammer"] = v(0, 0.0, R - 1.5)
	ex(hm, [-0.4, -0.6, 0.6, -0.4, 1.2, 1.4, 2.0, 2.0, 1.8, 2.4, 0.8, 1.8, -0.3, 0.6], 0.6, 0, 0.1)
	pb.sock("trigger", v(0, -2.7, 9.0))
	pb.sock("barrel", Vector3.ZERO)
	pb.sock("mag", v(0, -1.7, 0))
	pb.sock("handguard", v(0, -0.6, 0))
	pb.sock("stock", v(0, -0.4, R))
	var has_optic: bool = ctx.optic != "" and ctx.optic != "opt_irons"
	if has_optic:
		rail(pb.s("alu"), 15.0, 0, 2.02, 17.0)
	pb.sock("optic", v(0, 2.38, 9.0))
	pb.anchor("magwell", v(1.4, -1.3, 6.0))
	pb.anchor("grip", v(0, -5.0, R + 4.0))
	pb.anchor("support", v(-1.8, -3.4, -16.0))
	pb.anchor("lever_hand", v(0, -5.0, 10.0))
	pb.info["eject"] = v(0.0, 1.6, 9.0)
	pb.info["eject_up"] = true
	pb.info["move"] = "lever"


static func _gl(pb: MK.PB, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var cyl := pb.s("main", "cyl")
	pb.info.pivots["cyl"] = v(0, -4.4, 8.0)
	lt(cyl, [0, 6.5, 5.8, 6.5, 6.4, 5.9, 6.4, -5.9, 5.8, -6.5, 0, -6.5], 28)
	for i in 6:
		var a := TAU * i / 6.0 + PI * 0.5
		var c := Vector2(cos(a), sin(a)) * 4.4
		cy(pb.s("bore", "cyl"), 2.1, 0.2, c.x, c.y, -6.55, Vector3.ZERO, 16)
		var fa := a + PI / 6.0
		var fp := Vector2(cos(fa), sin(fa)) * 6.3
		bx(pb.s("bore", "cyl"), 0.8, 0.8, 9.0, fp.x, fp.y, 0, 0.3, Vector3(0, 0, rad_to_deg(fa)))
	# Frame plates front and rear with tie rods.
	ex(m, [0.4, 2.6, 1.6, 2.6, 1.6, -11.0, 0.4, -11.0], 6.0, 0, 0.6)
	ex(m, [14.4, 3.0, 18.0, 3.0, 18.0, -6.0, 14.4, -11.0], 6.0, 0, 0.6)
	for k in [-1.0, 1.0]:
		cy(pb.s("steel"), 0.4, 13.0, 2.6 * k, -10.0, 8.0, Vector3.ZERO, 10)
	rail(pb.s("alu"), 16.0, 0, 3.42, 17.0)
	trigger_guard(m, 13.0, 20.0, -6.0, -8.6, 1.6)
	pb.sock("trigger", v(0, -6.0, 15.4))
	pb.sock("barrel", v(0, 0, 1.0))
	pb.sock("stock", v(0, -2.0, 18.0))
	pb.sock("grip", v(0, -6.0, 18.4))
	pb.sock("optic", v(0, 3.78, 8.0))
	pb.sock("under", v(0, -11.0, 0.0))
	pb.anchor("magwell", v(0, -4.4, 14.0))
	pb.anchor("grip", v(0, -10.0, 20.0))
	pb.anchor("support", v(-2.0, -6.0, -12.0))
	pb.info["eject"] = v(0, -4.4, 14.0)
	pb.info["move"] = "cyl"


# ================================================================== BARRELS
static func _gas_len(L: float) -> float:
	if L < 30.0:
		return 12.0
	if L < 42.0:
		return 17.8
	if L < 50.0:
		return 22.9
	return 30.0


static func _barrel(pb: MK.PB, id: String, ctx: Dictionary) -> void:
	var L: float = ctx.blen * 100.0
	var fam: String = ctx.fam
	var st := pb.s("steel")
	var bore := pb.s("bore")
	match id:
		"brl_pistol", "brl_pistol_thr", "brl_pistol_port":
			var ext := 1.4 if id == "brl_pistol_thr" else 0.0
			var bs := pb.s("main") if id == "brl_pistol_thr" else st
			cy(bs, 0.62, L + ext, 0, 0, -(L + ext) * 0.5, Vector3.ZERO, 16)
			cy(bore, 0.46, 0.3, 0, 0, -L - ext + 0.1, Vector3.ZERO, 12)
			if ext > 0.0:
				for i in 5:
					tb(st, 0.66, 0.6, 0.12, 0, 0, -L - 0.25 - i * 0.25, Vector3.ZERO, 14)
			if id == "brl_pistol_port":
				for i in 3:
					bx(pb.s("bore"), 0.35, 0.3, 0.7, 0, 1.68, -L + 0.8 + i * 1.0, 0.1)
			pb.sock("muzzle", v(0, 0, -L - ext))
			pb.info["muzzle_r"] = 0.62
		"brl_rev", "brl_rev_slim", "brl_rev_vent":
			var m := pb.s("main")
			lt(m, [0, 0, 1.05, 0, 0.95, -L * 0.3, 0.9, -L, 0, -L], 18)
			cy(bore, 0.5, 0.3, 0, 0, -L + 0.1, Vector3.ZERO, 12)
			if id != "brl_rev_slim":
				ex(m, [0, -0.6, -L, -0.6, -L, -1.8, -L + 1.0, -2.4, -1.0, -2.4, 0, -2.0], 1.7, 0, 0.6)
			else:
				ex(m, [0, -0.6, -5.0, -0.6, -5.0, -2.0, -4.4, -2.4, -1.0, -2.4, 0, -2.0], 1.4, 0, 0.5)
				cy(st, 0.25, 4.0, 0, -1.7, -3.0, Vector3.ZERO, 8)
			if id == "brl_rev_vent":
				ex(m, [0, 0.8, -L, 0.8, -L, 1.6, 0, 1.6], 1.0, 0, 0.2)
				for i in int(L / 2.0):
					bx(bore, 1.02, 0.5, 0.8, 0, 1.15, -1.5 - i * 2.0, 0.1)
			ex(st, [-L + 1.6, 0.8, -L + 0.4, 0.8, -L + 0.5, 1.9, -L + 1.2, 1.9], 0.4, 0, 0.05)
			pb.anchor("native_front", v(0, 2.0, -L + 1.0))
			pb.sock("muzzle", v(0, 0, -L))
		"brl_sg", "brl_sg_rib", "brl_sg_rifled":
			var xs := [0.0]
			if fam == "double":
				xs = [-1.05, 1.05]
			for x in xs:
				lt(st, [0, 0, 1.45, 0, 1.4, -4.0, 1.12, -10.0, 1.08, -L, 0.92, -L, 0.92, -L + 0.4], 20, T(x))
				cy(bore, 0.92, 0.3, x, 0, -L + 0.12, Vector3.ZERO, 16)
			if fam == "double":
				ex(st, [0, 1.0, -L, 0.95, -L, 0.6, 0, 0.6], 0.8, 0, 0.1)
				ex(st, [-2.0, -0.6, -L + 0.5, -0.6, -L + 0.5, -1.0, -2.0, -1.0], 1.6, 0, 0.1)
			if id == "brl_sg_rib":
				ex(st, [0, 1.6, -L, 1.6, -L, 1.9, 0, 1.9], 0.8, 0, 0.05)
				for i in int(L / 3.0):
					bx(st, 0.3, 0.5, 0.4, 0, 1.35, -1.5 - i * 3.0, 0.05)
			if id == "brl_sg_rifled":
				ex(st, [-L + 2.0, 1.0, -L + 0.4, 1.0, -L + 0.6, 2.4, -L + 1.6, 2.4], 0.5, 0, 0.1)
				ex(st, [-12.0, 1.0, -16.0, 1.0, -16.0, 2.0, -12.0, 2.2], 1.6, 0, 0.2)
			var bead_y := 1.95 if id == "brl_sg_rib" else 1.5
			MK.sphere(pb.s("brass" if id != "brl_sg_rifled" else "glow_g"), 0.22 * CM, T(0, bead_y, -L + 0.8), 10, 6)
			pb.anchor("native_front", v(0, bead_y + 0.2, -L + 0.8))
			if fam == "lever" or fam == "pump":
				pass
			pb.sock("muzzle", v(0, 0, -L))
			pb.info["muzzle_r"] = 1.1
		"brl_gl":
			lt(pb.s("main"), [0, 0, 3.0, 0, 3.0, -2.0, 2.6, -3.0, 2.6, -L, 2.2, -L, 2.2, -L + 1.0], 24)
			cy(bore, 2.2, 0.3, 0, 0, -L + 0.12, Vector3.ZERO, 20)
			for i in 6:
				bx(pb.s("rubber"), 5.4, 5.4, 0.6, 0, 0, -6.0 - i * 3.2, 2.6)
			pb.sock("muzzle", v(0, 0, -L))
			pb.anchor("native_front", v(0, 3.2, -L + 2.0))
			pb.info["muzzle_r"] = 2.6
		_:
			_rifle_barrel(pb, id, ctx, L)


static func _rifle_barrel(pb: MK.PB, id: String, ctx: Dictionary, L: float) -> void:
	var fam: String = ctx.fam
	var big := fam == "amr"
	var r0 := 1.55
	var rm := 0.95
	var rf := 0.75
	match id:
		"brl_pencil": rm = 0.8; rf = 0.68
		"brl_med": rm = 1.1; rf = 0.9
		"brl_heavy", "brl_fluted": rm = 1.35; rf = 1.15
		"brl_bull": rm = 1.5; rf = 1.5; r0 = 1.5
		"brl_carbon": rm = 1.45; rf = 1.4
	if big:
		r0 *= 1.6; rm *= 1.55; rf *= 1.5
	if fam == "smg":
		r0 = 1.0; rm = 0.75; rf = 0.7
	var st := pb.s("steel" if id != "brl_bull" else "main")
	var thread := 1.6
	if id == "brl_carbon":
		lt(st, [0, 0, r0, 0, r0, -4.0, rf * 0.9, -4.5, rf * 0.9, -L + 5.0, 0.7, -L, 0, -L], 16)
		cy(pb.s("main"), rm, L - 10.0, 0, 0, -L * 0.5 + 0.5, Vector3.ZERO, 22, 0.4)
	else:
		lt(st, [0, 0, r0, 0, r0, -3.0, rm, -5.0, rm, -L * 0.45, rf, -L * 0.6, rf, -L + thread, rf * 0.82, -L + thread, rf * 0.82, -L, 0, -L], 20)
	if id == "brl_fluted":
		for i in 6:
			var a := TAU * i / 6.0
			bx(pb.s("bore"), 0.45, 0.45, L * 0.4, cos(a) * (rm - 0.12), sin(a) * (rm - 0.12), -L * 0.28, 0.2, Vector3(0, 0, rad_to_deg(a)))
	cy(pb.s("bore"), rf * 0.35 if not big else 0.66, 0.3, 0, 0, -L + 0.1, Vector3.ZERO, 12)
	# Gas system per family.
	if fam in ["ar", "ar10", "pdw", "lmg", "bullpup"]:
		var gz := -_gas_len(L) * (1.12 if fam == "ar10" else 1.0)
		if -gz < L - 3.0:
			bx(pb.s("steel"), 2.2, 2.6, 2.2, 0, 0.5, gz, 0.3)
			cy(pb.s("steel"), 0.3, -gz, 0, 1.6, gz * 0.5, Vector3.ZERO, 8)
	elif fam == "ak":
		var gz := -L + 11.0
		ex(pb.s("steel"), [gz + 2.5, -1.1, gz - 2.5, -1.1, gz - 2.5, 2.6, gz + 1.0, 2.6], 2.2, 0, 0.3)
		cy(pb.s("steel"), 1.05, -gz - 3.0, 0, 2.0, gz * 0.5 + 1.5, Vector3.ZERO, 14)
		# Front sight block with post and ears.
		var fz := -L + 2.5
		ex(pb.s("steel"), [fz + 1.6, -1.4, fz - 1.4, -1.4, fz - 1.4, 2.0, fz + 1.6, 2.0], 2.0, 0, 0.3)
		for x in [-0.9, 0.9]:
			ex(pb.s("steel"), [fz + 0.6, 2.0, fz - 0.6, 2.0, fz - 0.4, 4.0, fz + 0.4, 4.0], 0.35, x, 0.08)
		bx(pb.s("steel"), 0.2, 1.6, 0.2, 0, 3.4, fz, 0.02)
		pb.anchor("native_front", v(0, 4.1, fz))
	elif fam == "lever":
		ex(pb.s("steel"), [-L + 2.0, 0.6, -L + 0.4, 0.6, -L + 0.6, 2.1, -L + 1.6, 2.1], 0.35, 0, 0.05)
		ex(pb.s("steel"), [-7.0, 0.6, -10.0, 0.6, -10.0, 1.5, -7.0, 1.7], 1.6, 0, 0.2)
		pb.anchor("native_front", v(0, 2.15, -L + 1.0))
	pb.sock("muzzle", v(0, 0, -L))
	pb.anchor("fsight_b", v(0, rf, -L + 3.0))
	pb.info["muzzle_r"] = rf


# ================================================================== MUZZLE
static func _muzzle(pb: MK.PB, id: String, ctx: Dictionary) -> void:
	var st := pb.s("steel")
	var bore := pb.s("bore")
	var end := 5.0
	match id:
		"mz_a2":
			lt(st, [0, 0.6, 1.05, 0.6, 1.1, -4.4, 0.95, -4.6, 0.6, -4.6, 0.6, -4.2], 18)
			for i in 5:
				var a := PI * 0.3 + i * PI * 0.35
				bx(bore, 0.38, 0.38, 2.6, cos(a) * 1.0, sin(a) * 1.0, -2.6, 0.15, Vector3(0, 0, rad_to_deg(a)))
			end = 4.6
		"mz_3prong":
			lt(st, [0, 0.6, 1.0, 0.6, 1.05, -1.8, 0, -1.8], 16)
			for i in 3:
				var a := PI * 0.5 + TAU * i / 3.0
				bx(st, 0.55, 0.45, 3.4, cos(a) * 0.82, sin(a) * 0.82, -3.4, 0.15, Vector3(0, 0, rad_to_deg(a)))
			end = 5.1
		"mz_brake":
			ex(pb.s("main"), [0.4, 1.2, -6.0, 1.2, -6.4, 0.6, -6.4, -1.2, 0.4, -1.2], 2.6, 0, 0.5)
			for i in 4:
				bx(bore, 2.66, 1.0, 0.6, 0, 0, -1.4 - i * 1.3, 0.2)
			end = 6.4
		"mz_akbrake":
			lt(st, [0, 0.6, 1.0, 0.6, 1.0, -4.0, 0, -4.0], 16)
			ex(bore, [-2.8, 1.02, -4.0, 0.2, -4.0, 1.02], 2.1, 0, 0.05)
			bx(bore, 0.4, 0.4, 0.4, 0.95, 0.3, -1.6, 0.15)
			end = 4.0
		"mz_comp":
			lt(pb.s("main"), [0, 0.6, 1.25, 0.6, 1.25, -5.4, 1.0, -5.8, 0.6, -5.8], 18)
			for i in 3:
				bx(bore, 1.0, 0.5, 0.6, 0, 1.12, -1.6 - i * 1.3, 0.2)
			end = 5.8
		"mz_linear":
			lt(pb.s("main"), [0, 0.6, 1.4, 0.6, 1.6, -0.6, 1.6, -6.0, 1.1, -6.4, 0.7, -6.4], 20)
			end = 6.4
		"mz_supp", "mz_supp_long", "mz_supp_pistol", "mz_oil", "mz_sgsupp":
			var d := Parts.get_part(id)
			var l: float = d.get("len", 0.15) * 100.0
			var r := 2.0
			if id == "mz_supp_pistol":
				r = 1.75
			elif id == "mz_sgsupp":
				r = 2.6
			elif id == "mz_oil":
				r = 2.2
			lt(pb.s("main"), [0, 0.6, r - 0.4, 0.6, r, 0.0, r, -l + 0.4, r - 0.45, -l, 0.6, -l], 22)
			tb(st, r + 0.04, r - 0.2, 0.6, 0, 0, -l + 0.9, Vector3.ZERO, 22)
			tb(st, r + 0.04, r - 0.2, 0.5, 0, 0, -0.9, Vector3.ZERO, 22)
			if id == "mz_oil":
				for i in int(l / 2.5):
					tb(pb.s("main"), r + 0.15, r - 0.3, 0.5, 0, 0, -1.8 - i * 2.5, Vector3.ZERO, 22)
			cy(bore, 0.5, 0.2, 0, 0, -l - 0.02, Vector3.ZERO, 12)
			end = l
		"mz_50brake":
			ex(pb.s("main"), [0.6, 2.2, -11.0, 2.2, -11.6, 1.2, -11.6, -2.2, 0.6, -2.2], 5.2, 0, 0.8)
			for i in 2:
				bx(bore, 5.26, 2.8, 2.6, 0, 0, -3.2 - i * 4.6, 0.6)
			end = 11.6
		"mz_pcomp":
			ex(pb.s("main"), [1.0, 1.7, -3.2, 1.7, -3.6, 1.2, -3.6, -1.1, 1.0, -1.1], 2.3, 0, 0.45)
			for i in 2:
				bx(bore, 0.6, 0.3, 0.8, 0, 1.72, -1.0 - i * 1.3, 0.1)
			end = 3.6
		"ch_cyl", "ch_mod", "ch_full":
			var l2: float = {"ch_cyl": 1.6, "ch_mod": 2.4, "ch_full": 3.0}[id]
			lt(st, [0, 0.0, 1.2, 0.0, 1.25, -l2 + 0.4, 1.1, -l2, 0.85, -l2], 18)
			tb(pb.s("main"), 1.27, 1.15, 0.6, 0, 0, -l2 + 0.6, Vector3.ZERO, 18)
			end = l2
		"ch_breach":
			lt(st, [0, 0.0, 1.35, 0.0, 1.35, -6.0, 0.85, -6.0], 18)
			for i in 6:
				var a := TAU * i / 6.0
				bx(st, 0.6, 0.5, 1.2, cos(a) * 1.15, sin(a) * 1.15, -6.4, 0.1, Vector3(0, 0, rad_to_deg(a)))
				bx(bore, 0.5, 0.5, 1.4, cos(a + 0.5) * 1.3, sin(a + 0.5) * 1.3, -2.4, 0.15, Vector3(0, 0, rad_to_deg(a)))
			end = 7.0
	pb.anchor("muzzle_end", v(0, 0, -end))


# ================================================================== HANDGUARDS
static func _hg_len(p: Dictionary, ctx: Dictionary, def: float) -> float:
	var L: float = ctx.blen * 100.0
	return clampf(p.get("len", def), 8.0, maxf(8.0, L - 2.0))


static func _handguard(pb: MK.PB, id: String, p: Dictionary, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var bore := pb.s("bore")
	var s := 1.12 if ctx.fam == "ar10" else 1.0
	match id:
		"hg_classic":
			var l := minf(_hg_len({}, ctx, 17.8), 30.0)
			cy(pb.s("steel"), 1.8, 1.6, 0, 0, -0.8, Vector3.ZERO, 18)
			lt(m, [0, -1.6, 2.4, -1.6, 2.6, -2.6, 2.6, -l + 1.0, 2.2, -l, 0, -l], 20)
			for i in int(l / 1.6):
				tb(bore, 2.62, 2.4, 0.35, 0, 0, -3.0 - i * 1.6, Vector3.ZERO, 20)
			tb(pb.s("steel"), 2.0, 1.0, 1.0, 0, 0, -l - 0.3, Vector3.ZERO, 16)
			_hg_socks(pb, l, 2.6, 2.7, false)
		"hg_quad":
			var l := _hg_len(p, ctx, 33.0)
			lt(m, [0, 0.0, 2.6 * s, 0.0, 2.6 * s, -l, 0, -l], 4, T(0, 0, 0, Vector3(0, 0, 45)))
			for a in [0.0, 90.0, 180.0, 270.0]:
				var b := Basis.from_euler(Vector3(0, 0, deg_to_rad(a)))
				var up := b * Vector3(0, 1, 0)
				MK.rail(pb.s("alu"), l * CM, MK.xf(up * 1.84 * s * CM, Vector3(0, 0, a)))
			_hg_socks(pb, l, 2.5 * s, 2.25 * s, true)
		"hg_mlok", "hg_keymod", "hg_vent":
			var l := _hg_len(p, ctx, 33.0)
			var r := 2.2 * s
			lt(m, [0, 0.0, r, 0.0, r, -l + 0.3, r - 0.3, -l, 0, -l], 8, T(0, 0, 0, Vector3(0, 0, 22.5)))
			rail(pb.s("main"), l - 0.6, 0, r * 0.95, -0.3)
			for a in [90.0, 225.0, 270.0, 315.0, 135.0]:
				var b := Basis.from_euler(Vector3(0, 0, deg_to_rad(a)))
				var t := Transform3D(b, Vector3.ZERO) * T(0, r * 0.93, 0)
				for i in int((l - 4.0) / 4.0):
					var sz := Vector3(0.75, 0.12, 3.2) if id == "hg_mlok" else (Vector3(0.6, 0.12, 1.4) if id == "hg_keymod" else Vector3(1.2, 0.12, 3.4))
					MK.box(bore, sz * CM, t * T(0, 0, -2.6 - i * 4.0), 0.3 * CM, 0.03 * CM)
					if id == "hg_keymod":
						MK.box(bore, Vector3(0.9, 0.12, 0.9) * CM, t * T(0, 0, -3.6 - i * 4.0), 0.4 * CM, 0.03 * CM)
			_hg_socks(pb, l, r + 0.05, r + 0.05, true)
		"hg_carbon":
			var l := _hg_len(p, ctx, 33.0)
			cy(pb.s("alu"), 2.3, 2.0, 0, 0, -1.0, Vector3.ZERO, 20, 0.2)
			lt(m, [0, -2.0, 2.15, -2.0, 2.15, -l, 0, -l], 22)
			rail(pb.s("alu"), 12.0, 0, 2.15, -2.0)
			tb(pb.s("alu"), 2.25, 2.0, 1.2, 0, 0, -l + 0.4, Vector3.ZERO, 20)
			_hg_socks(pb, l, 2.15, 2.15, true)
		"hg_ak_wood", "hg_ak_poly":
			var l := 18.0
			ex(m, [-0.5, -0.6, -l, -0.6, -l - 0.5, -1.4, -l, -3.2, -2.0, -3.4, -0.5, -2.8], 4.2, 0, 1.6)
			ex(m, [-1.5, 1.2, -l + 1.0, 1.2, -l + 1.5, 2.0, -l + 1.0, 3.1, -1.5, 3.1], 3.1, 0, 1.2)
			for i in 3:
				bx(bore, 4.25, 0.25, 0.6, 0, -1.6, -5.0 - i * 3.0, 0.1)
			ex(pb.s("steel"), [0.0, 1.2, -1.6, 1.2, -1.6, -3.2, 0.0, -3.2], 4.3, 0, 0.2)
			_hg_socks(pb, l, 3.2, 2.2, false, -0.6)
		"hg_ak_quad", "hg_ak_mlok":
			var l := 22.0
			ex(m, [-0.5, -0.8, -l, -0.8, -l, -3.4, -0.5, -3.4], 4.4, 0, 0.6)
			ex(m, [-1.5, 1.2, -l + 2.0, 1.2, -l + 2.0, 3.1, -1.5, 3.1], 3.2, 0, 0.5)
			rail(pb.s("alu"), l - 4.0, 0, 3.5, -2.0)
			if id == "hg_ak_quad":
				rail(pb.s("alu"), l - 1.0, 0, -3.4, -0.5, Vector3(0, 0, 180))
				for x in [-1.0, 1.0]:
					rail(pb.s("alu"), l - 4.0, 2.2 * x, -1.6, -2.0, Vector3(0, 0, -90 * x))
			else:
				for i in int(l / 4.5):
					bx(bore, 4.46, 0.8, 3.0, 0, -2.2, -2.8 - i * 4.5, 0.3)
			_hg_socks(pb, l, 3.4, 2.3, false, -1.0)
		"hg_smg_slim", "hg_smg_wide", "hg_smg_rail":
			var l := 16.0
			var w := 3.4 if id == "hg_smg_slim" else 4.6
			ex(m, [-0.5, 1.3, -l, 1.3, -l - 0.4, 0.4, -l, -2.6, -0.5, -2.8], w, 0, 1.2 if id != "hg_smg_rail" else 0.3)
			if id == "hg_smg_rail":
				rail(pb.s("alu"), l - 1.0, 0, -2.8, -0.5, Vector3(0, 0, 180))
				for x in [-1.0, 1.0]:
					rail(pb.s("alu"), l - 4.0, w * 0.5 * x, -0.6, -2.0, Vector3(0, 0, -90 * x))
			else:
				for i in 6:
					bx(bore, w + 0.04, 0.22, 1.2, 0, -1.0, -3.0 - i * 2.0, 0.08)
			_hg_socks(pb, l, 2.8, w * 0.5, false, -0.6)
		"hg_pump_syn", "hg_pump_wood", "hg_pump_rail":
			var l := 18.0
			ex(m, [0, 0.8, -l, 0.8, -l - 0.4, 0.0, -l - 0.4, -2.0, -l, -2.8, 0, -2.8], 4.6, 0, 1.6)
			for i in 7:
				bx(bore, 4.66, 0.22, 0.7, 0, -1.0, -2.6 - i * 2.2, 0.08)
			if id == "hg_pump_rail":
				rail(pb.s("alu"), l - 2.0, 0, -2.8, -1.0, Vector3(0, 0, 180))
			_hg_socks(pb, l, 2.8, 2.3, false, -1.0)
			pb.anchor("support", v(-1.6, -3.6, -9.0))
		"hg_lev_wood", "hg_lev_mlok":
			var l := 24.0
			ex(m, [0, 0.4, -l, 0.4, -l - 0.6, -0.8, -l, -2.4, 0, -2.6], 3.6, 0, 1.4)
			if id == "hg_lev_wood":
				tb(pb.s("steel"), 1.9, 1.7, 1.0, 0, -0.9, -l + 0.6, Vector3.ZERO, 16)
			else:
				rail(pb.s("alu"), l - 4.0, 0, -2.6, -2.0, Vector3(0, 0, 180))
			if id == "hg_lev_mlok":
				for i in int(l / 4.5):
					bx(bore, 3.66, 0.8, 3.0, 0, -1.2, -2.6 - i * 4.5, 0.3)
			_hg_socks(pb, l, 2.6, 1.8, false)
		"hg_arca":
			var l := _hg_len(p, ctx, 38.0)
			ex(m, [0, 0.6, -l, 0.6, -l - 0.3, -3.8, -l + 0.4, -4.4, 0, -4.4], 5.0, 0, 0.8)
			for i in int(l / 5.0) - 1:
				bx(bore, 5.06, 1.6, 3.0, 0, -1.8, -3.4 - i * 5.0, 0.6)
			ex(pb.s("alu"), [0, -4.4, -l + 0.5, -4.4, -l + 0.5, -5.2, 0, -5.2], 3.8, 0, 0.2)
			pb.sock("under", v(0, -5.2, -l * 0.75))
			pb.anchor("support", v(-1.4, -5.6, -l * 0.5))
		"hg_amr":
			var l := 34.0
			lt(m, [0, 0.0, 3.6, 0.0, 3.6, -l, 0, -l], 20)
			for i in int(l / 4.0) - 1:
				for a in [0.0, 60.0, 120.0, 180.0, 240.0, 300.0]:
					var b := Basis.from_euler(Vector3(0, 0, deg_to_rad(a)))
					MK.box(bore, Vector3(1.4, 0.12, 2.4) * CM, Transform3D(b, Vector3.ZERO) * T(0, 3.55, -2.6 - i * 4.0), 0.6 * CM, 0.03 * CM)
			rail(pb.s("alu"), l - 4.0, 0, -3.6, -2.0, Vector3(0, 0, 180))
			_hg_socks(pb, l, 3.6, 3.6, false)
			pb.sock("under", v(0, -3.9, -l * 0.8))
		"hg_lmg":
			var l := 20.0
			ex(m, [0, 1.8, -l, 1.8, -l - 0.6, 0.4, -l, -3.4, 0, -3.4], 5.0, 0, 1.0)
			for i in 6:
				bx(bore, 5.06, 0.3, 1.4, 0, -1.2, -2.6 - i * 2.8, 0.1)
			var hdl := band([-12.0, 1.8, -13.0, 7.0, -21.0, 7.0, -22.0, 1.8], 1.2)
			exv(pb.s("steel"), hdl, 1.2, 0, 0.3)
			_hg_socks(pb, l, 3.4, 2.5, false)
		"hg_bp_short", "hg_bp_long":
			var l := 8.0 if id == "hg_bp_short" else 20.0
			if id == "hg_bp_long":
				lt(m, [0, 0.0, 2.4, 0.0, 2.4, -l, 0, -l], 8, T(0, 0, 0, Vector3(0, 0, 22.5)))
				rail(pb.s("alu"), l - 1.0, 0, 2.3, -0.5)
				for x in [-1.0, 1.0]:
					rail(pb.s("alu"), l - 6.0, 2.3 * x, 0, -3.0, Vector3(0, 0, -90 * x))
				_hg_socks(pb, l, 2.4, 2.4, true)
			else:
				ex(m, [1.0, -1.6, -l, -1.6, -l, -2.6, 1.0, -2.6], 3.0, 0, 0.3)
				rail(pb.s("alu"), l, 0, -2.6, 1.0, Vector3(0, 0, 180))
				pb.sock("under", v(0, -3.0, -l * 0.5))
				pb.anchor("support", v(-1.4, -3.8, -l * 0.5))
		"hg_dbl", "hg_dbl_beaver":
			var l := 22.0 if id == "hg_dbl" else 26.0
			var w := 3.6 if id == "hg_dbl" else 5.0
			ex(m, [0, 0.0, -l, 0.0, -l - 0.5, -0.8, -l, -2.2, 0, -2.4], w, 0, 1.4)
			pb.anchor("support", v(-1.6, -3.0, -l * 0.5))


static func _hg_socks(pb: MK.PB, l: float, under_r: float, side_r: float, top_rail: bool, y0 := 0.0) -> void:
	pb.sock("under", v(0, y0 - under_r, -l * 0.62))
	pb.sock("side", v(side_r, y0, -l * 0.8), Vector3(0, 0, 90))
	pb.anchor("support", v(-1.4, y0 - under_r - 1.2, -l * 0.5))
	if top_rail:
		pb.anchor("fsight", v(0, under_r + 0.0, -l + 2.0))


# ================================================================== STOCKS
static func _buffer_tube(pb: MK.PB, len_cm := 18.0) -> void:
	var st := pb.s("alu")
	lt(st, [0, len_cm, 1.4, len_cm, 1.5, len_cm - 0.3, 1.5, 1.0, 1.7, 0.6, 1.7, 0.0, 0, 0.0], 18)
	tb(pb.s("steel"), 1.85, 1.5, 0.8, 0, 0, 1.2, Vector3.ZERO, 16)


static func _stock(pb: MK.PB, id: String, p: Dictionary, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var bore := pb.s("bore")
	var rub := pb.s("rubber")
	var lop: float = p.get("lop", 4.0)
	var butt := Vector3.ZERO
	match id:
		"stk_m4", "stk_crane":
			_buffer_tube(pb)
			var z := 3.0 + lop
			ex(m, [z, 1.9, z + 14.0, 2.3, z + 16.0, 2.3, z + 16.0, -11.0, z + 14.6, -11.4, z + 8.0, -3.8, z, -2.0], 4.0 if id == "stk_m4" else 4.6, 0, 0.8)
			bx(rub, 4.2, 13.4, 1.2, 0, -4.4, z + 16.5, 0.5)
			if id == "stk_crane":
				for x in [-2.6, 2.6]:
					cy(m, 1.1, 10.0, x, -0.4, z + 9.0, Vector3.ZERO, 14, 0.3)
			else:
				bx(bore, 4.1, 1.0, 1.0, 0, -2.4, z + 11.0, 0.3)
			butt = v(0, -4.2, z + 17.0)
			pb.anchor("cheek", v(0, 2.2, z + 8.0))
		"stk_a2", "stk_lmg":
			ex(m, [0, 1.8, 24.0, 2.6, 25.0, 2.6, 25.0, -12.0, 23.0, -12.4, 8.0, -3.6, 0, -2.0], 4.2, 0, 1.0)
			if id == "stk_lmg":
				bx(bore, 4.26, 4.0, 8.0, 0, -3.4, 16.0, 1.5)
				tb(pb.s("steel"), 1.0, 0.7, 0.6, 0, -9.0, 20.0, Vector3(90, 0, 0), 12)
			bx(rub, 4.3, 14.6, 1.0, 0, -4.7, 25.4, 0.5)
			butt = v(0, -4.6, 26.0)
			pb.anchor("cheek", v(0, 2.4, 12.0))
		"stk_prs":
			_buffer_tube(pb, 10.0)
			var ck: float = p.get("cheek", 1.0)
			ex(m, [1.0, 1.0, 26.0, 1.4, 26.0, -12.0, 24.0, -12.0, 18.0, -4.6, 10.0, -3.6, 1.0, -2.0], 4.0, 0, 0.6)
			ex(pb.s("main"), [8.0, 1.6 + ck, 20.0, 1.6 + ck, 20.0, 0.8, 8.0, 0.8], 3.6, 0, 0.6)
			for x in [-1.0, 1.0]:
				cy(pb.s("steel"), 0.3, ck + 1.0, x * 1.2, 1.0 + ck * 0.5, 10.0, Vector3(90, 0, 0), 8)
			bx(rub, 4.2, 14.0, 1.2, 0, -5.0, 26.6, 0.5)
			cy(pb.s("steel"), 0.6, 4.0, 0, -10.0, 20.0, Vector3(90, 0, 0), 12)
			butt = v(0, -5.0, 27.2)
			pb.anchor("cheek", v(0, 2.0 + ck, 14.0))
		"stk_skel":
			_buffer_tube(pb, 14.0)
			for path in [[2.0, 1.4, 18.0, 2.0], [18.0, 2.4, 18.0, -10.0], [2.0, -1.6, 17.0, -10.0]]:
				exv(m, band(path, 1.1), 3.4, 0, 0.4)
			bx(rub, 3.6, 13.0, 1.0, 0, -4.0, 18.6, 0.4)
			butt = v(0, -4.0, 19.0)
		"stk_pdw":
			for x in [-1.6, 1.6]:
				cy(pb.s("steel"), 0.45, 10.0 + lop, x, -0.6, (10.0 + lop) * 0.5, Vector3.ZERO, 10)
			ex(m, [9.0 + lop, 2.4, 11.0 + lop, 2.4, 11.0 + lop, -9.0, 9.0 + lop, -9.0], 4.4, 0, 0.6)
			bx(rub, 4.4, 11.0, 0.8, 0, -3.3, 11.4 + lop, 0.4)
			butt = v(0, -3.3, 11.8 + lop)
		"stk_brace", "stk_brace_p":
			_buffer_tube(pb, 16.0)
			ex(m, [4.0, 2.2, 17.0, 2.2, 17.0, -2.2, 4.0, -2.2], 4.4, 0, 1.4)
			for x in [-1.0, 1.0]:
				ex(rub, [6.0, 0.0, 17.0, 0.0, 17.0, -5.0, 8.0, -4.0], 0.5, 2.3 * x, 0.2)
			butt = v(0, -1.0, 17.4)
		"stk_ak_wood", "stk_ak_poly", "stk_sidefold":
			if id == "stk_sidefold":
				for path in [[0.0, 0.6, 22.0, -0.6], [22.0, -0.6, 22.0, -12.0], [1.0, -2.0, 21.0, -11.0]]:
					exv(m, band(path, 1.4), 3.0, 0, 0.5)
				bx(rub, 3.4, 12.6, 1.0, 0, -6.2, 22.6, 0.4)
				butt = v(0, -6.2, 23.0)
			else:
				ex(m, [0, 0.8, 3.0, 1.0, 24.0, -1.2, 25.0, -1.2, 25.0, -13.0, 23.0, -13.6, 8.0, -4.8, 0, -2.4], 4.0, 0, 1.1)
				ex(pb.s("steel"), [25.0, -0.8, 25.8, -0.8, 25.8, -13.4, 25.0, -13.6], 4.1, 0, 0.3)
				bx(pb.s("steel"), 1.6, 0.6, 3.0, 0, 0.6, 1.6, 0.2)
				butt = v(0, -7.0, 26.0)
			pb.anchor("cheek", v(0, 0.6, 10.0))
		"stk_underfold":
			for x in [-1.6, 1.6]:
				exv(pb.s("main"), band([0.0, -1.0, 23.0, -2.6, 23.0, -11.0], 0.9), 0.5, x, 0.15)
			ex(pb.s("main"), [22.6, -2.4, 24.0, -2.4, 24.0, -11.4, 22.6, -11.4], 3.8, 0, 0.4)
			butt = v(0, -7.0, 24.4)
		"stk_smg_fixed":
			ex(m, [0, 1.6, 22.0, 2.2, 23.0, 2.2, 23.0, -10.4, 21.0, -10.8, 9.0, -3.4, 0, -1.8], 4.0, 0, 1.2)
			bx(rub, 4.1, 12.6, 0.8, 0, -4.1, 23.4, 0.5)
			butt = v(0, -4.1, 23.8)
		"stk_smg_wire":
			for x in [-1.8, 1.8]:
				cy(pb.s("main"), 0.4, 18.0, x, 0.0, 9.0, Vector3.ZERO, 10)
			ex(pb.s("main"), [17.0, 1.8, 19.0, 1.8, 19.0, -9.4, 17.0, -9.4], 4.2, 0, 0.6)
			bx(rub, 4.2, 10.6, 0.6, 0, -3.8, 19.4, 0.4)
			butt = v(0, -3.8, 19.8)
		"stk_hunter", "stk_thumb":
			# Full stock: forend under the barrel, receiver bedding, grip, butt.
			var fe := -60.0
			ex(m, [fe, -0.8, -22.0, -0.8, -21.0, -1.6, 0.0, -1.6, 2.0, 0.4, 10.0, 2.4 if id == "stk_hunter" else 2.8, 32.0, 1.4, 33.0, 1.4, 33.0, -13.0, 31.0, -13.6, 10.0, -6.0, 6.0, -5.6, 5.4, -11.6, 1.6, -11.6, -2.0, -5.0, -14.0, -5.0, -24.0, -4.4, fe + 2.0, -3.6, fe, -2.4], 4.4, 0, 1.3)
			bx(pb.s("bore"), 4.46, 0.2, 9.0, 0, -3.6, -6.0, 0.1)
			if id == "stk_thumb":
				ex(pb.s("bore"), [6.0, -1.8, 9.0, -2.6, 9.0, -5.0, 6.0, -5.4, 4.6, -3.6], 4.46, 0, 0.2)
			if id == "stk_hunter":
				for i in 6:
					bx(pb.s("bore"), 4.46, 0.15, 3.0, 0, -6.0 - i * 0.6, 3.6, 0.05, Vector3(-25, 0, 0))
			bx(rub, 4.4, 14.6, 1.4, 0, -5.8, 33.7, 0.6)
			cy(pb.s("steel"), 0.5, 0.6, 0, -2.4, -48.0, Vector3(90, 0, 0), 10)
			butt = v(0, -5.8, 34.4)
			pb.anchor("wrist", v(0, -6.0, 3.8))
			pb.anchor("cheek", v(0, 2.2, 14.0))
			pb.anchor("support", v(-1.4, -4.6, -38.0))
			pb.sock("under", v(0, -2.8, -52.0))
		"stk_chassis":
			var ck: float = p.get("cheek", 1.5)
			ex(m, [0, 0.8, 4.0, 0.8, 4.0, -2.2, 0, -2.2], 3.2, 0, 0.3)
			for path in [[4.0, 0.0, 28.0, 0.6], [5.0, -2.0, 27.0, -11.0]]:
				exv(m, band(path, 1.6), 2.8, 0, 0.4)
			ex(m, [26.0, 1.4, 28.6, 1.4, 28.6, -12.6, 26.0, -12.6], 3.4, 0, 0.5)
			ex(m, [10.0, 1.4 + ck, 22.0, 1.4 + ck, 22.0, 0.2, 10.0, 0.2], 3.4, 0, 0.6)
			bx(rub, 3.6, 14.0, 1.0, 0, -5.6, 29.1, 0.5)
			cy(pb.s("steel"), 0.5, 4.0, 0, -12.0, 22.0, Vector3(90, 0, 0), 12)
			butt = v(0, -5.6, 29.6)
			pb.anchor("cheek", v(0, 1.6 + ck, 15.0))
		"stk_sg_wood", "stk_sg_syn", "stk_lever":
			var straight := id == "stk_lever"
			if straight:
				ex(m, [0, 1.0, 2.0, 0.6, 34.0, -1.6, 35.0, -1.6, 35.0, -13.4, 33.0, -13.8, 8.0, -4.6, 0, -3.4], 4.0, 0, 1.2)
				ex(pb.s("steel"), [35.0, -1.4, 35.8, -1.8, 36.0, -8.0, 35.6, -13.6, 35.0, -13.6], 4.0, 0, 0.3)
				butt = v(0, -7.0, 36.0)
				pb.anchor("wrist", v(0, -4.0, 5.0))
			else:
				ex(m, [0, 1.2, 2.0, 0.8, 34.0, -0.6, 35.0, -0.6, 35.0, -14.0, 33.0, -14.4, 10.0, -6.8, 7.0, -7.4, 5.4, -8.2, 3.0, -6.2, 0, -3.4], 4.2, 0, 1.3)
				bx(rub, 4.4, 14.0, 1.6, 0, -7.3, 35.7, 0.6)
				butt = v(0, -7.3, 36.6)
				pb.anchor("wrist", v(0, -5.6, 4.4))
			pb.anchor("cheek", v(0, 0.6, 14.0))
		"stk_amr":
			ex(m, [0, 2.2, 22.0, 2.2, 24.0, 1.0, 24.0, -14.0, 20.0, -14.0, 14.0, -6.0, 0, -6.0], 4.6, 0, 0.8)
			ex(pb.s("bore"), [6.0, -0.8, 16.0, -0.8, 13.0, -4.6, 6.0, -4.6], 4.66, 0, 0.6)
			bx(rub, 5.0, 16.0, 2.0, 0, -6.0, 25.0, 0.8)
			cy(pb.s("steel"), 0.7, 8.0, 0, -16.0, 18.0, Vector3(90, 0, 0), 12)
			butt = v(0, -6.0, 26.0)
			pb.anchor("cheek", v(0, 2.4, 12.0))
	pb.anchor("butt", butt)


# ================================================================== GRIPS
static func _grip(pb: MK.PB, id: String, ctx: Dictionary) -> void:
	var m := pb.s("main")
	match id:
		"gr_a2", "gr_ergo", "gr_vert", "gr_ak_poly", "gr_target":
			var pts := [0.2, 0.2, 3.4, 0.2, 5.6, -10.4, 5.0, -11.2, 1.9, -11.2, 1.1, -9.6, 1.6, -7.6, 0.8, -6.6, 1.2, -4.6, -0.3, -1.0]
			if id == "gr_vert":
				pts = [0.2, 0.2, 3.4, 0.2, 4.2, -10.6, 3.6, -11.2, 0.8, -11.2, 0.2, -9.6, 0.2, -1.0]
			elif id == "gr_ak_poly":
				pts = [0.2, 0.2, 3.0, 0.2, 5.4, -10.0, 4.8, -10.8, 2.0, -10.8, 1.2, -9.4, -0.2, -1.0]
			elif id == "gr_target":
				pts = [0.2, 0.2, 3.6, 0.2, 5.0, -4.0, 6.4, -9.6, 5.8, -11.4, 1.6, -11.4, 1.2, -10.4, 2.6, -10.0, 1.4, -6.0, -0.2, -1.0]
			ex(m, pts, 3.0 if id != "gr_ergo" else 3.3, 0, 1.0)
			if id == "gr_ergo":
				for i in 6:
					bx(pb.s("rubber"), 3.36, 0.5, 2.0, 0, -3.0 - i * 1.2, 2.4 + i * 0.4, 0.2, Vector3(-17, 0, 0))
			if id == "gr_target":
				ex(m, [3.0, -3.0, 6.0, -3.6, 6.0, -4.4, 3.0, -4.0], 1.4, 2.0, 0.3)
			pb.anchor("grip", v(0, -5.6, 2.6))
		"gr_ak_wood":
			ex(m, [0.2, 0.2, 3.0, 0.2, 5.2, -10.2, 4.6, -11.0, 1.9, -11.0, 1.0, -9.6, -0.2, -1.0], 2.8, 0, 1.0)
			pb.anchor("grip", v(0, -5.6, 2.4))
		"gr_skel":
			for path in [[0.4, 0.0, 4.8, -10.6], [3.0, 0.0, 5.6, -10.6], [1.0, -10.8, 5.6, -10.8]]:
				exv(m, band(path, 1.0), 2.6, 0, 0.3)
			pb.anchor("grip", v(0, -5.6, 2.6))
		"pnl_wood", "pnl_g10", "pnl_ivory":
			var pnl := [7.3, -2.8, 9.2, -11.8, 8.8, -12.3, 3.9, -12.3, 3.2, -11.3, 2.4, -5.0, 3.0, -3.0]
			for x in [-1.18, 1.18]:
				ex(m, pnl, 0.3, x, 0.12)
				if id == "pnl_wood":
					for i in 5:
						bx(pb.s("bore"), 0.32, 0.12, 4.4, x, -5.0 - i * 1.2, 5.6 + i * 0.25, 0.03, Vector3(-14, 0, 0))
				cy(pb.s("steel"), 0.35, 0.2, x + 0.1 * signf(x), -4.0, 6.2, Vector3(0, 90, 0), 10)
				cy(pb.s("steel"), 0.35, 0.2, x + 0.1 * signf(x), -10.6, 7.6, Vector3(0, 90, 0), 10)
			pb.anchor("grip", v(0, -6.2, 6.0))
		"rg_rubber", "rg_wood", "rg_bird":
			var pts := [0.0, 0.0, 2.6, 1.0, 4.4, -2.0, 5.6, -9.8, 4.6, -11.4, 0.6, -11.4, -0.4, -10.0, 0.4, -8.4, -0.4, -7.0, 0.4, -5.4, -0.4, -4.0, -0.8, -1.6]
			if id == "rg_wood":
				pts = [0.0, 0.0, 2.6, 1.0, 4.6, -2.0, 5.8, -10.4, 4.8, -11.6, 0.4, -11.6, -0.6, -9.0, -0.8, -1.6]
			elif id == "rg_bird":
				pts = [0.0, 0.0, 2.6, 1.0, 4.0, -2.0, 4.6, -6.4, 5.4, -8.4, 3.8, -9.2, 0.6, -8.0, -0.6, -5.0, -0.8, -1.6]
			ex(pb.s("main"), pts, 3.4, 0, 1.2)
			pb.anchor("grip", v(0, -4.6, 2.0))


# ================================================================== MAGAZINES
static func _mag(pb: MK.PB, id: String, ctx: Dictionary) -> void:
	var tag: String = ctx.mag_tag
	var cap: int = ctx.cap
	var c: Dictionary = ctx.cal
	var m := pb.s("main")
	var depth: float = c.cl * 0.1 + 0.6
	var cw: float = c.cw * 0.1
	match tag:
		"tube", "ltube":
			var L: float = ctx.blen * 100.0
			var tl := minf(L - 2.0, 6.0 + cap * c.cl * 0.1 * 1.05) if id != "tube_8" else L + 6.0
			lt(pb.s("steel"), [0, 0, 1.15, 0, 1.15, -tl + 0.4, 1.0, -tl, 0, -tl], 18)
			cy(pb.s("main" if id == "tube_8" else "steel"), 1.25, 1.6, 0, 0, -tl + 0.4, Vector3.ZERO, 18, 0.3)
			if id == "tube_8" and L > 0.0:
				bx(pb.s("steel"), 1.4, 4.0, 1.4, 0, 1.2, -L + 1.0, 0.3)
			return
		"belt":
			if id != "mag_std":
				var big := id == "belt_200"
				var h := 12.0 if big else 9.0
				var bs := pb.s("main") if big else pb.s("main")
				ex(bs, [-5.0, 0.0, 6.0, 0.0, 6.0, -h, -5.0, -h], 7.0 if big else 6.0, -3.0, 0.6 if big else 1.6)
				bx(pb.s("steel"), 7.2, 0.4, 0.8, -3.0, -h + 2.0, 0, 0.1)
				for i in 8:
					cy(pb.s("brass"), cw * 0.5, 2.4, -0.6 + i * 0.25, 0.6 + i * 0.3, -1.0 + i * 0.1, Vector3(0, 90, 0), 8)
				pb.anchor("magwell_l", v(-3.0, -h, 0))
				return
	if tag in ["pistol", "pistol1"]:
		var single := tag == "pistol1"
		var w := cw + (0.5 if single else 1.6)
		var gl: float = 10.6 + {"mag_short": -1.2, "mag_std": 0.0, "mag_ext": 1.8, "mag_quad": 12.0, "mag_drum": 0.0}.get(id, 0.0)
		ex(pb.s("steel"), [-depth * 0.5, 0, depth * 0.5, 0, depth * 0.5, -gl, -depth * 0.5, -gl], w, 0, 0.3)
		ex(m, [-depth * 0.5 - 0.3, -gl, depth * 0.5 + 0.3, -gl, depth * 0.5 + 0.2, -gl - 0.8, -depth * 0.5 - 0.4, -gl - 0.8], w + 0.4, 0, 0.3)
		if id == "mag_drum":
			cy(m, 4.6, 4.2, 0, -gl - 4.6, 0, Vector3(0, 90, 0), 24, 0.6)
			cy(pb.s("steel"), 1.0, 4.4, 0, -gl - 4.6, 0, Vector3(0, 90, 0), 14, 0.2)
		cy(pb.s("brass"), cw * 0.45, depth - 0.8, 0, -0.5, 0, Vector3.ZERO, 10)
		return
	# Box magazines: curved double-stack bodies.
	var dbl := tag not in ["bolt"]
	var w := cw * (1.65 if dbl else 1.05) + 0.35
	if tag == "box12":
		w = cw + 0.6
	var per := cw * (0.5 if dbl else 1.0) * 0.97
	var L := 3.0 + cap * per
	var curve: float = c.taper * L * L * 0.012
	if id == "mag_quad":
		L = 3.0 + cap * per * 0.5
		w *= 1.7
	if id == "mag_drum":
		L = 9.0
		curve = 0.0
	if tag in ["bolt", "amr"]:
		curve = 0.0
		L = 2.0 + cap * per * (0.55 if tag == "amr" else 0.6)
	var path := []
	var n := 8
	for i in n + 1:
		var t := float(i) / n
		path.append(-curve * t * t)
		path.append(-t * L)
	var body := band(path, depth)
	exv(m, body, w, 0, 0.35)
	# Ribs, witness holes, baseplate.
	for i in 3:
		var t2 := 0.3 + i * 0.22
		bx(pb.s("bore"), w + 0.04, 0.25, depth * 0.6, 0, -t2 * L, -curve * t2 * t2, 0.08)
	var endz := -curve
	var a := atan2(-2.0 * curve, L)
	bx(pb.s("steel" if tag != "ak" else "main"), w + 0.5, 0.8, depth + 0.7, 0, -L - 0.2, endz, 0.25, Vector3(rad_to_deg(-a), 0, 0))
	if id == "mag_drum":
		var dr := 6.0 if tag != "box12" else 7.5
		if tag == "smg" or tag == "pistol":
			dr = 5.0
		cy(m, dr, w * 1.9, 0, -L - dr + 1.0, endz, Vector3(0, 90, 0), 28, 0.8)
		cy(pb.s("steel"), dr * 0.25, w * 2.0, 0, -L - dr + 1.0, endz, Vector3(0, 90, 0), 14, 0.2)
		if tag == "stanag" or tag == "smg":
			cy(m, dr, w * 1.9, 0, -L - dr + 1.0, endz, Vector3(0, 90, 0), 28, 0.8)
	cy(pb.s("brass"), cw * 0.45, depth - 1.0, 0, 0.1, 0, Vector3.ZERO, 10)


# ================================================================== OPTICS
static func _ring_mount(pb: MK.PB, h: float, z0: float, z1: float, r: float) -> void:
	for z in [z0, z1]:
		ex(pb.s("alu"), [z - 1.0, 0.0, z + 1.0, 0.0, z + 0.8, h, z - 0.8, h], 2.4, 0, 0.3)
		tb(pb.s("alu"), r + 0.35, r - 0.02, 1.8, 0, h, z, Vector3.ZERO, 22)


static func _scope_body(pb: MK.PB, h: float, len: float, obj_r: float, eye_r: float, tube_r: float, turrets: bool) -> void:
	var m := pb.s("main")
	var hz := len * 0.5
	var t := T(0, h, 0)
	lt(m, [0.0, hz, eye_r - 0.3, hz, eye_r, hz - 0.4, eye_r, hz - 6.0, tube_r, hz - 9.0, tube_r, -hz + 9.0, obj_r, -hz + 4.0, obj_r, -hz + 0.3, obj_r - 0.4, -hz, 0.0, -hz], 26, t)
	MK.cyl(pb.s("lens"), (obj_r - 0.35) * CM, 0.1 * CM, t * T(0, 0, -hz - 0.02), 22)
	MK.cyl(pb.s("lens"), (eye_r - 0.4) * CM, 0.1 * CM, t * T(0, 0, hz + 0.02), 20)
	for i in 4:
		tb(pb.s("rubber"), eye_r + 0.03, eye_r - 0.1, 0.25, 0, h, hz - 1.2 - i * 0.9, Vector3.ZERO, 22)
	if turrets:
		cy(m, 1.5, 2.6, 0, h + tube_r + 0.9, -1.0, Vector3(90, 0, 0), 18, 0.3)
		cy(m, 1.5, 2.6, tube_r + 0.9, h, -1.0, Vector3(0, 90, 0), 18, 0.3)
		for i in 10:
			var a := TAU * i / 10.0
			bx(pb.s("bore"), 0.12, 2.0, 0.12, cos(a) * 1.52, h + tube_r + 1.0, -1.0 + sin(a) * 1.52, 0.02)
		cy(m, 1.3, 2.0, -tube_r - 0.6, h, -1.0, Vector3(0, 90, 0), 16, 0.3)
		cy(m, 1.8, 0.8, 0, h, hz - 9.5, Vector3.ZERO, 22, 0.2)


static func _optic(pb: MK.PB, id: String, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var sight := Vector3.ZERO
	match id:
		"opt_irons":
			if ctx.native_irons:
				pb.info["native"] = true
				return
			# Flip-up aperture rear (front post is added at the handguard/barrel).
			ex(m, [-1.4, 0.0, 1.6, 0.0, 1.6, 1.0, -1.4, 1.0], 2.3, 0, 0.3)
			ex(m, [-0.4, 0.8, 0.8, 0.8, 0.6, 3.2, -0.2, 3.2], 1.8, 0, 0.3)
			tb(pb.s("steel"), 0.6, 0.18, 0.4, 0, 3.6, 0.2, Vector3.ZERO, 16)
			sight = v(0, 3.6, 0.2)
			pb.info["rear_y"] = 3.6
		"opt_reddot":
			ex(pb.s("alu"), [-2.6, 0.0, 2.6, 0.0, 2.2, 1.2, -2.2, 1.2], 2.4, 0, 0.3)
			ex(pb.s("alu"), [-1.8, 1.0, 1.8, 1.0, 1.4, 2.4, -1.4, 2.4], 1.4, 0, 0.3)
			var h := 3.9
			lt(m, [1.75, 3.2, 1.95, 3.0, 1.95, -3.0, 1.75, -3.2, 1.6, -3.2, 1.6, 3.2], 24, T(0, h, 0))
			MK.cyl(pb.s("glass"), 1.6 * CM, 0.05 * CM, T(0, h, -2.8), 22)
			cy(m, 0.9, 1.2, 0, h + 2.4, 0.0, Vector3(90, 0, 0), 16, 0.2)
			cy(m, 0.9, 1.2, 2.4, h, 0.0, Vector3(0, 90, 0), 16, 0.2)
			MK.sphere(pb.s("glow"), 0.035 * CM, T(0, h, -2.6), 8, 4)
			sight = v(0, h, 3.2)
			pb.info["reticle"] = v(0, h, -2.6)
		"opt_minidot":
			ex(pb.s("alu"), [-2.2, 0.0, 2.2, 0.0, 2.2, 0.8, -2.2, 0.8], 2.4, 0, 0.3)
			var hood := band([1.6, 0.8, 1.4, 2.6, 0.0, 3.0, -1.6, 2.6, -1.8, 0.8], 0.45)
			exv(m, hood, 2.4, 0, 0.2)
			MK.box(pb.s("glass"), Vector3(2.0, 1.9, 0.08) * CM, T(0, 1.8, -1.5, Vector3(-12, 0, 0)), 0.3 * CM, 0.0)
			MK.sphere(pb.s("glow"), 0.03 * CM, T(0, 1.8, -1.45), 8, 4)
			sight = v(0, 1.8, 1.0)
			pb.info["reticle"] = v(0, 1.8, -1.45)
		"opt_holo", "opt_holomag":
			ex(m, [-5.0, 0.0, 4.0, 0.0, 4.0, 2.0, -5.0, 2.0], 3.2, 0, 0.4)
			var hood := band([3.6, 1.8, 3.6, 5.4, -3.2, 5.4, -3.2, 1.8], 0.55)
			exv(m, hood, 3.2, 0, 0.2)
			for x in [-1.45, 1.45]:
				ex(m, [3.6, 1.8, -3.2, 1.8, -3.2, 5.4, 3.6, 5.4], 0.3, x, 0.08)
			MK.box(pb.s("glass"), Vector3(2.6, 3.0, 0.08) * CM, T(0, 3.6, -2.9), 0.1 * CM, 0.0)
			MK.box(pb.s("glass"), Vector3(2.6, 3.0, 0.08) * CM, T(0, 3.6, 3.3), 0.1 * CM, 0.0)
			MK.tube(pb.s("glow"), 0.17 * CM, 0.16 * CM, 0.01 * CM, T(0, 3.6, -2.7), 28)
			MK.sphere(pb.s("glow"), 0.012 * CM, T(0, 3.6, -2.7), 6, 3)
			cy(pb.s("steel"), 0.7, 1.5, 1.8, 0.8, -3.8, Vector3(0, 90, 0), 12)
			sight = v(0, 3.6, 3.4)
			pb.info["reticle"] = v(0, 3.6, -2.7)
			if id == "opt_holomag":
				var mz := 9.0
				ex(pb.s("alu"), [mz - 2.0, 0.0, mz + 2.0, 0.0, mz + 1.6, 1.6, mz - 1.6, 1.6], 3.0, 0, 0.3)
				lt(m, [0.0, mz + 5.0, 1.8, mz + 5.0, 1.8, mz - 4.0, 1.5, mz - 5.0, 0.0, mz - 5.0], 22, T(0, 3.6, 0))
				MK.cyl(pb.s("lens"), 1.4 * CM, 0.1 * CM, T(0, 3.6, mz + 5.02), 18)
				sight = v(0, 3.6, 14.0)
		"opt_prism":
			ex(pb.s("alu"), [-3.0, 0.0, 3.0, 0.0, 2.6, 1.0, -2.6, 1.0], 2.6, 0, 0.3)
			ex(m, [-4.2, 1.0, 4.4, 1.0, 4.4, 5.4, -3.0, 5.4, -4.2, 4.6], 3.6, 0, 0.8)
			lt(m, [0.0, -3.6, 2.0, -3.6, 2.0, -6.4, 1.8, -6.8, 0.0, -6.8], 20, T(0, 3.4, 0))
			MK.cyl(pb.s("lens"), 1.7 * CM, 0.1 * CM, T(0, 3.4, -6.85), 18)
			MK.cyl(pb.s("lens"), 1.4 * CM, 0.1 * CM, T(0, 3.4, 4.45), 18)
			sight = v(0, 3.4, 4.5)
		"opt_acog":
			ex(pb.s("alu"), [-4.0, 0.0, 4.0, 0.0, 3.4, 1.2, -3.4, 1.2], 2.6, 0, 0.3)
			lt(m, [0.0, 6.0, 1.6, 6.0, 1.8, 5.0, 2.2, 1.0, 2.2, -3.0, 2.6, -5.0, 2.6, -8.0, 2.2, -8.4, 0.0, -8.4], 24, T(0, 4.0, 0))
			ex(m, [-3.0, 1.0, 3.0, 1.0, 3.0, 2.6, -3.0, 2.6], 3.0, 0, 0.6)
			cy(pb.s("glow"), 0.18, 3.0, 0, 6.4, -1.0, Vector3.ZERO, 8)
			MK.cyl(pb.s("lens"), 2.3 * CM, 0.1 * CM, T(0, 4.0, -8.45), 22)
			MK.cyl(pb.s("lens"), 1.4 * CM, 0.1 * CM, T(0, 4.0, 6.05), 18)
			sight = v(0, 4.0, 6.0)
		"opt_lpvo", "opt_39", "opt_10x", "opt_525":
			var spec: Array = {"opt_lpvo": [27.0, 1.5, 2.1, 1.5, 4.4], "opt_39": [31.0, 2.5, 2.0, 1.27, 4.8], "opt_10x": [31.0, 2.6, 2.0, 1.5, 5.0], "opt_525": [38.0, 3.0, 2.1, 1.7, 5.8]}[id]
			var len: float = spec[0]
			var h: float = spec[4]
			_ring_mount(pb, h, -4.5, 5.5, spec[3])
			_scope_body(pb, h, len, spec[1], spec[2], spec[3], id != "opt_39")
			if id == "opt_525":
				tb(m, 3.05, 2.85, 8.0, 0, h, -len * 0.5 - 3.8, Vector3.ZERO, 26)
			sight = v(0, h, len * 0.5 + 2.0)
	pb.anchor("sight", sight)


# ================================================================== ACCESSORIES
static func _accessory(pb: MK.PB, id: String, ctx: Dictionary) -> void:
	var m := pb.s("main")
	var clamp := func(lz: float) -> void:
		ex(pb.s("alu"), [-lz * 0.5, 0.0, lz * 0.5, 0.0, lz * 0.5, -1.2, -lz * 0.5, -1.2], 2.6, 0, 0.3)
	match id:
		"ub_vgrip":
			clamp.call(4.0)
			lt(m, [0.0, 0.8, 1.6, 0.8, 1.7, -1.0, 1.55, -9.0, 1.3, -10.0, 0.0, -10.0], 18, T(0, -1.0, 0, Vector3(-90, 0, 0)))
			pb.anchor("support", v(-1.2, -6.0, 0))
		"ub_agrip":
			clamp.call(6.0)
			ex(m, [-3.4, -1.0, 3.2, -1.0, 3.8, -2.0, 0.6, -4.2, -2.6, -2.2], 3.0, 0, 0.9)
			pb.anchor("support", v(-1.4, -3.2, 0))
		"ub_stop":
			ex(m, [-1.6, 0.0, 1.6, 0.0, 1.0, -2.2, -1.2, -2.2], 2.6, 0, 0.6)
			pb.anchor("support", v(-1.4, -2.4, -3.0))
		"ub_bipod":
			clamp.call(3.0)
			ex(pb.s("alu"), [-2.0, -1.0, 2.0, -1.0, 2.0, -2.8, -2.0, -2.8], 4.2, 0, 0.5)
			for x in [-1.4, 1.4]:
				cy(pb.s("steel"), 0.42, 17.0, x, -2.4, -9.0, Vector3.ZERO, 10, 0.1)
				cy(pb.s("rubber"), 0.6, 1.4, x, -2.4, -17.6, Vector3.ZERO, 10, 0.2)
			pb.anchor("support", v(-1.4, -3.6, 4.0))
		"ub_gl":
			clamp.call(14.0)
			lt(m, [0.0, 8.0, 2.4, 8.0, 2.4, -14.0, 2.1, -15.0, 0.0, -15.0], 22, T(0, -3.4, 0))
			cy(pb.s("bore"), 2.05, 0.2, 0, -3.4, -15.0, Vector3.ZERO, 18)
			ex(m, [6.0, -5.6, 10.0, -5.6, 10.6, -11.0, 7.8, -11.0], 2.6, 0, 0.8)
			trigger_guard(pb.s("steel"), 3.0, 8.0, -5.6, -8.0, 1.2)
			pb.anchor("support", v(-1.4, -9.0, 9.0))
		"ub_sg":
			clamp.call(16.0)
			lt(pb.s("steel"), [0.0, 6.0, 1.3, 6.0, 1.3, -18.0, 0.0, -18.0], 18, T(0, -2.6, 0))
			cy(pb.s("bore"), 1.0, 0.2, 0, -2.6, -18.05, Vector3.ZERO, 14)
			ex(m, [4.0, -3.6, 10.0, -3.6, 10.0, -6.0, 4.0, -6.0], 2.4, 0, 0.4)
			ex(m, [-6.0, -3.6, 2.0, -3.6, 2.0, -10.0, -6.0, -10.0], 2.6, 0, 0.6)
			pb.anchor("support", v(-1.4, -9.0, -2.0))
		"ub_light", "sd_light":
			clamp.call(3.0)
			lt(m, [0.0, 3.0, 1.0, 3.0, 1.1, -3.0, 1.6, -4.4, 1.6, -6.0, 0.0, -6.0], 18, T(0, -2.2, 1.0))
			MK.cyl(pb.s("white"), 1.4 * CM, 0.1 * CM, T(0, -2.2, -5.0), 18)
			pb.info["light"] = v(0, -2.2, -5.2)
		"ub_laser":
			clamp.call(3.0)
			ex(m, [-3.0, -1.0, 2.4, -1.0, 2.4, -3.0, -3.0, -3.0], 2.6, 0, 0.5)
			MK.sphere(pb.s("glow"), 0.25 * CM, T(0.6, -2.0, -3.05), 8, 4)
			pb.info["laser"] = v(0.6, -2.0, -3.1)
		"sd_laser":
			clamp.call(3.0)
			ex(m, [-3.4, -1.0, 2.6, -1.0, 2.6, -3.4, -3.4, -3.4], 2.4, 0, 0.5)
			MK.sphere(pb.s("glow"), 0.25 * CM, T(0, -2.2, -3.45), 8, 4)
			pb.info["laser"] = v(0, -2.2, -3.5)
		"sd_peq":
			clamp.call(5.0)
			ex(m, [-4.6, -1.0, 4.0, -1.0, 4.0, -4.2, -4.6, -4.2], 3.6, 0, 0.6)
			MK.sphere(pb.s("glow"), 0.25 * CM, T(-0.8, -2.0, -4.65), 8, 4)
			MK.cyl(pb.s("white"), 1.0 * CM, 0.1 * CM, T(0.6, -3.0, -4.65), 14)
			pb.info["laser"] = v(-0.8, -2.0, -4.7)
			pb.info["light"] = v(0.6, -3.0, -4.8)


static func _trigger(pb: MK.PB, id: String) -> void:
	var role := "main" if id == "trig_flat" else "steel"
	if id == "trig_flat":
		exv(pb.s(role), band([0.2, 0.4, 0.3, -2.2], 0.45), 0.7, 0, 0.1)
	else:
		exv(pb.s(role), band([0.4, 0.4, 0.0, -0.6, 0.0, -1.4, 0.5, -2.2], 0.4), 0.6 if id != "trig_match" else 0.45, 0, 0.1)
	if id in ["trig_sel", "trig_burst", "trig_three"]:
		cy(pb.s("steel"), 0.6, 0.3, -1.55, 1.6, 3.2, Vector3(0, 90, 0), 12)
		bx(pb.s("steel"), 0.25, 0.4, 1.4, -1.65, 1.6, 3.8, 0.1)

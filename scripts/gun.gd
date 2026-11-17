class_name Gun
extends RefCounted
## Builds, validates, assembles (into a Node3D) and rates gun designs.

const ORDER := ["barrel", "trigger", "grip", "stock", "mag", "handguard", "muzzle", "under", "side", "optic"]
const NATIVE_IRONS := ["ak", "pump", "double", "lever", "smg", "pistol", "revolver"]
const MANUAL := ["bolt", "pump", "lever", "break", "revolver"]

static var _cache := {}


# ------------------------------------------------------------------ data
static func new_build(rcv_id: String) -> Dictionary:
	var r: Dictionary = Parts.RCV[rcv_id]
	var b := {"rcv": rcv_id, "cal": r.cals[0], "ammo": "", "name": r.name, "fin": r.fin, "parts": {}, "blen": r.blen[2]}
	for slot in r.def:
		var d := Parts.get_part(r.def[slot])
		b.parts[slot] = {"id": r.def[slot], "p": _default_params(d), "f": d.fin if d.fin != "Black" or slot != "barrel" else "Black"}
	b.ammo = Cal.ammo_for(b.cal)[0]
	return b


static func _default_params(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d.get("p", {}):
		out[k] = d.p[k][3]
	return out


## Fixes a build after the receiver, caliber or a part changes.
static func validate(b: Dictionary) -> void:
	var r: Dictionary = Parts.RCV[b.rcv]
	if b.cal not in r.cals:
		b.cal = r.cals[0]
	if b.ammo not in Cal.ammo_for(b.cal):
		b.ammo = Cal.ammo_for(b.cal)[0]
	b.blen = clampf(b.get("blen", r.blen[2]), r.blen[0], r.blen[1])
	for slot in b.parts.keys():
		var e: Dictionary = b.parts[slot]
		if e.id not in Parts.options(b.rcv, slot):
			b.parts.erase(slot)
	for slot in Parts.SLOTS:
		if Parts.required(b.rcv, slot) and not b.parts.has(slot):
			var opts := Parts.options(b.rcv, slot)
			var pick: String = r.def.get(slot, opts[0] if opts.size() > 0 else "")
			if pick != "":
				var d := Parts.get_part(pick)
				b.parts[slot] = {"id": pick, "p": _default_params(d), "f": d.fin}
	# A stock with an integral grip replaces the pistol grip.
	if has_stock_grip(b) and b.parts.has("grip") and r.slots.get("grip", "") == "pg":
		b.parts.erase("grip")


static func has_stock_grip(b: Dictionary) -> bool:
	var s: Dictionary = b.parts.get("stock", {})
	return not s.is_empty() and Parts.get_part(s.id).get("grip", false)


static func slot_available(b: Dictionary, slot: String) -> bool:
	if Parts.options(b.rcv, slot).is_empty():
		return false
	if slot == "grip" and has_stock_grip(b) and Parts.RCV[b.rcv].slots.get("grip", "") == "pg":
		return false
	if slot == "muzzle" and b.rcv == "revolver":
		return false
	return true


static func ctx_for(b: Dictionary) -> Dictionary:
	var r: Dictionary = Parts.RCV[b.rcv]
	var opt: String = b.parts.get("optic", {}).get("id", "")
	return {
		"fam": r.fam, "rcv": b.rcv, "cal_id": b.cal, "cal": Cal.get_cal(b.cal), "blen": b.blen * 0.01,
		"optic": opt, "native_irons": r.fam in NATIVE_IRONS, "mag_tag": r.slots.get("mag", ""), "cap": Parts.capacity(b),
	}


# ------------------------------------------------------------------ assembly
static func _baked(id: String, params: Dictionary, ctx: Dictionary) -> Dictionary:
	var key := id + "|" + var_to_str(params) + "|" + var_to_str(ctx)
	if _cache.has(key):
		return _cache[key]
	if _cache.size() > 600:
		_cache.clear()
	var pb := Models.build(id, params, ctx)
	var baked := pb.bake()
	_cache[key] = baked
	return baked


static func _instance(baked: Dictionary, finish: String, nm: String) -> Node3D:
	var root := Node3D.new()
	root.name = nm
	var pivots: Dictionary = baked.info.get("pivots", {})
	var groups := {}
	for k in baked.meshes:
		var parts: PackedStringArray = k.split("|")
		var g := parts[0]
		var role := parts[1]
		var parent := root
		if g != "":
			if not groups.has(g):
				var gn := Node3D.new()
				gn.name = g
				gn.position = pivots.get(g, Vector3.ZERO)
				root.add_child(gn)
				groups[g] = gn
			parent = groups[g]
		var mi := MeshInstance3D.new()
		mi.mesh = baked.meshes[k]
		mi.material_override = Mats.get_mat(role, finish)
		if g != "":
			mi.position = -pivots.get(g, Vector3.ZERO)
		parent.add_child(mi)
	root.set_meta("groups", groups)
	return root


## Assembles the gun. Returns a Node3D with meta "info":
## anchors (gun space), groups (animated nodes), slot nodes, optic data.
static func assemble(b: Dictionary) -> Node3D:
	validate(b)
	var ctx := ctx_for(b)
	var r: Dictionary = Parts.RCV[b.rcv]
	var gun := Node3D.new()
	gun.name = "Gun"
	var rb := _baked(b.rcv, {}, ctx)
	var rnode := _instance(rb, b.get("fin", r.fin), "receiver")
	gun.add_child(rnode)
	var socks := {}
	for k in rb.sockets:
		socks[k] = rb.sockets[k]
	var anchors := {}
	for k in rb.anchors:
		anchors[k] = rb.anchors[k]
	var rinfo: Dictionary = rb.info
	var groups: Dictionary = rnode.get_meta("groups").duplicate()
	var slot_nodes := {}
	var part_info := {}
	var sock_group: Dictionary = rinfo.get("sock_group", {})
	var break_node: Node3D = null
	if rinfo.get("move", "") == "break":
		break_node = Node3D.new()
		break_node.name = "break"
		break_node.position = anchors.get("hinge", Vector3.ZERO)
		gun.add_child(break_node)
		groups["break"] = break_node
	var grip_set := false
	for slot in ORDER:
		if not b.parts.has(slot) or not socks.has(slot):
			continue
		var e: Dictionary = b.parts[slot]
		var pb := _baked(e.id, e.get("p", {}), ctx)
		if pb.info.get("native", false):
			part_info[slot] = pb.info
			continue
		var xf: Transform3D = socks[slot]
		var node := _instance(pb, e.get("f", "Black"), slot)
		var parent: Node3D = gun
		var local := xf
		if sock_group.has(slot) and groups.has(sock_group[slot]):
			parent = groups[sock_group[slot]]
			local = parent.transform.affine_inverse() * xf
		elif break_node and slot in ["barrel", "handguard", "muzzle", "under", "side"]:
			parent = break_node
			local = break_node.transform.affine_inverse() * xf
		node.transform = local
		parent.add_child(node)
		slot_nodes[slot] = node
		for k in pb.sockets:
			socks[k] = xf * pb.sockets[k]
		for k in pb.anchors:
			anchors[k] = xf * pb.anchors[k]
		var pi: Dictionary = pb.info.duplicate()
		for k in ["reticle", "laser", "light"]:
			if pi.has(k):
				pi[k] = xf * pi[k]
		part_info[slot] = pi
		if slot == "grip":
			grip_set = true
	if not grip_set and anchors.has("wrist"):
		anchors["grip"] = anchors["wrist"]
	# Sight line: optic, else native sights.
	var opt: Dictionary = b.parts.get("optic", {})
	var odef := Parts.get_part(opt.get("id", ""))
	var native: bool = part_info.get("optic", {}).get("native", false) or opt.is_empty()
	if native and anchors.has("native_sight"):
		anchors["sight"] = anchors["native_sight"]
	elif not anchors.has("sight"):
		anchors["sight"] = Vector3(0, 0.035, anchors.get("grip", Vector3.ZERO).z)
	# Flip-up irons need a front post at the front of the rail / barrel.
	if odef.get("kind", "") == "irons" and not native:
		var fp: Vector3 = anchors.get("fsight", anchors.get("fsight_b", Vector3(0, 0.02, -0.3)))
		_front_post(gun, fp, anchors.sight.y)
	var muzzle: Vector3 = socks.get("muzzle", Transform3D()).origin
	if anchors.has("muzzle_end"):
		muzzle = anchors.muzzle_end
	if slot_nodes.has("mag"):
		groups["mag"] = slot_nodes.mag
	if r.action == "pump" and slot_nodes.has("handguard"):
		groups["pump"] = slot_nodes.handguard
	var info := {
		"anchors": anchors, "groups": groups, "slots": slot_nodes, "rinfo": rinfo, "parts": part_info,
		"muzzle": muzzle, "zoom": odef.get("zoom", [1.0]), "optic_kind": odef.get("kind", "irons" if native else ""),
		"optic_id": opt.get("id", ""),
	}
	gun.set_meta("info", info)
	return gun


static func _front_post(gun: Node3D, base: Vector3, top_y: float) -> void:
	var st := MK.new_st()
	var h := maxf(0.008, top_y - base.y)
	MK.box(st, Vector3(0.012, 0.01, 0.02), MK.xf(base + Vector3(0, 0.005, 0)), 0.002, 0.001)
	MK.box(st, Vector3(0.006, h, 0.012), MK.xf(base + Vector3(0, h * 0.5 + 0.005, 0)), 0.001, 0.0008)
	MK.box(st, Vector3(0.0018, 0.012, 0.0018), MK.xf(base + Vector3(0, h - 0.002, 0)), 0.0003, 0.0)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Mats.get_mat("steel")
	gun.add_child(mi)


# ------------------------------------------------------------------ stats
static func _mod(b: Dictionary, key: String, def := 1.0) -> float:
	var out := def
	for slot in b.parts:
		var d := Parts.get_part(b.parts[slot].id)
		if d.m.has(key) and typeof(d.m[key]) == TYPE_FLOAT:
			out *= d.m[key]
	return out


static func _sum(b: Dictionary, key: String) -> float:
	var out := 0.0
	for slot in b.parts:
		var d := Parts.get_part(b.parts[slot].id)
		if d.m.has(key) and typeof(d.m[key]) == TYPE_FLOAT:
			out += d.m[key]
	return out


static func has_flag(b: Dictionary, key: String) -> bool:
	for slot in b.parts:
		var d := Parts.get_part(b.parts[slot].id)
		if d.m.get(key, false) == true or d.get(key, false) == true:
			return true
	return false


static func modes(b: Dictionary) -> Array:
	var r: Dictionary = Parts.RCV[b.rcv]
	if r.action in MANUAL:
		return ["semi"]
	var t := Parts.get_part(b.parts.get("trigger", {}).get("id", "trig_std"))
	return t.get("modes", ["semi"])


static func mass(b: Dictionary) -> float:
	var r: Dictionary = Parts.RCV[b.rcv]
	var kg: float = r.kg
	var c := Cal.get_cal(b.cal)
	for slot in b.parts:
		var d := Parts.get_part(b.parts[slot].id)
		kg += d.kg
		if slot == "barrel":
			kg += d.get("kgcm", 0.014) * b.blen * (2.0 if r.fam == "double" else 1.0)
	var cap := Parts.capacity(b)
	var round_kg: float = (c.g * 1.9 + c.pw) / 1000.0
	kg += cap * round_kg
	if b.parts.has("mag"):
		kg += 0.1 + cap * 0.003
	return kg


static func compute(b: Dictionary) -> Dictionary:
	validate(b)
	var r: Dictionary = Parts.RCV[b.rcv]
	var proj := Cal.projectile(b.cal, b.ammo, b.blen)
	proj.v *= _mod(b, "v")
	var kg := mass(b)
	var n: int = proj.pellets
	var e_muzzle: float = 0.5 * proj.kg * proj.v * proj.v * n
	var gas_v: float = proj.v * 1.6
	var p: float = proj.kg * n * proj.v + proj.powder / 1000.0 * gas_v
	var vr: float = p / kg
	var free_e: float = 0.5 * kg * vr * vr * float(proj.recoil)
	var stocked: bool = b.parts.has("stock") or b.rcv == "bullpup"
	var felt: float = free_e * float(r.recoil) * _mod(b, "recoil")
	if not stocked and r.fam not in ["pistol", "revolver"]:
		felt *= 1.4
	var kick := 0.42 * sqrt(felt) * _mod(b, "climb")
	if r.fam in ["pistol", "revolver"]:
		kick *= 1.35
	var moa: float = r.moa * _mod(b, "moa") * proj.moa
	var ads := (0.13 + 0.05 * kg) * _mod(b, "ads")
	var hip := (1.0 + kg * 0.35) * _mod(b, "hip")
	var sway := (0.6 + kg * 0.12) * _mod(b, "sway")
	var rpm: float = r.rpm
	if has_flag(b, "supp") and r.action == "semi":
		rpm *= 1.06
	var ref_e: float = 0.5 * proj.kg * pow(Cal.get_cal(b.cal).vmax * 0.92, 2.0)
	var pen: float = proj.pen * sqrt(maxf(0.5 * proj.kg * proj.v * proj.v, 1.0) / maxf(ref_e, 1.0))
	var db := 152.0 + 10.0 * log(maxf(e_muzzle, 30.0) / 300.0) / log(10.0)
	db += clampf((35.0 - b.blen) * 0.12, -2.0, 4.0) + _sum(b, "noise")
	var traj := trajectory(proj, [100.0, 300.0, 500.0, 1000.0])
	var eff := effective_range(proj, moa)
	var cap := Parts.capacity(b)
	return {
		"v": proj.v, "e": e_muzzle, "pellets": n, "kg": kg, "felt": felt, "free": free_e, "kick": kick,
		"moa": moa, "ads": ads, "hip": hip, "sway": sway, "rpm": rpm, "pen": pen, "db": db,
		"cap": cap, "reload": r.reload * _mod(b, "reload"), "jam": r.jam * _mod(b, "jam"), "heat": _mod(b, "heat"),
		"pellet_deg": 0.9 * _mod(b, "pellet"), "dmg": sqrt(0.5 * proj.kg * proj.v * proj.v) * 1.2 * proj.dmg,
		"traj": traj, "eff": eff, "modes": modes(b), "proj": proj, "split": _mod(b, "split"),
		"supp": has_flag(b, "supp"), "flash": _mod(b, "flash"), "bipod": has_flag(b, "bipod"),
	}


## Point-mass trajectory (no wind) with the bore level: velocity and energy at
## the given distances.
static func trajectory(proj: Dictionary, dists: Array) -> Array:
	var k := Cal.drag_k(proj)
	var pos := Vector2.ZERO
	var vel := Vector2(proj.v, 0)
	var out := []
	var i := 0
	var t := 0.0
	var dt := 0.002
	while i < dists.size() and t < 12.0:
		var sp := vel.length()
		vel += (Vector2(0, -9.81) - vel * sp * k) * dt
		pos += vel * dt
		t += dt
		if pos.x >= dists[i]:
			var vv := vel.length()
			out.append({"d": dists[i], "v": vv, "e": 0.5 * proj.kg * vv * vv * proj.pellets, "t": t, "drop": -pos.y})
			i += 1
	return out


## Distance where the bullet falls below 45% of muzzle energy, goes subsonic
## (for supersonic loads) or the group exceeds a 40 cm torso.
static func effective_range(proj: Dictionary, moa: float) -> float:
	var k := Cal.drag_k(proj)
	var v0: float = proj.v
	var x := 0.0
	var vx: float = v0
	var dt := 0.002
	var e0 := v0 * v0
	var group_lim := 40.0 / maxf(moa * 2.9, 0.1) * 100.0
	if proj.pellets > 1:
		group_lim = 40.0
	while x < 2500.0:
		vx -= vx * vx * k * dt
		x += vx * dt
		if vx * vx < e0 * 0.45 and x > 50.0:
			break
		if v0 > 500.0 and vx < 340.0:
			break
		if x > group_lim:
			break
	return x

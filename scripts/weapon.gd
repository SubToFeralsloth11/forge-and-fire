extends Node3D
## First-person weapon: viewmodel with hands, aiming, procedural animation
## (bolt/slide travel, pump, lever, bolt handle, reloads), recoil, heat, jams,
## zeroing and firing through the ballistics simulation.

const MOA_RAD := 0.000290888

var player: CharacterBody3D
var cam: Camera3D
var bal: Node3D

var build := {}
var stats := {}
var info := {}
var rcv := {}
var cal := {}
var gun: Node3D
var proj := {}

var ammo := 0
var cap := 1
var modes: Array = ["semi"]
var mode := 0
var cooldown := 0.0
var burst_left := 0
var trigger_held := false
var _trigger_was := false
var ads := 0.0
var ads_on := false
var heat := 0.0
var jammed := false
var zoom_i := 0
var zero := 100.0
var zero_angle := 0.0
var sight_h := 0.05
var shots := 0
var last_split := 0.0
var _last_shot_time := 0.0

# animation timers
var _bolt_t := 1.0
var _bolt_dur := 0.08
var _cycle_t := -1.0
var _cycle_dur := 0.5
var _reload_t := -1.0
var _reload_dur := 2.0
var _reload_kind := "mag"
var _reload_was_empty := false
var _shell_loop := false
var _clear_t := -1.0
var _inspect_t := -1.0
var _rec_z := 0.0
var _rec_zv := 0.0
var _rec_p := 0.0
var _rec_pv := 0.0
var _rec_r := 0.0
var _cyl_rot := 0.0
var _cyl_target := 0.0
var _hammer := 0.0
var _sway_t := 0.0
var _bob_t := 0.0
var _sounds_done := {}
var _swap_t := 0.0

var hand_r: MeshInstance3D
var hand_l: MeshInstance3D
var arm_r: MeshInstance3D
var arm_l: MeshInstance3D
var laser_dot: MeshInstance3D
var light: SpotLight3D
var light_on := false

var ub_kind := ""
var ub_ammo := 0
var ub_reload := 0.0


func _ready() -> void:
	var glove := Mats.prop(Color(0.12, 0.12, 0.11), 0.85)
	var sleeve := Mats.prop(Color(0.28, 0.3, 0.22), 0.95)
	hand_r = _limb(_capsule(0.032, 0.11), glove)
	hand_l = _limb(_capsule(0.032, 0.11), glove)
	arm_r = _limb(_capsule(0.036, 0.5), sleeve)
	arm_l = _limb(_capsule(0.036, 0.5), sleeve)
	laser_dot = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.004
	sm.height = 0.008
	laser_dot.mesh = sm
	laser_dot.material_override = Mats.get_mat("glow")
	laser_dot.top_level = true
	laser_dot.visible = false
	add_child(laser_dot)


func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 10
	c.rings = 3
	return c


func _limb(m: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


# ------------------------------------------------------------------ equip
func equip(b: Dictionary) -> void:
	build = b.duplicate(true)
	Gun.validate(build)
	stats = Gun.compute(build)
	rcv = Parts.RCV[build.rcv]
	cal = Cal.get_cal(build.cal)
	proj = stats.proj
	if gun:
		gun.queue_free()
	gun = Gun.assemble(build)
	add_child(gun)
	for mi in gun.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	info = gun.get_meta("info")
	cap = stats.cap
	ammo = cap + (1 if _closed_bolt_mag() else 0)
	modes = stats.modes
	mode = modes.size() - 1 if "auto" in modes else 0
	heat = 0.0
	jammed = false
	_reload_t = -1.0
	_cycle_t = -1.0
	zoom_i = 0
	sight_h = info.anchors.sight.y
	var kind: String = info.optic_kind
	zero = 100.0
	if kind in ["irons", "dot", "holo"] or rcv.fam in ["pistol", "revolver"]:
		zero = 50.0 if rcv.fam not in ["pistol", "revolver"] else 25.0
	if proj.cls == "shotgun":
		zero = 25.0
	if proj.cls == "grenade":
		zero = 100.0
	_compute_zero()
	ub_kind = ""
	for slot in ["under"]:
		var e: Dictionary = build.parts.get(slot, {})
		if not e.is_empty():
			var d := Parts.get_part(e.id)
			if d.m.get("ubgl", false) or d.get("ubgl", false):
				ub_kind = "gl"
				ub_ammo = 1
			elif d.m.get("ubsg", false) or d.get("ubsg", false):
				ub_kind = "sg"
				ub_ammo = 3
	if light:
		light.queue_free()
		light = null
	light_on = false
	for slot in ["under", "side"]:
		var pi: Dictionary = info.parts.get(slot, {})
		if pi.has("light") and light == null:
			light = SpotLight3D.new()
			light.spot_range = 60.0
			light.spot_angle = 14.0
			light.light_energy = 6.0
			light.visible = false
			gun.add_child(light)
			light.position = pi.light
	_swap_t = 0.6
	Sfx.play("bolt_back", null, -6.0)


func _closed_bolt_mag() -> bool:
	return rcv.action in ["semi", "bolt"] and rcv.slots.has("mag") and build.rcv != "lmg"


## Bore elevation so the bullet crosses the line of sight at `zero` metres.
func _compute_zero() -> void:
	var k := Cal.drag_k(proj)
	var lo := -0.02
	var hi := 0.25
	for it in 40:
		var th := (lo + hi) * 0.5
		var p := Vector2(0, -sight_h)
		var v: Vector2 = Vector2(cos(th), sin(th)) * float(proj.v)
		var dt := 0.001
		var t := 0.0
		while p.x < zero and t < 10.0:
			var sp := v.length()
			v += (Vector2(0, -9.81) - v * sp * k) * dt
			p += v * dt
			t += dt
		if p.y > 0.0:
			hi = th
		else:
			lo = th
	zero_angle = (lo + hi) * 0.5


func adjust_zero(dir: int) -> void:
	var kind: String = info.optic_kind
	var step := 50.0 if kind == "scope" else 25.0
	var mx := 1500.0 if kind == "scope" else 400.0
	zero = clampf(zero + dir * step, 25.0, mx)
	_compute_zero()
	Sfx.play("click", null, -6.0)


func zoom() -> float:
	var z: Array = info.get("zoom", [1.0])
	return float(z[zoom_i % z.size()])


func cycle_zoom() -> void:
	var z: Array = info.get("zoom", [1.0])
	if z.size() > 1:
		zoom_i = (zoom_i + 1) % z.size()
		Sfx.play("click", null, -4.0)


func scoped() -> bool:
	return ads > 0.92 and (info.optic_kind == "scope" or zoom() > 1.5)


func busy() -> bool:
	return _reload_t >= 0.0 or _clear_t >= 0.0 or _swap_t > 0.0


# ------------------------------------------------------------------ input
func set_trigger(on: bool) -> void:
	trigger_held = on


func switch_mode() -> void:
	if modes.size() > 1:
		mode = (mode + 1) % modes.size()
		Sfx.play("select", null, -4.0)


func toggle_light() -> void:
	if light:
		light_on = not light_on
		light.visible = light_on
		Sfx.play("click", null, -6.0)


func inspect() -> void:
	if not busy():
		_inspect_t = 0.0


func reload() -> void:
	if jammed:
		_clear_t = 0.0
		Sfx.play("bolt_back", null, -2.0)
		return
	if busy() or ammo >= cap + (1 if _closed_bolt_mag() else 0):
		return
	_cycle_t = -1.0
	_inspect_t = -1.0
	_reload_was_empty = ammo == 0
	_sounds_done.clear()
	var kind := "mag"
	if rcv.slots.get("mag", "") in ["tube", "ltube"]:
		kind = "tube"
	elif rcv.action == "revolver":
		kind = "cyl"
	elif rcv.action == "break":
		kind = "break"
	elif rcv.slots.get("mag", "") == "belt":
		kind = "belt"
	_reload_kind = kind
	match kind:
		"tube":
			_reload_dur = rcv.reload * Gun._mod(build, "reload") + 0.25
			_shell_loop = true
		"mag", "belt":
			_reload_dur = stats.reload + (0.55 if _reload_was_empty and rcv.action == "semi" else 0.0)
		_:
			_reload_dur = stats.reload
	_reload_t = 0.0


func fire_underbarrel() -> void:
	if ub_kind == "" or busy():
		return
	if ub_ammo <= 0:
		if ub_reload <= 0.0:
			ub_reload = 2.4 if ub_kind == "gl" else 2.0
			Sfx.play("mag_out", null, -4.0)
		return
	ub_ammo -= 1
	var c_id := "40mm" if ub_kind == "gl" else "12ga"
	var p := Cal.projectile(c_id, "he" if ub_kind == "gl" else "buck", 30.0 if ub_kind == "gl" else 45.0)
	var dir := -cam.global_basis.z
	var eye := cam.global_position
	var origin := eye + cam.global_basis * Vector3(0, -0.08, 0)
	var up_ang := 0.06 if ub_kind == "gl" else 0.0
	dir = dir.rotated(cam.global_basis.x, up_ang)
	for i in p.pellets:
		var d := dir
		if p.pellets > 1:
			d = _cone(dir, deg_to_rad(1.1))
		bal.fire(origin, d * p.v + player.velocity, p, {"eye": eye, "dir": -cam.global_basis.z, "d": p.d})
	var e: float = 0.5 * p.kg * p.v * p.v * p.pellets
	Sfx.play_stream(Sfx.gunshot(e, 30.0, false, 0.0, false), null, 2.0)
	player.add_recoil(2.4 if ub_kind == "sg" else 1.6, randf_range(-0.6, 0.6))
	_rec_zv += 1.2
	_rec_pv += 6.0
	Fx.muzzle(gun.to_global(info.muzzle + Vector3(0, -0.05, 0.05)), dir, 1.2, 1.5)


# ------------------------------------------------------------------ firing
func _can_fire() -> bool:
	return not busy() and _cycle_t < 0.0 and cooldown <= 0.0 and not jammed and _inspect_t < 0.0 and not player.sprinting


func _physics_process(delta: float) -> void:
	if gun == null:
		return
	cooldown -= delta
	heat = maxf(0.0, heat - delta * 0.04 * (1.0 / maxf(stats.heat, 0.3)))
	if ub_reload > 0.0:
		ub_reload -= delta
		if ub_reload <= 0.0:
			ub_ammo = 1 if ub_kind == "gl" else 3
			Sfx.play("mag_in", null, -4.0)
	var pressed := trigger_held and not _trigger_was
	_trigger_was = trigger_held
	if trigger_held and _reload_t >= 0.0 and _reload_kind == "tube" and ammo > 0:
		_reload_t = -1.0
		_shell_loop = false
	if not _can_fire():
		return
	var m: String = modes[mode]
	if burst_left > 0:
		_shoot()
		burst_left -= 1
		return
	if not pressed and not (m == "auto" and trigger_held):
		return
	if ammo <= 0:
		if pressed:
			Sfx.play("dry", null, -2.0)
			if rcv.action != "revolver":
				reload()
		return
	if m == "burst":
		burst_left = 2
	_shoot()


func _shoot() -> void:
	if ammo <= 0:
		burst_left = 0
		return
	ammo -= 1
	shots += 1
	var now := Time.get_ticks_msec() / 1000.0
	last_split = now - _last_shot_time if _last_shot_time > 0.0 else 0.0
	_last_shot_time = now
	var interval: float = 60.0 / stats.rpm
	if modes[mode] == "semi" and rcv.action not in Gun.MANUAL:
		interval = maxf(interval, 0.075 * stats.split)
	cooldown = interval
	# Ballistics.
	var eye := cam.global_position
	var los := -cam.global_basis.z
	var right := cam.global_basis.x
	var origin := eye + cam.global_basis * Vector3(0, -sight_h, 0)
	var base_dir := los.rotated(right, zero_angle)
	var moa: float = stats.moa * (1.0 + heat * 1.5 * stats.heat)
	var spread := moa * 0.5 * MOA_RAD
	var hip_deg: float = stats.hip * (1.0 - ads)
	if rcv.fam in ["pistol", "revolver"]:
		hip_deg *= 0.6
	var mv: float = player.velocity.length()
	spread += deg_to_rad(hip_deg * 0.5) + deg_to_rad(clampf(mv * 0.25, 0.0, 2.0)) * (1.0 - ads * 0.5)
	var dir := _cone(base_dir, spread)
	var v: float = proj.v
	var n: int = proj.pellets
	var pel := deg_to_rad(stats.pellet_deg) if n > 1 else 0.0
	for i in n:
		var d := dir if n == 1 else _cone(dir, pel)
		var pv := v * randf_range(0.99, 1.01)
		bal.fire(origin, d * pv + player.velocity, proj, {"eye": eye, "dir": los, "d": proj.d})
	# Heat & jams.
	heat += float(0.5 * proj.kg * v * v * n) / 40000.0 * stats.heat
	if randf() < stats.jam * (1.0 + heat * 4.0) and ammo > 0:
		jammed = true
		burst_left = 0
	# Recoil.
	var k: float = stats.kick
	if player.bipod_ready(stats):
		k *= 0.28
	elif player.stance == 2:
		k *= 0.7
	elif player.stance == 1:
		k *= 0.85
	player.add_recoil(k * randf_range(0.85, 1.15), k * randf_range(-0.35, 0.35))
	var hard := clampf(stats.felt / 15.0, 0.2, 3.0)
	_rec_zv += 0.9 * hard
	_rec_pv += 5.0 * hard * (1.4 if rcv.fam in ["pistol", "revolver"] else 1.0)
	_rec_r += randf_range(-1.0, 1.0) * hard
	# Effects.
	var mz := gun.to_global(info.muzzle)
	var fwd := -gun.global_basis.z
	var flash: float = stats.flash * clampf(stats.e / 1500.0, 0.3, 2.5) * (1.0 + clampf((30.0 - build.blen) / 20.0, 0.0, 1.0))
	Fx.muzzle(mz, fwd, flash, 1.0 if not stats.supp else 1.6)
	var supersonic: bool = v > 343.0
	Sfx.play_stream(Sfx.gunshot(stats.e, build.blen, stats.supp, Gun._sum(build, "noise"), supersonic), null, -2.0 + (0.0 if not stats.supp else -6.0))
	_bolt_t = 0.0
	_bolt_dur = clampf(interval * 0.85, 0.04, 0.12)
	_hammer = 1.0
	if rcv.action == "revolver":
		_cyl_target += TAU / 6.0
	if rcv.action in ["semi"]:
		_eject()
	if rcv.action in ["bolt", "pump", "lever"]:
		_cycle_t = 0.0
		_cycle_dur = {"bolt": 0.8, "pump": 0.45, "lever": 0.5}[rcv.action]
		_sounds_done.clear()


func _cone(dir: Vector3, radius: float) -> Vector3:
	if radius <= 0.0:
		return dir
	var r := sqrt(randf()) * radius
	var phi := randf() * TAU
	var perp := dir.cross(Vector3.UP)
	if perp.length_squared() < 1e-6:
		perp = dir.cross(Vector3.RIGHT)
	perp = perp.normalized().rotated(dir, phi)
	return dir.rotated(perp, r).normalized()


func _eject() -> void:
	if cal.hull == "none":
		return
	var ep: Vector3 = info.rinfo.get("eject", Vector3(0.02, 0.01, 0.08))
	var pos := gun.to_global(ep)
	var b := cam.global_basis
	var vel: Vector3 = player.velocity + b.x * randf_range(2.0, 3.2) + b.y * randf_range(1.0, 2.0) + b.z * randf_range(0.2, 0.8)
	if info.rinfo.get("eject_down", false):
		vel = player.velocity - b.y * 1.5 + b.x * 0.4
	elif info.rinfo.get("eject_up", false):
		vel = player.velocity + b.y * 2.6 + b.x * 0.5
	Fx.casing(pos, vel, cal)


# ------------------------------------------------------------------ pose
func _process(delta: float) -> void:
	if gun == null:
		return
	_swap_t = maxf(0.0, _swap_t - delta)
	var want_ads: bool = ads_on and not player.sprinting and _reload_t < 0.0 and _inspect_t < 0.0 and _clear_t < 0.0
	var ads_speed := 1.0 / maxf(stats.ads, 0.08)
	ads = move_toward(ads, 1.0 if want_ads else 0.0, delta * ads_speed)
	_update_anims(delta)
	var a: Dictionary = info.anchors
	var G: Vector3 = a.get("grip", Vector3(0, -0.05, 0.15))
	var S: Vector3 = a.sight
	var pistol: bool = rcv.fam in ["pistol", "revolver"]
	var hip_pos := Vector3(0.13, -0.15, -0.3) if not pistol else Vector3(0.11, -0.16, -0.36)
	var hip_b := Basis(Vector3.UP, 0.05) * Basis(Vector3.FORWARD, 0.02)
	var hip := Transform3D(hip_b, hip_pos - hip_b * G)
	var kind: String = info.optic_kind
	var eye := 0.16
	match kind:
		"irons": eye = 0.12 if not pistol else 0.42
		"dot": eye = 0.2 if not pistol else 0.42
		"holo": eye = 0.15
		"scope": eye = 0.12
	var adst := Transform3D(Basis.IDENTITY, Vector3(0, 0, -eye) - S)
	var e := ads * ads * (3.0 - 2.0 * ads)
	var t := Transform3D(hip.basis.slerp(adst.basis, e), hip.origin.lerp(adst.origin, e))
	# Sprint, reload, inspect, cycle poses (rotate around the grip).
	var pose_rot := Vector3.ZERO
	var pose_off := Vector3.ZERO
	var sprint_k: float = 1.0 if player.sprinting and _reload_t < 0.0 else 0.0
	_sprint_blend = move_toward(_sprint_blend, sprint_k, delta * 4.0)
	pose_rot += Vector3(-0.35, 0.6, 0.25) * _sprint_blend
	pose_off += Vector3(-0.04, -0.04, 0.03) * _sprint_blend
	if _reload_t >= 0.0:
		var rt := clampf(_reload_t / _reload_dur, 0.0, 1.0)
		var tilt := smoothstep(0.0, 0.15, rt) * (1.0 - smoothstep(0.85, 1.0, rt))
		pose_rot += Vector3(0.25, 0.2, 0.45) * tilt
		pose_off += Vector3(-0.05, 0.03, 0.03) * tilt
	if _clear_t >= 0.0:
		var ct := clampf(_clear_t / 0.9, 0.0, 1.0)
		pose_rot += Vector3(0.0, 0.0, 0.6) * sin(ct * PI)
	if _cycle_t >= 0.0:
		var cy := clampf(_cycle_t / _cycle_dur, 0.0, 1.0)
		var amt := sin(cy * PI)
		match rcv.action:
			"bolt": pose_rot += Vector3(0.05, 0.0, 0.18) * amt * (1.0 - ads * 0.6)
			"pump": pose_rot += Vector3(0.06, 0, 0.05) * amt
			"lever": pose_rot += Vector3(-0.1, 0, 0.0) * amt
	if _inspect_t >= 0.0:
		var it := clampf(_inspect_t / 3.0, 0.0, 1.0)
		var amt := smoothstep(0.0, 0.2, it) * (1.0 - smoothstep(0.8, 1.0, it))
		pose_rot += Vector3(0.15, -0.9 + sin(it * PI * 2.0) * 0.5, 0.6 * sin(it * PI)) * amt
		pose_off += Vector3(-0.08, 0.04, 0.05) * amt
	if _swap_t > 0.0:
		pose_off += Vector3(0, -0.3, 0) * _swap_t / 0.6
	# Recoil springs.
	_rec_zv += (-_rec_z * 260.0 - _rec_zv * 22.0) * delta
	_rec_z += _rec_zv * delta
	_rec_pv += (-_rec_p * 220.0 - _rec_pv * 18.0) * delta
	_rec_p += _rec_pv * delta
	_rec_r = lerpf(_rec_r, 0.0, delta * 10.0)
	# Sway and bob.
	_sway_t += delta
	var mv: float = Vector2(player.velocity.x, player.velocity.z).length()
	if player.is_on_floor():
		_bob_t += delta * mv * 1.6
	var bob := Vector3(sin(_bob_t) * 0.006, -absf(cos(_bob_t)) * 0.008, 0) * (1.0 - ads * 0.8) * clampf(mv / 4.0, 0.0, 1.5)
	var idle := Vector3(sin(_sway_t * 1.1) * 0.0015, sin(_sway_t * 1.7) * 0.0012, 0) * (1.0 - ads)
	var pivot := G
	var rb := Basis.from_euler(pose_rot + Vector3(_rec_p * 0.02 * (1.0 - ads * 0.5), 0, _rec_r * 0.01))
	var piv_t := Transform3D(Basis.IDENTITY, pivot) * Transform3D(rb, Vector3.ZERO) * Transform3D(Basis.IDENTITY, -pivot)
	t = t * piv_t
	t.origin += pose_off + bob + idle + Vector3(0, 0, _rec_z * 0.06 * (1.0 - ads * 0.4))
	gun.transform = t
	gun.visible = not scoped()
	_update_hands()
	_update_laser()


var _sprint_blend := 0.0


func smoothstep(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _group(nm: String) -> Node3D:
	var g = info.groups.get(nm)
	return g if is_instance_valid(g) else null


func _snd(key: String, nm: String, at: float, now: float, vol := -4.0) -> void:
	if now >= at and not _sounds_done.has(key):
		_sounds_done[key] = true
		Sfx.play(nm, null, vol)


func _update_anims(delta: float) -> void:
	var move: String = info.rinfo.get("move", "bolt")
	var travel: float = info.rinfo.get("travel", 0.06)
	# Bolt / slide travel after each shot.
	_bolt_t = minf(1.0, _bolt_t + delta / maxf(_bolt_dur, 0.01))
	var bo := sin(_bolt_t * PI) if _bolt_t < 1.0 else 0.0
	var locked: bool = ammo == 0 and rcv.action == "semi" and rcv.fam in ["pistol"]
	var bg := _group("bolt")
	if bg:
		bg.position = Vector3(0, 0, travel * bo)
	var sg := _group("slide")
	if sg:
		sg.position = Vector3(0, 0, travel * (1.0 if locked and _reload_t < 0.0 else bo))
	_hammer = maxf(0.0, _hammer - delta * 8.0)
	var hg := _group("hammer")
	if hg:
		hg.rotation.x = -_hammer * 0.6
	_cyl_rot = lerp_angle(_cyl_rot, _cyl_target, clampf(delta * 20.0, 0.0, 1.0))
	var cg := _group("cyl")
	if cg:
		cg.rotation.z = _cyl_rot
	# Manual action cycling.
	var pump := _group("pump")
	var handle := _group("handle")
	var lever := _group("lever")
	if pump:
		pump.position = info.socks.get("handguard", Transform3D()).origin
	if _cycle_t >= 0.0:
		_cycle_t += delta
		var c := clampf(_cycle_t / _cycle_dur, 0.0, 1.0)
		match rcv.action:
			"pump":
				var off := sin(c * PI) * 0.085
				if pump:
					pump.position = info.socks.handguard.origin + Vector3(0, 0, off)
				if bg:
					bg.position = Vector3(0, 0, off)
				_snd("p1", "pump", 0.0, c)
				_snd("p2", "bolt_fwd", 0.6, c)
				if c >= 0.3 and not _sounds_done.has("ej"):
					_sounds_done["ej"] = true
					_eject()
			"bolt":
				if handle:
					var lift := smoothstep(0.0, 0.2, c) * (1.0 - smoothstep(0.8, 1.0, c))
					var pull := smoothstep(0.2, 0.45, c) * (1.0 - smoothstep(0.55, 0.8, c))
					handle.rotation.z = lift * 1.25
					handle.position = info.rinfo.pivots.get("handle", Vector3.ZERO) + Vector3(0, 0, pull * travel)
				_snd("b1", "bolt_back", 0.2, c)
				_snd("b2", "bolt_fwd", 0.6, c)
				if c >= 0.45 and not _sounds_done.has("ej"):
					_sounds_done["ej"] = true
					_eject()
			"lever":
				if lever:
					lever.rotation.x = sin(c * PI) * 0.9
				_snd("l1", "bolt_back", 0.1, c)
				_snd("l2", "bolt_fwd", 0.7, c)
				if c >= 0.5 and not _sounds_done.has("ej"):
					_sounds_done["ej"] = true
					_eject()
		if c >= 1.0:
			_cycle_t = -1.0
			if handle:
				handle.rotation.z = 0.0
				handle.position = info.rinfo.pivots.get("handle", Vector3.ZERO)
			if lever:
				lever.rotation.x = 0.0
	# Jam clearing.
	if _clear_t >= 0.0:
		_clear_t += delta
		var ch := _group("charge")
		var ct := clampf(_clear_t / 0.9, 0.0, 1.0)
		if ch:
			ch.position = Vector3(0, 0, sin(ct * PI) * travel)
		if bg:
			bg.position = Vector3(0, 0, sin(ct * PI) * travel)
		if ct >= 1.0:
			_clear_t = -1.0
			jammed = false
			ammo = maxi(0, ammo - 1)
			_eject()
			Sfx.play("bolt_fwd", null, -2.0)
	if _inspect_t >= 0.0:
		_inspect_t += delta
		if _inspect_t > 3.0:
			_inspect_t = -1.0
	if _reload_t >= 0.0:
		_reload_t += delta
		_reload_anim(clampf(_reload_t / _reload_dur, 0.0, 1.0), travel)


func _reload_anim(rt: float, travel: float) -> void:
	var mg := _group("mag")
	match _reload_kind:
		"mag", "belt":
			var out := smoothstep(0.18, 0.35, rt)
			var inn := smoothstep(0.5, 0.72, rt)
			var drop := out * (1.0 - inn)
			if mg:
				var base: Transform3D = info.socks.get("mag", Transform3D())
				mg.transform = base
				var down := -base.basis.y * 0.28 * drop
				if _reload_kind == "belt":
					down = Vector3(-0.15, -0.1, 0) * drop
				mg.position = base.origin + down
				mg.visible = drop < 0.95
			_snd("o", "mag_out", 0.2, rt)
			_snd("i", "mag_in", 0.68, rt)
			if _reload_was_empty and rcv.action == "semi":
				var ch := _group("charge")
				var sl := _group("slide")
				var c := smoothstep(0.78, 0.86, rt) * (1.0 - smoothstep(0.88, 0.95, rt))
				if ch:
					ch.position = Vector3(0, 0, c * travel)
				if sl:
					sl.position = Vector3(0, 0, travel * (1.0 - smoothstep(0.86, 0.92, rt)))
				_snd("c1", "bolt_back", 0.8, rt)
				_snd("c2", "bolt_fwd", 0.9, rt)
			if _reload_kind == "belt":
				_snd("cov", "bolt_back", 0.1, rt)
				_snd("cov2", "mag_in", 0.85, rt)
		"tube":
			_snd("s" + str(ammo), "shell", 0.6, rt)
			if rt >= 1.0:
				ammo += 1
				_sounds_done.clear()
				if ammo < cap and _shell_loop:
					_reload_t = 0.0
					return
				_reload_t = -1.0
				if _reload_was_empty:
					_cycle_t = 0.0
					_cycle_dur = 0.45 if rcv.action == "pump" else 0.5
				return
		"cyl":
			var cg := _group("cyl")
			if cg:
				var open := smoothstep(0.08, 0.2, rt) * (1.0 - smoothstep(0.85, 0.95, rt))
				cg.position = info.rinfo.pivots.get("cyl", Vector3.ZERO) + Vector3(-0.03 * open, -0.01 * open, 0)
			_snd("open", "cyl", 0.1, rt)
			_snd("dump", "tink", 0.3, rt, -8.0)
			_snd("load", "mag_in", 0.65, rt)
			_snd("close", "cyl", 0.9, rt)
			if rt >= 0.3 and not _sounds_done.has("ej_all"):
				_sounds_done["ej_all"] = true
				for i in cap - ammo:
					_eject()
		"break":
			var br := _group("break")
			if br:
				br.rotation.x = -smoothstep(0.05, 0.2, rt) * (1.0 - smoothstep(0.82, 0.95, rt)) * 0.6
			_snd("open", "bolt_back", 0.08, rt)
			_snd("s1", "shell", 0.45, rt)
			_snd("s2", "shell", 0.62, rt)
			_snd("close", "bolt_fwd", 0.9, rt)
			if rt >= 0.25 and not _sounds_done.has("ej_all"):
				_sounds_done["ej_all"] = true
				for i in cap - ammo:
					_eject()
	if rt >= 1.0:
		_reload_t = -1.0
		ammo = cap + (1 if _closed_bolt_mag() and not _reload_was_empty else 0)
		if mg:
			mg.visible = true
			mg.transform = info.socks.get("mag", Transform3D())


func _update_hands() -> void:
	var a: Dictionary = info.anchors
	var gt := gun.transform
	var G: Vector3 = gt * a.get("grip", Vector3(0, -0.05, 0.15))
	var Sp: Vector3 = gt * a.get("support", Vector3(-0.015, -0.04, -0.15))
	if _reload_t >= 0.0 and _reload_kind in ["mag", "belt", "tube", "cyl", "break"]:
		var rt := clampf(_reload_t / _reload_dur, 0.0, 1.0)
		var reach := smoothstep(0.05, 0.25, rt) * (1.0 - smoothstep(0.8, 0.95, rt))
		var mw: Vector3 = gt * a.get("magwell", Vector3(0, -0.1, 0.05))
		var away := Vector3(-0.05, -0.18, 0.05) * sin(clampf((rt - 0.3) / 0.35, 0.0, 1.0) * PI)
		Sp = Sp.lerp(mw + away, reach)
	if _cycle_t >= 0.0 and rcv.action == "bolt":
		var knob: Vector3 = a.get("bolt_knob", G)
		var hg := _group("handle")
		if hg:
			knob = gt * (hg.transform * (knob - info.rinfo.pivots.get("handle", Vector3.ZERO)))
		var c := clampf(_cycle_t / _cycle_dur, 0.0, 1.0)
		G = G.lerp(knob, sin(c * PI))
	if _cycle_t >= 0.0 and rcv.action == "pump":
		var pump := _group("pump")
		if pump:
			Sp += Vector3(0, 0, pump.position.z - info.socks.handguard.origin.z)
	_place(hand_r, G, G + Vector3(0.0, -0.08, 0.02), 0.0)
	_place(hand_l, Sp, Sp + Vector3(-0.03, -0.07, 0.0), 0.0)
	var pistol: bool = rcv.fam in ["pistol", "revolver"]
	var sh_r := Vector3(0.3, -0.62, 0.32)
	var sh_l := Vector3(-0.3, -0.62, 0.26) if not pistol else Vector3(-0.16, -0.62, 0.3)
	_place(arm_r, G + Vector3(0, -0.04, 0.03), sh_r, 1.0)
	_place(arm_l, Sp + Vector3(0, -0.03, 0.02), sh_l, 1.0)
	hand_l.visible = gun.visible
	hand_r.visible = gun.visible
	arm_l.visible = gun.visible
	arm_r.visible = gun.visible


## Stretches a capsule between two points in weapon space.
func _place(mi: MeshInstance3D, a: Vector3, b: Vector3, stretch: float) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.001:
		return
	var y := d / len
	var x := y.cross(Vector3.FORWARD)
	if x.length_squared() < 1e-5:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y)
	var cm: CapsuleMesh = mi.mesh
	var sy := len / cm.height if stretch > 0.0 else 1.0
	var mid := a + d * 0.5 if stretch > 0.0 else a + y * cm.height * 0.35
	mi.transform = Transform3D(Basis(x, y * sy, z), mid)


func _update_laser() -> void:
	var lp := Vector3.ZERO
	var has := false
	for slot in ["side", "under"]:
		var pi: Dictionary = info.parts.get(slot, {})
		if pi.has("laser"):
			lp = pi.laser
			has = true
	if not has or not gun.visible:
		laser_dot.visible = false
		return
	var from := gun.to_global(lp)
	var to := from + -gun.global_basis.z * 300.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1 | 2
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		laser_dot.visible = true
		laser_dot.global_position = hit.position + hit.normal * 0.003
		var d := cam.global_position.distance_to(hit.position)
		laser_dot.scale = Vector3.ONE * clampf(d * 0.25, 0.5, 30.0)
	else:
		laser_dot.visible = false

extends Node3D
## Projectile simulation: point-mass with quadratic drag, gravity and wind,
## stepped at 240 Hz with a ray per step. Handles penetration (by material and
## thickness), ricochets, explosions and hit reporting.

signal hit_report(info: Dictionary)

const STEP := 1.0 / 240.0
const MAX_LIFE := 9.0
## Steel-equivalent resistance per mm of material.
const RESIST := {
	"steel": 1.0, "armor": 1.6, "concrete": 0.22, "wood": 0.035, "glass": 0.04, "gel": 0.0075,
	"dummy": 0.012, "melon": 0.006, "paper": 0.0, "plastic": 0.02, "dirt": 0.5, "water": 0.02, "tire": 0.03,
}
## Materials that stop bullets outright (ground, berms).
const SOLID := ["dirt", "rock"]

var bullets: Array = []
var _acc := 0.0
var _tracer_mesh: BoxMesh
var _tracer_mat: StandardMaterial3D
var _trail_mat: StandardMaterial3D
var wind := Vector3.ZERO


func _ready() -> void:
	_tracer_mesh = BoxMesh.new()
	_tracer_mesh.size = Vector3(1, 1, 1)
	_tracer_mat = StandardMaterial3D.new()
	_tracer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tracer_mat.albedo_color = Color(1.0, 0.45, 0.2)
	_tracer_mat.emission_enabled = true
	_tracer_mat.emission = Color(1.0, 0.4, 0.15)
	_tracer_mat.emission_energy_multiplier = 6.0
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.albedo_color = Color(1, 1, 0.9, 0.35)
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	update_wind()


func update_wind() -> void:
	var a := deg_to_rad(float(Game.settings.wind_dir))
	wind = Vector3(sin(a), 0, -cos(a)) * float(Game.settings.wind)


## Fires one projectile. proj is a Cal.projectile() dictionary (per pellet).
## `shot` carries the shooter's line of sight for drop reporting.
func fire(pos: Vector3, vel: Vector3, proj: Dictionary, shot: Dictionary) -> void:
	var b := {
		"p": pos, "v": vel, "k": Cal.drag_k(proj), "kg": proj.kg, "pen": proj.pen, "dmg": proj.dmg,
		"v0": vel.length(), "t": 0.0, "origin": pos, "shot": shot, "explosive": proj.explosive,
		"smoke": proj.smoke, "incendiary": proj.incendiary, "dist": 0.0, "pellet": proj.pellets > 1, "hits": 0,
	}
	var trails: int = int(Game.settings.trails)
	if proj.tracer or proj.explosive > 0.0 or trails == 2:
		var mi := MeshInstance3D.new()
		mi.mesh = _tracer_mesh
		mi.material_override = _tracer_mat if (proj.tracer or proj.explosive > 0.0) else _trail_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		b["tr"] = mi
		b["tr_w"] = 0.012 if proj.tracer else 0.006
		if proj.explosive > 0.0:
			b["tr_w"] = 0.05
	bullets.append(b)


func _physics_process(delta: float) -> void:
	_acc += delta
	var space := get_world_3d().direct_space_state
	while _acc >= STEP:
		_acc -= STEP
		var i := 0
		while i < bullets.size():
			if _step(bullets[i], space):
				i += 1
			else:
				_kill(i)
	for b in bullets:
		if b.has("tr"):
			var mi: MeshInstance3D = b.tr
			var sp: float = b.v.length()
			var len := clampf(sp * 0.03, 0.2, 25.0)
			if b.t < 0.02:
				mi.visible = false
				continue
			mi.visible = true
			var dir: Vector3 = b.v / maxf(sp, 0.01)
			var up := Vector3.UP if absf(dir.y) < 0.98 else Vector3.RIGHT
			var w: float = b.tr_w * (1.0 + b.dist * 0.004)
			mi.global_transform = Transform3D(Basis.looking_at(dir, up).scaled(Vector3(w, w, len)), b.p - dir * len * 0.5)


func _kill(i: int) -> void:
	var b: Dictionary = bullets[i]
	if b.has("tr"):
		b.tr.queue_free()
	bullets.remove_at(i)


func _step(b: Dictionary, space: PhysicsDirectSpaceState3D) -> bool:
	b.t += STEP
	if b.t > MAX_LIFE or b.p.y < -100.0:
		return false
	var rel: Vector3 = b.v - wind
	var sp := rel.length()
	b.v += (Vector3(0, -9.81, 0) - rel * sp * b.k) * STEP
	var from: Vector3 = b.p
	var to: Vector3 = from + b.v * STEP
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1 | 2
	q.hit_back_faces = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		b.dist += from.distance_to(to)
		b.p = to
		return true
	b.dist += from.distance_to(hit.position)
	return _impact(b, hit, space)


func _impact(b: Dictionary, hit: Dictionary, space: PhysicsDirectSpaceState3D) -> bool:
	var col: Object = hit.collider
	var mat: String = col.get_meta("mat", "dirt") if col else "dirt"
	var pos: Vector3 = hit.position
	var n: Vector3 = hit.normal
	var v: Vector3 = b.v
	var sp := v.length()
	var dir := v / maxf(sp, 0.01)
	var energy: float = 0.5 * b.kg * sp * sp
	var dist_from_shooter: float = (pos - b.shot.get("eye", b.origin)).length()
	var fx_scale := clampf(dist_from_shooter / 60.0, 1.0, 10.0)
	if b.explosive > 0.0:
		_explode(pos + n * 0.1, b.explosive, b)
		return false
	if b.smoke:
		Fx.smoke_cloud(pos)
		return false
	# Report the hit (first impact of each projectile, any pellet).
	var los_dir: Vector3 = b.shot.get("dir", dir)
	var eye: Vector3 = b.shot.get("eye", b.origin)
	var along := (pos - eye).dot(los_dir)
	var drop := (eye + los_dir * along - pos).dot(Vector3.UP)
	var info := {
		"pos": pos, "normal": n, "dir": dir, "v": sp, "energy": energy, "dmg": sqrt(energy) * 1.2 * b.dmg,
		"mat": mat, "dist": dist_from_shooter, "drop": drop, "tof": b.t, "collider": col, "pellet": b.pellet,
		"incendiary": b.incendiary, "kg": b.kg,
	}
	if col and col.has_method("bullet_hit"):
		col.bullet_hit(info)
	if col is RigidBody3D:
		var rb := col as RigidBody3D
		rb.apply_impulse(dir * b.kg * sp * 4.0, pos - rb.global_position)
	if b.hits == 0:
		hit_report.emit(info)
	b.hits += 1
	Fx.impact(pos, n, mat, fx_scale)
	if col is Node3D and mat not in ["dirt", "rock", "water"]:
		Fx.hole(pos, n, clampf(b.shot.get("d", 0.008) * 1.2, 0.004, 0.03) * (1.0 if mat != "steel" else 1.6), col as Node3D, mat)
	elif mat == "dirt" and dist_from_shooter < 120.0:
		pass
	if mat in SOLID or mat == "water":
		return false
	# Ricochet off hard surfaces at grazing angles.
	var cosi := -dir.dot(n)
	if mat in ["steel", "armor", "concrete"] and cosi < 0.26 and randf() < 0.7:
		b.v = (dir - 2.0 * dir.dot(n) * n).normalized() * sp * 0.55
		b.v = b.v.rotated(Vector3.UP, randf_range(-0.1, 0.1))
		b.p = pos + n * 0.01
		return true
	# Penetration: steel-equivalent capacity falls with the square root of energy.
	var res: float = RESIST.get(mat, 0.3)
	var thick_mm := _thickness_mm(col, pos, dir)
	var e0: float = 0.5 * b.kg * b.v0 * b.v0
	var cap: float = b.pen * sqrt(energy / maxf(e0, 0.001))
	var need: float = thick_mm * res / maxf(cosi, 0.2)
	if col and col.has_method("pen_result"):
		col.pen_result(cap, need, thick_mm)
	if need >= cap:
		return false
	var keep := sqrt(maxf(0.0, 1.0 - need / cap))
	b.v = v * keep
	if mat == "gel" or mat == "dummy" or mat == "melon":
		b.v = b.v.rotated(Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(), randf_range(0.0, 0.2))
	b.p = pos + dir * (thick_mm / 1000.0 / maxf(cosi, 0.2) + 0.002)
	return b.v.length() > 30.0


## Thickness along the shot: per-body "thick" meta (mm) or the box shape.
func _thickness_mm(col: Object, pos: Vector3, dir: Vector3) -> float:
	if col == null:
		return 0.0
	if col.has_meta("thick"):
		return float(col.get_meta("thick"))
	if col is CollisionObject3D:
		var co := col as CollisionObject3D
		for c in co.get_children():
			if c is CollisionShape3D and c.shape is BoxShape3D:
				var cs := c as CollisionShape3D
				var inv := cs.global_transform.affine_inverse()
				var lp := inv * pos
				var ld := (inv.basis * dir).normalized()
				var he: Vector3 = (cs.shape as BoxShape3D).size * 0.5
				var tmax := INF
				for a in 3:
					if absf(ld[a]) > 1e-6:
						var t1 := (he[a] - lp[a]) / ld[a]
						var t2 := (-he[a] - lp[a]) / ld[a]
						tmax = minf(tmax, maxf(t1, t2))
				if tmax < INF:
					var world_len := (cs.global_transform.basis * (ld * tmax)).length()
					return maxf(world_len, 0.0) * 1000.0
			elif c is CollisionShape3D and c.shape is SphereShape3D:
				return (c.shape as SphereShape3D).radius * 2000.0
			elif c is CollisionShape3D and c.shape is CylinderShape3D:
				return (c.shape as CylinderShape3D).radius * 2000.0
	return 99999.0


func _explode(pos: Vector3, radius: float, b: Dictionary) -> void:
	Fx.explosion(pos, radius * 0.5)
	var eye: Vector3 = b.shot.get("eye", pos)
	Sfx.play_delayed("boom", pos, eye.distance_to(pos), 6.0)
	hit_report.emit({"pos": pos, "normal": Vector3.UP, "dir": Vector3.DOWN, "v": b.v.length(), "energy": 0.0, "dmg": 0.0, "mat": "explosion", "dist": eye.distance_to(pos), "drop": 0.0, "tof": b.t, "collider": null, "pellet": false})
	blast(pos, radius, 160.0)


## Damages and pushes everything near an explosion.
func blast(pos: Vector3, radius: float, damage: float) -> void:
	var space := get_world_3d().direct_space_state
	var sq := PhysicsShapeQueryParameters3D.new()
	var sph := SphereShape3D.new()
	sph.radius = radius
	sq.shape = sph
	sq.transform = Transform3D(Basis.IDENTITY, pos)
	sq.collision_mask = 1 | 2
	var seen := {}
	for r in space.intersect_shape(sq, 64):
		var col: Object = r.collider
		if col == null or seen.has(col):
			continue
		seen[col] = true
		var cp: Vector3 = (col as Node3D).global_position
		var d := cp.distance_to(pos)
		var f := clampf(1.0 - d / radius, 0.0, 1.0)
		if col.has_method("blast_hit"):
			col.blast_hit(pos, damage * f)
		if col is RigidBody3D:
			var dirv := (cp - pos + Vector3.UP * 0.5).normalized()
			(col as RigidBody3D).apply_impulse(dirv * 40.0 * f * (col as RigidBody3D).mass * 0.4)

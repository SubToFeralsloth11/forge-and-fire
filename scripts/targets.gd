class_name Targets
extends RefCounted
## Range targets. Every class receives bullet_hit(info) from ballistics.gd.

const UI := preload("res://scripts/ui_kit.gd")


static func box_body(body: CollisionObject3D, size: Vector3, mat: Material, mesh_offset := Vector3.ZERO) -> MeshInstance3D:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = mesh_offset
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = mesh_offset
	body.add_child(mi)
	return mi


static func label3d(text: String, size := 64, col := Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.modulate = col
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	l.pixel_size = 0.004
	return l


# ------------------------------------------------------------------ steel
## A hanging steel plate that swings and rings when hit.
class Steel extends StaticBody3D:
	var swing := 0.0
	var swing_v := 0.0
	var hinge: Node3D
	var hits := 0
	var plate_size := Vector2(0.4, 0.4)
	var shape := "rect"
	var dist := 100.0
	var ring := "steel"

	func setup(sz: Vector2, kind := "rect", d := 100.0) -> void:
		plate_size = sz
		shape = kind
		dist = d
		set_meta("mat", "steel")
		set_meta("thick", 12.0)

	func _ready() -> void:
		var mat := Mats.prop(Color(0.92, 0.92, 0.9), 0.6, 0.2)
		var mi := MeshInstance3D.new()
		if shape == "round":
			var cm := CylinderMesh.new()
			cm.top_radius = plate_size.x * 0.5
			cm.bottom_radius = plate_size.x * 0.5
			cm.height = 0.012
			mi.mesh = cm
			mi.rotation = Vector3(PI * 0.5, 0, 0)
			var cs := CollisionShape3D.new()
			var sh := CylinderShape3D.new()
			sh.radius = plate_size.x * 0.5
			sh.height = 0.012
			cs.shape = sh
			cs.rotation = mi.rotation
			add_child(cs)
			set_meta("thick", 12.0)
		else:
			var bm := BoxMesh.new()
			bm.size = Vector3(plate_size.x, plate_size.y, 0.012)
			mi.mesh = bm
			var cs := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = bm.size
			cs.shape = sh
			add_child(cs)
		mi.material_override = mat
		add_child(mi)
		ring = "steel_hi" if plate_size.x < 0.35 else "steel"

	func bullet_hit(info: Dictionary) -> void:
		hits += 1
		swing_v += clampf(info.kg * info.v * 0.6 / maxf(plate_size.x * plate_size.y * 30.0, 0.5), 0.2, 6.0)
		Sfx.play_delayed(ring, info.pos, info.dist, 4.0 + clampf(info.dist / 200.0, 0.0, 8.0), randf_range(0.95, 1.05))

	func _physics_process(delta: float) -> void:
		if absf(swing) < 0.0001 and absf(swing_v) < 0.0001:
			return
		swing_v += (-swing * 30.0 - swing_v * 2.5) * delta
		swing += swing_v * delta
		rotation.x = -swing * 0.5


# ------------------------------------------------------------------ paper
## Paper target on a frame. Keeps hole positions and shows the group size.
class Paper extends StaticBody3D:
	var holes: Array = []
	var dist := 25.0
	var label: Label3D
	var size := Vector2(0.45, 0.6)

	func _ready() -> void:
		set_meta("mat", "paper")
		set_meta("thick", 0.3)
		var img := Image.create(256, 340, false, Image.FORMAT_RGB8)
		img.fill(Color(0.93, 0.92, 0.86))
		var c := Vector2(128, 150)
		for r in [110, 90, 70, 50, 30, 12]:
			for y in 340:
				for x in 256:
					var d := Vector2(x, y).distance_to(c)
					if absf(d - r) < 1.2:
						img.set_pixel(x, y, Color(0.1, 0.1, 0.1))
					elif r == 12 and d < 12:
						img.set_pixel(x, y, Color(0.8, 0.1, 0.1))
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = ImageTexture.create_from_image(img)
		mat.roughness = 0.95
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = size
		mi.mesh = qm
		mi.material_override = mat
		mi.position.z = 0.006
		add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(size.x, size.y, 0.01)
		cs.shape = sh
		add_child(cs)
		var board := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x + 0.04, size.y + 0.04, 0.01)
		board.mesh = bm
		board.material_override = Mats.prop(Color(0.55, 0.45, 0.32))
		add_child(board)
		label = Targets.label3d("%d m" % int(dist), 48)
		label.position = Vector3(0, size.y * 0.5 + 0.12, 0)
		add_child(label)

	func bullet_hit(info: Dictionary) -> void:
		holes.append(to_local(info.pos))
		if holes.size() > 5:
			holes.pop_front()
		_update()

	func _update() -> void:
		var spread := 0.0
		for a in holes:
			for b in holes:
				spread = maxf(spread, Vector2(a.x, a.y).distance_to(Vector2(b.x, b.y)))
		var moa := rad_to_deg(atan(spread / maxf(dist, 1.0))) * 60.0
		label.text = "%d m  ·  %d-shot group %.1f cm (%.2f MOA)" % [int(dist), holes.size(), spread * 100.0, moa]

	func reset() -> void:
		holes.clear()
		label.text = "%d m" % int(dist)


# ------------------------------------------------------------------ dummy
## A foam training mannequin with hit zones. Topples at 0 HP and resets.
class Dummy extends Node3D:
	var hp := 100.0
	var down := false
	var label: Label3D
	var body: Node3D

	func _ready() -> void:
		body = Node3D.new()
		add_child(body)
		var mat := Mats.prop(Color(0.78, 0.68, 0.5), 0.9)
		var parts := [
			["head", Vector3(0, 1.62, 0), Vector3(0.2, 0.24, 0.22), 2.5],
			["neck", Vector3(0, 1.45, 0), Vector3(0.1, 0.1, 0.1), 2.0],
			["chest", Vector3(0, 1.22, 0), Vector3(0.4, 0.38, 0.24), 1.0],
			["belly", Vector3(0, 0.95, 0), Vector3(0.34, 0.2, 0.22), 0.9],
			["arm_l", Vector3(-0.27, 1.12, 0), Vector3(0.1, 0.56, 0.11), 0.5],
			["arm_r", Vector3(0.27, 1.12, 0), Vector3(0.1, 0.56, 0.11), 0.5],
			["leg_l", Vector3(-0.1, 0.45, 0), Vector3(0.14, 0.8, 0.15), 0.6],
			["leg_r", Vector3(0.1, 0.45, 0), Vector3(0.14, 0.8, 0.15), 0.6],
		]
		for p in parts:
			var sb := DummyPart.new()
			sb.dummy = self
			sb.zone = p[0]
			sb.mult = p[3]
			sb.set_meta("mat", "dummy")
			sb.position = p[1]
			Targets.box_body(sb, p[2], mat)
			body.add_child(sb)
		var stand := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.25
		cm.bottom_radius = 0.3
		cm.height = 0.05
		stand.mesh = cm
		stand.material_override = Mats.prop(Color(0.15, 0.15, 0.15), 0.6, 0.5)
		add_child(stand)
		label = Targets.label3d("100 HP", 40, Color(0.6, 1, 0.6))
		label.position = Vector3(0, 2.0, 0)
		add_child(label)

	func damage(amount: float, zone: String) -> void:
		if down:
			return
		hp -= amount
		var t := Targets.label3d("-%d %s" % [int(amount), zone.to_upper()], 36, Color(1, 0.8, 0.3) if zone != "head" else Color(1, 0.3, 0.2))
		t.position = Vector3(randf_range(-0.2, 0.2), 1.8, 0)
		add_child(t)
		var tw := t.create_tween()
		tw.tween_property(t, "position:y", 2.4, 0.9)
		tw.parallel().tween_property(t, "modulate:a", 0.0, 0.9)
		tw.tween_callback(t.queue_free)
		label.text = "%d HP" % maxi(0, int(hp))
		if hp <= 0.0:
			down = true
			var tw2 := body.create_tween()
			tw2.tween_property(body, "rotation:x", -PI * 0.47, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw2.tween_interval(2.5)
			tw2.tween_property(body, "rotation:x", 0.0, 0.6)
			tw2.tween_callback(reset)

	func reset() -> void:
		hp = 100.0
		down = false
		body.rotation = Vector3.ZERO
		label.text = "100 HP"


class DummyPart extends StaticBody3D:
	var dummy: Dummy
	var zone := "chest"
	var mult := 1.0

	func bullet_hit(info: Dictionary) -> void:
		dummy.damage(info.dmg * mult, zone)
		Sfx.play_delayed("thud", info.pos, info.dist, -4.0)

	func blast_hit(_p: Vector3, dmg: float) -> void:
		dummy.damage(dmg * 0.5, zone)


# ------------------------------------------------------------------ props
## Rigid physics prop that breaks (crate, bottle, melon, cinder block) or
## explodes (barrel, propane tank).
class Prop extends RigidBody3D:
	var hp := 100.0
	var kind := "crate"
	var size := Vector3.ONE
	var home: Transform3D
	var color := Color.WHITE
	var dead := false
	var blast_fn: Callable

	func setup(k: String, sz: Vector3, c: Color, health: float, m: float) -> void:
		kind = k
		size = sz
		color = c
		hp = health
		mass = m
		var mat_name: String = {"crate": "wood", "barrel": "steel", "bottle": "glass", "melon": "melon", "block": "concrete", "propane": "steel", "pumpkin": "melon", "can": "steel", "tire": "tire"}.get(k, "wood")
		set_meta("mat", mat_name)
		if k in ["barrel", "can", "propane"]:
			set_meta("thick", 1.2)

	func _ready() -> void:
		home = global_transform
		continuous_cd = false
		var mi := MeshInstance3D.new()
		var cs := CollisionShape3D.new()
		var mat := Mats.prop(color, 0.7 if kind != "bottle" else 0.1, 0.4 if kind in ["barrel", "can", "propane"] else 0.0)
		match kind:
			"barrel", "bottle", "can", "propane", "tire":
				var cm := CylinderMesh.new()
				cm.top_radius = size.x * 0.5 * (0.35 if kind == "bottle" else 1.0)
				cm.bottom_radius = size.x * 0.5
				cm.height = size.y
				mi.mesh = cm
				var sh := CylinderShape3D.new()
				sh.radius = size.x * 0.5
				sh.height = size.y
				cs.shape = sh
				if kind == "bottle":
					mat = mat.duplicate()
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mat.albedo_color.a = 0.6
			"melon", "pumpkin":
				var sm := SphereMesh.new()
				sm.radius = size.x * 0.5
				sm.height = size.y
				mi.mesh = sm
				var sh := SphereShape3D.new()
				sh.radius = size.x * 0.5
				cs.shape = sh
			_:
				var bm := BoxMesh.new()
				bm.size = size
				mi.mesh = bm
				var sh := BoxShape3D.new()
				sh.size = size
				cs.shape = sh
		mi.material_override = mat
		add_child(mi)
		add_child(cs)
		if kind == "barrel":
			for y in [-0.3, 0.3]:
				var ring := MeshInstance3D.new()
				var tm := TorusMesh.new()
				tm.inner_radius = size.x * 0.5
				tm.outer_radius = size.x * 0.5 + 0.015
				ring.mesh = tm
				ring.material_override = mat
				ring.position.y = y * size.y
				add_child(ring)

	func bullet_hit(info: Dictionary) -> void:
		var s: String = {"crate": "wood", "block": "thud", "bottle": "glass", "melon": "splat", "pumpkin": "splat"}.get(kind, "thud")
		Sfx.play_delayed(s if kind != "bottle" else "glass", info.pos, info.dist, -2.0)
		_take(info.dmg if kind != "barrel" else info.dmg * (2.0 if info.get("incendiary", false) else 1.0))

	func blast_hit(_p: Vector3, dmg: float) -> void:
		_take(dmg)

	func _take(d: float) -> void:
		if dead:
			return
		hp -= d
		if hp <= 0.0:
			_break()

	func _break() -> void:
		dead = true
		var p := global_position
		match kind:
			"barrel", "propane":
				Fx.explosion(p, 3.0 if kind == "barrel" else 2.0)
				Sfx.play("boom", p, 6.0)
				if blast_fn.is_valid():
					blast_fn.call(p, 6.0 if kind == "barrel" else 4.5, 120.0)
			"bottle":
				Fx.impact(p, Vector3.UP, "glass", 1.5)
			"melon", "pumpkin":
				Fx.impact(p, Vector3.UP, "melon", 1.6)
			"block":
				Fx.impact(p, Vector3.UP, "concrete", 2.0)
			_:
				Fx.impact(p, Vector3.UP, "wood", 2.5)
		_spawn_debris()
		visible = false
		collision_layer = 0
		collision_mask = 0
		freeze = true

	func _spawn_debris() -> void:
		if kind in ["bottle", "melon", "pumpkin", "barrel", "propane", "can"]:
			return
		for i in 6:
			var d := RigidBody3D.new()
			d.mass = mass / 6.0
			var s := size * Vector3(randf_range(0.25, 0.5), randf_range(0.25, 0.5), randf_range(0.25, 0.5))
			Targets.box_body(d, s, Mats.prop(color))
			d.set_meta("mat", get_meta("mat"))
			get_parent().add_child(d)
			d.global_position = global_position + Vector3(randf_range(-0.2, 0.2), randf_range(0.0, 0.3), randf_range(-0.2, 0.2)) * size
			d.linear_velocity = Vector3(randf_range(-2, 2), randf_range(1, 4), randf_range(-2, 2))
			d.add_to_group("debris")

	func reset() -> void:
		dead = false
		hp = {"crate": 120.0, "barrel": 90.0, "bottle": 1.0, "melon": 10.0, "block": 260.0, "propane": 60.0, "pumpkin": 14.0, "can": 2.0, "tire": 400.0}.get(kind, 100.0)
		visible = true
		collision_layer = 1
		collision_mask = 1
		freeze = false
		global_transform = home
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO


# ------------------------------------------------------------------ armor plate
## Fixed steel plate of a known thickness. Shows whether rounds go through.
class Plate extends StaticBody3D:
	var mm := 6.0
	var label: Label3D
	var armor := false

	func _ready() -> void:
		set_meta("mat", "armor" if armor else "steel")
		set_meta("thick", mm)
		Targets.box_body(self, Vector3(0.5, 0.5, mm / 1000.0), Mats.prop(Color(0.35, 0.36, 0.38) if not armor else Color(0.25, 0.3, 0.25), 0.5, 0.6))
		label = Targets.label3d("%s %d mm" % ["Armor" if armor else "Steel", int(mm)], 40)
		label.position = Vector3(0, 0.42, 0)
		add_child(label)

	func pen_result(cap: float, need: float, _t: float) -> void:
		var through := need < cap
		label.text = "%s %d mm\n%s  (round could do %.1f mm, needed %.1f)" % ["Armor" if armor else "Steel", int(mm), "PENETRATED" if through else "STOPPED", cap / (1.6 if armor else 1.0), need / (1.6 if armor else 1.0)]
		label.modulate = Color(1, 0.4, 0.3) if through else Color(0.5, 1, 0.5)

	func bullet_hit(info: Dictionary) -> void:
		Sfx.play_delayed("steel_hi", info.pos, info.dist, -2.0)


# ------------------------------------------------------------------ gel
## Ballistic gelatin block. Draws the wound track and reports its depth.
class Gel extends StaticBody3D:
	var label: Label3D
	var depth := 0.6

	func _ready() -> void:
		set_meta("mat", "gel")
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.95, 0.85, 0.55, 0.55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.2
		Targets.box_body(self, Vector3(0.15, 0.15, depth), m, Vector3(0, 0, -depth * 0.5 + 0.0))
		label = Targets.label3d("Ballistic gel", 36)
		label.position = Vector3(0, 0.2, -depth * 0.5)
		add_child(label)

	func bullet_hit(info: Dictionary) -> void:
		# Penetration depth from steel-equivalent capacity (same model as ballistics).
		var cap: float = info.get("cap_hint", 0.0)
		var e: float = info.energy
		var d := clampf(sqrt(e) * 0.012 * (0.55 if info.dmg > sqrt(e) * 1.3 else 1.0), 0.03, depth)
		var line := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.004
		cm.bottom_radius = 0.012
		cm.height = d
		line.mesh = cm
		line.material_override = Mats.prop(Color(0.5, 0.15, 0.1), 0.6)
		add_child(line)
		var lp := to_local(info.pos)
		line.position = lp + Vector3(0, 0, -d * 0.5)
		line.rotation = Vector3(PI * 0.5, 0, 0)
		label.text = "Gel: %.0f cm track" % (d * 100.0)


# ------------------------------------------------------------------ glass
class Glass extends StaticBody3D:
	var mi: MeshInstance3D
	var size := Vector2(1.0, 1.0)

	func _ready() -> void:
		set_meta("mat", "glass")
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.7, 0.85, 0.95, 0.3)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.metallic = 0.6
		m.roughness = 0.05
		mi = Targets.box_body(self, Vector3(size.x, size.y, 0.006), m)

	func bullet_hit(info: Dictionary) -> void:
		Sfx.play_delayed("glass", info.pos, info.dist, 0.0)
		Fx.impact(global_position, Vector3.FORWARD, "glass", 3.0)
		visible = false
		collision_layer = 0

	func reset() -> void:
		visible = true
		collision_layer = 1


# ------------------------------------------------------------------ movers
## Steel silhouette that runs back and forth on a rail (lead practice).
class Mover extends Steel:
	var span := 8.0
	var speed := 3.0
	var t := 0.0
	var base := Vector3.ZERO

	func _ready() -> void:
		super._ready()
		base = position

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		t += delta
		var ph := fmod(t * speed / span, 2.0)
		var x := (ph if ph < 1.0 else 2.0 - ph) * span - span * 0.5
		position = base + Vector3(x, 0, 0)


## Pop-up steel for the timed drill: up on start, falls when hit.
class Popper extends Steel:
	var up := false
	var drill: Object

	func _ready() -> void:
		super._ready()
		rotation.x = -PI * 0.5
		collision_layer = 0

	func raise() -> void:
		up = true
		collision_layer = 1
		create_tween().tween_property(self, "rotation:x", 0.0, 0.2)

	func bullet_hit(info: Dictionary) -> void:
		if not up:
			return
		super.bullet_hit(info)
		up = false
		collision_layer = 0
		create_tween().tween_property(self, "rotation:x", -PI * 0.5, 0.25)
		if drill:
			drill.popper_hit(self)

	func _physics_process(_d: float) -> void:
		pass

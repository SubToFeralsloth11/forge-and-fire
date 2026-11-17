extends Node
## Visual effects: muzzle flash, smoke, impact puffs, sparks, debris, ejected
## casings (with a cheap raycast bounce), bullet holes and explosions.

var root: Node3D
var _quad: QuadMesh
var _cube: BoxMesh
var _casings: Array = []
var _holes: Array = []
var _mats := {}
const MAX_HOLES := 400
const MAX_CASINGS := 60


func _ready() -> void:
	_quad = QuadMesh.new()
	_quad.size = Vector2(1, 1)
	_cube = BoxMesh.new()
	_cube.size = Vector3.ONE


func _mat(key: String, c: Color, unshaded := true, add := false) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.vertex_color_use_as_albedo = true
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[key] = m
	return m


func _burst(pos: Vector3, mat: Material, amount: int, life: float, speed: float, size: float, dir := Vector3.UP, spread := 60.0, grav := Vector3(0, -2, 0), mesh: Mesh = null, color_ramp: Gradient = null) -> void:
	if root == null:
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 0.95
	p.mesh = mesh if mesh else _quad
	p.material_override = mat
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = grav
	p.damping_min = 1.0
	p.damping_max = 3.0
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 1.4))
	p.scale_amount_curve = curve
	if color_ramp:
		p.color_ramp = color_ramp
	else:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		p.color_ramp = g
	root.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)


func muzzle(pos: Vector3, dir: Vector3, flash: float, smoke: float, parent: Node3D = null) -> void:
	if root == null:
		return
	if flash > 0.03:
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.85, 0.5, 1))
		g.set_color(1, Color(1.0, 0.4, 0.1, 0))
		_burst(pos, _mat("flash", Color.WHITE, true, true), 8, 0.06, 6.0 * flash, 0.09 * clampf(flash, 0.3, 2.5), dir, 18.0, Vector3.ZERO, null, g)
		var l := OmniLight3D.new()
		l.light_color = Color(1, 0.7, 0.4)
		l.light_energy = 4.0 * clampf(flash, 0.2, 2.0)
		l.omni_range = 4.0
		root.add_child(l)
		l.global_position = pos + dir * 0.05
		get_tree().create_timer(0.045).timeout.connect(l.queue_free)
	var sg := Gradient.new()
	sg.set_color(0, Color(0.8, 0.8, 0.8, 0.35 * smoke))
	sg.set_color(1, Color(0.8, 0.8, 0.8, 0))
	_burst(pos, _mat("smoke", Color.WHITE, false), 6, 1.4, 1.2, 0.18, dir, 25.0, Vector3(0, 0.4, 0), null, sg)


## Impact puff by material. `scale` grows with distance so far hits stay visible.
func impact(pos: Vector3, normal: Vector3, mat: String, scale := 1.0) -> void:
	match mat:
		"steel":
			var g := Gradient.new()
			g.set_color(0, Color(1, 0.9, 0.5, 1))
			g.set_color(1, Color(1, 0.4, 0.1, 0))
			_burst(pos, _mat("spark", Color.WHITE, true, true), 14, 0.35, 9.0, 0.03 * scale, normal, 70.0, Vector3(0, -9, 0), null, g)
			_dust(pos, normal, Color(0.5, 0.5, 0.5), scale * 0.6)
		"wood":
			_burst(pos, _mat("chip", Color(0.6, 0.45, 0.28), false), 10, 0.8, 4.0, 0.025 * scale, normal, 50.0, Vector3(0, -9, 0), _cube)
			_dust(pos, normal, Color(0.65, 0.55, 0.4), scale * 0.5)
		"glass":
			_burst(pos, _mat("shard", Color(0.8, 0.9, 1.0, 0.7), false), 18, 1.0, 3.5, 0.03 * scale, normal, 90.0, Vector3(0, -9, 0), _cube)
		"melon":
			_burst(pos, _mat("pulp", Color(0.85, 0.15, 0.2), false), 26, 0.9, 5.0, 0.05 * scale, Vector3.UP, 80.0, Vector3(0, -9, 0), _cube)
		"gel", "dummy":
			_dust(pos, normal, Color(0.95, 0.9, 0.75), scale * 0.5)
		"paper":
			_burst(pos, _mat("paper", Color(0.95, 0.95, 0.9), false), 4, 0.6, 1.5, 0.012 * scale, -normal, 40.0, Vector3(0, -3, 0), _cube)
		"concrete":
			_dust(pos, normal, Color(0.7, 0.7, 0.68), scale)
			_burst(pos, _mat("chip_c", Color(0.6, 0.6, 0.58), false), 8, 0.6, 3.0, 0.02 * scale, normal, 50.0, Vector3(0, -9, 0), _cube)
		"water":
			_burst(pos, _mat("splash", Color(0.8, 0.9, 1.0, 0.8), false), 16, 0.8, 5.0, 0.06 * scale, Vector3.UP, 15.0, Vector3(0, -9, 0))
		_:
			_dust(pos, normal, Color(0.55, 0.45, 0.33), scale)


func _dust(pos: Vector3, normal: Vector3, c: Color, scale: float) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(c.r, c.g, c.b, 0.85))
	g.set_color(1, Color(c.r, c.g, c.b, 0))
	_burst(pos, _mat("dust", Color.WHITE, false), 8, 1.2, 2.5, 0.25 * scale, normal + Vector3.UP * 0.5, 35.0, Vector3(0, -1.5, 0), null, g)


func explosion(pos: Vector3, radius: float) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.9, 0.6, 1))
	g.add_point(0.25, Color(1, 0.45, 0.1, 0.9))
	g.set_color(1, Color(0.15, 0.13, 0.12, 0))
	_burst(pos, _mat("fire", Color.WHITE, true, false), 40, 1.2, radius * 3.0, radius * 0.6, Vector3.UP, 180.0, Vector3(0, 1.5, 0), null, g)
	var sg := Gradient.new()
	sg.set_color(0, Color(0.25, 0.23, 0.2, 0.8))
	sg.set_color(1, Color(0.4, 0.38, 0.35, 0))
	_burst(pos + Vector3.UP * 0.5, _mat("smoke2", Color.WHITE, false), 24, 4.0, radius * 1.2, radius * 0.9, Vector3.UP, 70.0, Vector3(0, 1.0, 0), null, sg)
	_burst(pos, _mat("chip_c", Color(0.4, 0.35, 0.3), false), 30, 1.5, radius * 5.0, 0.06, Vector3.UP, 80.0, Vector3(0, -9.8, 0), _cube)
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.6, 0.3)
	l.light_energy = 12.0
	l.omni_range = radius * 5.0
	root.add_child(l)
	l.global_position = pos + Vector3.UP
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


func smoke_cloud(pos: Vector3) -> void:
	var sg := Gradient.new()
	sg.set_color(0, Color(0.85, 0.85, 0.85, 0.9))
	sg.set_color(1, Color(0.85, 0.85, 0.85, 0))
	_burst(pos, _mat("smoke3", Color.WHITE, false), 60, 12.0, 2.0, 4.0, Vector3.UP, 90.0, Vector3(0, 0.15, 0), null, sg)


## A bullet hole decal on a surface. Parented to the hit node so it moves with it.
func hole(pos: Vector3, normal: Vector3, size: float, parent: Node3D, mat_name: String) -> void:
	if parent == null:
		return
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	var key := "hole_" + mat_name
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.03, 0.03, 0.03) if mat_name != "steel" else Color(0.75, 0.75, 0.72)
		if mat_name == "paper":
			m.albedo_color = Color(0.05, 0.05, 0.05)
		m.roughness = 0.9
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if mat_name == "paper" else BaseMaterial3D.SHADING_MODE_PER_PIXEL
		_mats[key] = m
	mi.material_override = _mats[key]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	mi.global_transform = Transform3D(Basis.looking_at(-normal, up), pos + normal * 0.002)
	_holes.append(mi)
	if _holes.size() > MAX_HOLES:
		var old = _holes.pop_front()
		if is_instance_valid(old):
			old.queue_free()


func clear_holes() -> void:
	for h in _holes:
		if is_instance_valid(h):
			h.queue_free()
	_holes.clear()


# ------------------------------------------------------------------ casings
func casing(pos: Vector3, vel: Vector3, cal: Dictionary) -> void:
	if root == null or cal.hull == "none":
		return
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	var r: float = cal.cw * 0.0005
	cm.top_radius = r * (0.85 if cal.hull != "hull" else 1.0)
	cm.bottom_radius = r
	cm.height = cal.cl * 0.001 * (0.75 if cal.hull != "hull" else 0.95)
	cm.radial_segments = 8
	cm.rings = 1
	mi.mesh = cm
	var mat := "brass"
	if cal.hull == "steel":
		mat = "steel"
	mi.material_override = Mats.get_mat(mat) if cal.hull != "hull" else Mats.prop(Color(0.75, 0.1, 0.08), 0.6)
	root.add_child(mi)
	mi.global_position = pos
	mi.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
	_casings.append({"n": mi, "v": vel, "w": Vector3(randf_range(-20, 20), randf_range(-20, 20), randf_range(-20, 20)), "t": 0.0, "rest": false, "tinked": false})
	if _casings.size() > MAX_CASINGS:
		var c = _casings.pop_front()
		if is_instance_valid(c.n):
			c.n.queue_free()


func _physics_process(delta: float) -> void:
	if _casings.is_empty() or root == null or not root.is_inside_tree():
		return
	var space := root.get_world_3d().direct_space_state
	var i := 0
	while i < _casings.size():
		var c: Dictionary = _casings[i]
		var n: MeshInstance3D = c.n
		if not is_instance_valid(n):
			_casings.remove_at(i)
			continue
		c.t += delta
		if c.t > 12.0:
			n.queue_free()
			_casings.remove_at(i)
			continue
		if not c.rest:
			c.v += Vector3(0, -9.8, 0) * delta
			var from := n.global_position
			var to: Vector3 = from + c.v * delta
			var q := PhysicsRayQueryParameters3D.create(from, to)
			q.collision_mask = 1
			var hit := space.intersect_ray(q)
			if hit:
				n.global_position = hit.position + hit.normal * 0.004
				c.v = c.v.bounce(hit.normal) * 0.35
				c.w *= 0.5
				if not c.tinked:
					c.tinked = true
					Sfx.play("tink", hit.position, -14.0, randf_range(0.8, 1.3))
				if c.v.length() < 0.4:
					c.rest = true
					n.rotation = Vector3(0, n.rotation.y, PI * 0.5)
			else:
				n.global_position = to
				n.rotation += c.w * delta
		i += 1

extends Node3D
## The proving ground: a covered firing line, paper and steel out to 1,500 m,
## dummies, a destruction yard, armour plates, gel, movers and a timed drill.

const Bal := preload("res://scripts/ballistics.gd")

const LONG := [[100.0, -6.0, 0.3], [200.0, -3.0, 0.4], [300.0, 0.0, 0.5], [400.0, 3.0, 0.6], [500.0, 6.0, 0.7], [600.0, -9.0, 0.8], [700.0, -2.0, 0.9], [800.0, 4.0, 1.0], [1000.0, 0.0, 1.2], [1200.0, -12.0, 1.5], [1500.0, 12.0, 1.8]]

var bal: Node3D
var spawn := Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 2.2))
var resettable: Array = []
var poppers: Array = []
var drill_on := false
var drill_t := 0.0
var drill_hits := 0
var drill_best := 0.0
var drill_label: Label3D
var drill_button: Vector3
var flags: Array = []
var env: Environment
var sun: DirectionalLight3D


var we: WorldEnvironment


func _ready() -> void:
	bal = Bal.new()
	bal.name = "Ballistics"
	add_child(bal)
	Fx.root = self
	_env()
	_ground()
	_firing_line()
	_long_range()
	_paper_lane()
	_dummies()
	_yard()
	_armor_and_gel()
	_movers()
	_drill()
	_trees()
	_flags()


func _env() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.22, 0.42, 0.72)
	sm.sky_horizon_color = Color(0.66, 0.74, 0.82)
	sm.ground_horizon_color = Color(0.55, 0.55, 0.5)
	sm.ground_bottom_color = Color(0.25, 0.24, 0.2)
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.55
	env.ambient_light_color = Color(0.62, 0.6, 0.56)
	env.ambient_light_energy = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.76, 0.84)
	env.fog_density = 0.00018
	env.fog_aerial_perspective = 0.4
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.ssao_enabled = true
	we = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	add_child(sun)


func _static_box(size: Vector3, pos: Vector3, mat: Material, mat_name := "dirt", rot := Vector3.ZERO, parent: Node = self) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.set_meta("mat", mat_name)
	Targets.box_body(sb, size, mat)
	parent.add_child(sb)
	sb.position = pos
	sb.rotation_degrees = rot
	return sb


func _ground() -> void:
	var n := FastNoiseLite.new()
	n.frequency = 0.03
	n.fractal_octaves = 4
	var g := Gradient.new()
	g.set_color(0, Color(0.26, 0.33, 0.16))
	g.set_color(1, Color(0.42, 0.46, 0.25))
	g.add_point(0.6, Color(0.36, 0.38, 0.2))
	var t := NoiseTexture2D.new()
	t.noise = n
	t.color_ramp = g
	t.seamless = true
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(0.05, 0.05, 0.05)
	m.roughness = 0.95
	var gb := StaticBody3D.new()
	gb.set_meta("mat", "dirt")
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(6000, 2, 6000)
	cs.shape = sh
	cs.position = Vector3(0, -1, -1000)
	gb.add_child(cs)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6000, 6000)
	mi.mesh = pm
	mi.material_override = m
	mi.position = Vector3(0, 0, -1000)
	gb.add_child(mi)
	add_child(gb)
	# Mown lane down range.
	var lane := MeshInstance3D.new()
	var lm := PlaneMesh.new()
	lm.size = Vector2(40, 1600)
	lane.mesh = lm
	lane.material_override = Mats.prop(Color(0.47, 0.5, 0.3), 0.95)
	lane.position = Vector3(0, 0.01, -800)
	add_child(lane)
	# Backstop hills.
	var dirt := Mats.prop(Color(0.42, 0.33, 0.22), 0.95)
	for i in 9:
		_berm(Vector3(-160 + i * 40, 0, -1680 - (i % 3) * 30), Vector3(70, 45 + (i % 4) * 12, 60), dirt)
	_berm(Vector3(-28, 0, -62), Vector3(30, 6, 8), dirt)
	_berm(Vector3(45, 0, -70), Vector3(50, 7, 8), dirt)
	_berm(Vector3(-55, 0, -122), Vector3(40, 7, 8), dirt)


func _berm(pos: Vector3, size: Vector3, mat: Material) -> void:
	var sb := StaticBody3D.new()
	sb.set_meta("mat", "dirt")
	var pm := PrismMesh.new()
	pm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = mat
	mi.position.y = size.y * 0.5
	sb.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.shape = pm.create_convex_shape()
	cs.position.y = size.y * 0.5
	sb.add_child(cs)
	add_child(sb)
	sb.position = pos


func _sign(text: String, pos: Vector3, size := 160, col := Color.WHITE) -> Label3D:
	var l := Targets.label3d(text, size, col)
	l.pixel_size = 0.006
	l.position = pos
	add_child(l)
	return l


func _firing_line() -> void:
	var conc := Mats.prop(Color(0.62, 0.61, 0.58), 0.9)
	_static_box(Vector3(34, 0.2, 7), Vector3(0, 0.0, 1.8), conc, "concrete")
	var wood := Mats.get_mat("main", "Walnut")
	var steel := Mats.prop(Color(0.25, 0.26, 0.27), 0.5, 0.6)
	# Roof (set back so the sky stays visible) + posts between the benches.
	_static_box(Vector3(34, 0.15, 5.2), Vector3(0, 3.4, 2.8), Mats.prop(Color(0.55, 0.56, 0.58), 0.7, 0.3), "steel")
	for x in [-16.5, -6.0, 6.0, 16.5]:
		for z in [0.4, 5.2]:
			_static_box(Vector3(0.18, 3.3, 0.18), Vector3(x, 1.7, z), steel, "steel")
	# Shooting benches with sandbags.
	for i in 7:
		var x := -12.0 + i * 4.0
		_static_box(Vector3(1.5, 0.08, 0.8), Vector3(x, 0.86, 0.0), wood, "wood")
		for lx in [-0.65, 0.65]:
			_static_box(Vector3(0.08, 0.8, 0.7), Vector3(x + lx, 0.45, 0.0), steel, "steel")
		_static_box(Vector3(0.36, 0.12, 0.22), Vector3(x, 0.96, -0.2), Mats.prop(Color(0.6, 0.53, 0.38), 1.0), "wood")
		_sign(str(i + 1), Vector3(x, 3.1, 0.3), 40, Color(1, 0.8, 0.3))
	# Prone mats in front of the benches.
	for x in [-14.0, 14.0]:
		var mat := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 0.03, 2.4)
		mat.mesh = bm
		mat.material_override = Mats.prop(Color(0.2, 0.25, 0.18), 1.0)
		mat.position = Vector3(x, 0.115, 1.0)
		add_child(mat)
	_sign("FORGE & FIRE PROVING GROUND", Vector3(0, 3.75, 0.25), 70, Color(1, 0.6, 0.3))


func _long_range() -> void:
	for spec in LONG:
		var d: float = spec[0]
		var x: float = spec[1]
		var sz: float = spec[2]
		var post := Mats.prop(Color(0.3, 0.3, 0.3), 0.6, 0.5)
		var frame_h := sz + 0.9
		_static_box(Vector3(0.08, frame_h, 0.08), Vector3(x - sz * 0.6 - 0.1, frame_h * 0.5, -d), post, "steel")
		_static_box(Vector3(0.08, frame_h, 0.08), Vector3(x + sz * 0.6 + 0.1, frame_h * 0.5, -d), post, "steel")
		_static_box(Vector3(sz * 1.2 + 0.3, 0.06, 0.06), Vector3(x, frame_h, -d), post, "steel")
		var hinge := Node3D.new()
		hinge.position = Vector3(x, frame_h - 0.03, -d)
		add_child(hinge)
		var st := Targets.Steel.new()
		st.setup(Vector2(sz, sz * (1.3 if int(d) % 200 == 0 else 1.0)), "round" if int(d) % 200 != 0 else "rect", d)
		hinge.add_child(st)
		st.position = Vector3(0, -0.12 - sz * 0.6, 0)
		st.set_meta("label", "%d m steel" % int(d))
		_sign("%d m" % int(d), Vector3(x, frame_h + 0.5 + d * 0.002, -d), 100 + int(d * 0.14), Color(1, 0.9, 0.4))
	_sign("100", Vector3(-19, 0.8, -100), 80)


func _paper_lane() -> void:
	for spec in [[7.0, -19.0], [15.0, -17.5], [25.0, -16.0], [50.0, -14.5], [100.0, -13.0]]:
		var stand := Mats.prop(Color(0.5, 0.4, 0.28))
		var z := -float(spec[0])
		var x: float = spec[1]
		for lx in [-0.3, 0.3]:
			_static_box(Vector3(0.05, 1.5, 0.05), Vector3(x + lx, 0.75, z - 0.03), stand, "wood")
		var p := Targets.Paper.new()
		p.dist = spec[0]
		add_child(p)
		p.position = Vector3(x, 1.35, z)
		resettable.append(p)


func _dummies() -> void:
	for spec in [[10.0, 14.0], [20.0, 16.0], [35.0, 18.0], [50.0, 15.0], [75.0, 20.0]]:
		var dm := Targets.Dummy.new()
		add_child(dm)
		dm.position = Vector3(spec[1], 0, -spec[0])
		resettable.append(dm)
	_sign("DUMMIES", Vector3(17, 3.0, -8), 90)


func _prop(kind: String, size: Vector3, pos: Vector3, col: Color, hp: float, mass: float) -> void:
	var p := Targets.Prop.new()
	p.setup(kind, size, col, hp, mass)
	p.blast_fn = bal.blast
	add_child(p)
	p.position = pos
	resettable.append(p)


func _yard() -> void:
	var base := Vector3(40, 0, -30)
	_sign("DESTRUCTION YARD", base + Vector3(0, 4, 8), 110)
	# Crate stacks.
	for i in 3:
		for j in 3 - i:
			_prop("crate", Vector3(0.8, 0.8, 0.8), base + Vector3(-8 + j * 0.82 + i * 0.41, 0.4 + i * 0.81, 0), Color(0.62, 0.48, 0.3), 120, 25)
	# Explosive barrels.
	for i in 4:
		_prop("barrel", Vector3(0.6, 0.9, 0.6), base + Vector3(-2 + i * 0.75, 0.45, -2), Color(0.75, 0.12, 0.08), 90, 60)
	_prop("propane", Vector3(0.35, 0.8, 0.35), base + Vector3(2.5, 0.4, -2), Color(0.9, 0.9, 0.88), 60, 15)
	# Table with bottles, cans and melons.
	var wood := Mats.get_mat("main", "Walnut")
	_static_box(Vector3(4, 0.08, 0.8), base + Vector3(6, 0.9, 0), wood, "wood")
	for lx in [-1.8, 1.8]:
		_static_box(Vector3(0.08, 0.86, 0.7), base + Vector3(6 + lx, 0.45, 0), wood, "wood")
	for i in 5:
		_prop("bottle", Vector3(0.08, 0.28, 0.08), base + Vector3(4.4 + i * 0.35, 1.08, 0), Color(0.2, 0.55, 0.25), 1, 0.4)
	for i in 3:
		_prop("melon", Vector3(0.28, 0.28, 0.28), base + Vector3(6.4 + i * 0.4, 1.09, 0.1), Color(0.18, 0.45, 0.15), 10, 4)
	for i in 3:
		_prop("can", Vector3(0.07, 0.12, 0.07), base + Vector3(7.7 + i * 0.12, 1.0, -0.1), Color(0.75, 0.75, 0.8), 2, 0.3)
	_prop("pumpkin", Vector3(0.38, 0.32, 0.38), base + Vector3(5.6, 1.1, -0.2), Color(0.9, 0.45, 0.1), 14, 6)
	# Cinder block wall.
	for row in 4:
		for i in 6:
			_prop("block", Vector3(0.39, 0.19, 0.19), base + Vector3(10 + i * 0.4 + (0.2 if row % 2 == 1 else 0.0), 0.1 + row * 0.2, -1), Color(0.6, 0.6, 0.58), 260, 12)
	# Glass panes.
	for i in 3:
		var g := Targets.Glass.new()
		g.size = Vector2(1.0, 1.2)
		add_child(g)
		g.position = base + Vector3(-6 + i * 1.3, 1.0, -6)
		_static_box(Vector3(1.1, 0.1, 0.1), base + Vector3(-6 + i * 1.3, 0.35, -6), Mats.prop(Color(0.3, 0.3, 0.3)), "steel")
		resettable.append(g)
	# Old car hulk: thin sheet metal over a frame, glass windows.
	var car := Node3D.new()
	add_child(car)
	car.position = base + Vector3(2, 0, -9)
	var paint := Mats.prop(Color(0.25, 0.35, 0.5), 0.5, 0.4)
	var hull := _static_box(Vector3(1.8, 0.8, 4.2), Vector3(0, 0.75, 0), paint, "steel", Vector3.ZERO, car)
	hull.set_meta("thick", 1.0)
	var cab := _static_box(Vector3(1.6, 0.6, 2.0), Vector3(0, 1.45, 0.2), paint, "steel", Vector3.ZERO, car)
	cab.set_meta("thick", 1.0)
	var eng := _static_box(Vector3(0.9, 0.5, 0.8), Vector3(0, 0.8, -1.4), Mats.prop(Color(0.2, 0.2, 0.2), 0.6, 0.6), "steel", Vector3.ZERO, car)
	eng.set_meta("thick", 60.0)
	for w in [[-0.9, -1.3], [0.9, -1.3], [-0.9, 1.3], [0.9, 1.3]]:
		var wh := StaticBody3D.new()
		wh.set_meta("mat", "tire")
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.35
		cm.bottom_radius = 0.35
		cm.height = 0.25
		mi.mesh = cm
		mi.material_override = Mats.get_mat("rubber")
		wh.add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 0.35
		sh.height = 0.25
		cs.shape = sh
		wh.add_child(cs)
		car.add_child(wh)
		wh.position = Vector3(w[0], 0.35, w[1])
		wh.rotation = Vector3(0, 0, PI * 0.5)
	var ws := Targets.Glass.new()
	ws.size = Vector2(1.5, 0.55)
	car.add_child(ws)
	ws.position = Vector3(0, 1.45, -0.82)
	ws.rotation = Vector3(-0.5, 0, 0)
	resettable.append(ws)


func _armor_and_gel() -> void:
	var base := Vector3(-36, 0, -20)
	_sign("PENETRATION TEST", base + Vector3(0, 3.2, 1), 100)
	var i := 0
	for mm in [3.0, 6.0, 10.0, 15.0, 20.0, 30.0]:
		var p := Targets.Plate.new()
		p.mm = mm
		add_child(p)
		p.position = base + Vector3(-5 + i * 1.6, 1.3, 0)
		_static_box(Vector3(0.1, 1.05, 0.1), base + Vector3(-5 + i * 1.6, 0.52, 0.06), Mats.prop(Color(0.3, 0.3, 0.3)), "steel")
		i += 1
	var ap := Targets.Plate.new()
	ap.mm = 8.0
	ap.armor = true
	add_child(ap)
	ap.position = base + Vector3(-5 + i * 1.6, 1.3, 0)
	_static_box(Vector3(0.1, 1.05, 0.1), base + Vector3(-5 + i * 1.6, 0.52, 0.06), Mats.prop(Color(0.3, 0.3, 0.3)), "steel")
	for k in 3:
		var g := Targets.Gel.new()
		add_child(g)
		g.position = base + Vector3(-3 + k * 2.0, 1.0, 4.0)
		_static_box(Vector3(0.6, 0.9, 0.7), base + Vector3(-3 + k * 2.0, 0.45, 3.65), Mats.prop(Color(0.4, 0.35, 0.3)), "wood")
		resettable.append(g)


func _movers() -> void:
	var base := Vector3(-55, 0, 0)
	_sign("MOVERS  (lead your shots)", base + Vector3(0, 3.0, -48), 100)
	for spec in [[50.0, 2.5, 10.0], [100.0, 4.0, 16.0], [200.0, 5.5, 24.0]]:
		var rail := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(spec[2] + 2.0, 0.1, 0.3)
		rail.mesh = bm
		rail.material_override = Mats.prop(Color(0.3, 0.3, 0.3), 0.6, 0.5)
		rail.position = base + Vector3(0, 0.05, -spec[0])
		add_child(rail)
		var mv := Targets.Mover.new()
		mv.setup(Vector2(0.5, 1.0), "rect", spec[0])
		mv.speed = spec[1]
		mv.span = spec[2]
		add_child(mv)
		mv.position = base + Vector3(0, 0.75, -spec[0])
		_sign("%d m · %.1f m/s" % [int(spec[0]), spec[1]], base + Vector3(spec[2] * 0.5 + 2.0, 1.6, -spec[0]), 70)


func _drill() -> void:
	var base := Vector3(26, 0, 0)
	drill_button = base + Vector3(0, 1.0, 1.2)
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.12
	cm.height = 1.0
	post.mesh = cm
	post.material_override = Mats.prop(Color(0.8, 0.15, 0.1), 0.5)
	post.position = base + Vector3(0, 0.5, 1.2)
	add_child(post)
	drill_label = _sign("TIMED DRILL\nstand here and press E", base + Vector3(0, 2.6, 1.2), 70, Color(1, 0.6, 0.3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 8:
		var pp := Targets.Popper.new()
		pp.setup(Vector2(0.45, 0.75), "rect", 10.0 + i * 4.0)
		pp.drill = self
		var hinge := Node3D.new()
		hinge.position = base + Vector3(rng.randf_range(-7, 7), 0.0, -8.0 - i * 4.0)
		add_child(hinge)
		hinge.add_child(pp)
		pp.position = Vector3(0, 0.5, 0)
		poppers.append(pp)


func start_drill() -> void:
	if drill_on:
		return
	drill_on = true
	drill_hits = 0
	drill_t = -2.0
	drill_label.text = "STAND BY..."
	Sfx.play("beep")
	get_tree().create_timer(1.0).timeout.connect(Sfx.play.bind("beep"))
	get_tree().create_timer(2.0).timeout.connect(_drill_go)


func _drill_go() -> void:
	Sfx.play("buzzer")
	drill_t = 0.0
	for p in poppers:
		p.raise()


func popper_hit(_p: Object) -> void:
	drill_hits += 1
	if drill_hits >= poppers.size():
		drill_on = false
		if drill_best <= 0.0 or drill_t < drill_best:
			drill_best = drill_t
		drill_label.text = "TIME %.2f s   (best %.2f s)\npress E to go again" % [drill_t, drill_best]
		Sfx.play("buzzer")


func _process(delta: float) -> void:
	if drill_on and drill_t >= 0.0:
		drill_t += delta
		drill_label.text = "%.2f s   %d/%d" % [drill_t, drill_hits, poppers.size()]
	elif drill_on:
		drill_t += delta
	var w: Vector3 = bal.wind
	var t := Time.get_ticks_msec() / 1000.0
	for f in flags:
		var fl: Node3D = f
		var ang := atan2(w.x, w.z)
		fl.rotation.y = ang + sin(t * 3.0 + fl.position.z) * 0.15
		var droop := clampf(w.length() / 8.0, 0.1, 1.0)
		fl.rotation.z = -(1.0 - droop) * 1.2


func _trees() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 2.4
	cone.height = 7.0
	cone.radial_segments = 8
	mm.mesh = cone
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var xs := []
	for i in 700:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * rng.randf_range(85.0, 420.0)
		var z := rng.randf_range(-1650.0, 150.0)
		var s := rng.randf_range(0.7, 1.6)
		xs.append(Transform3D(Basis.IDENTITY.scaled(Vector3(s, s * rng.randf_range(0.9, 1.4), s)), Vector3(x, 3.5 * s, z)))
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Mats.prop(Color(0.14, 0.26, 0.12), 0.9)
	add_child(mmi)


func _flags() -> void:
	for d in [50.0, 300.0, 600.0, 1000.0]:
		var pole := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.05
		cm.height = 6.0
		pole.mesh = cm
		pole.material_override = Mats.prop(Color(0.8, 0.8, 0.8), 0.5, 0.5)
		pole.position = Vector3(-22, 3, -d)
		add_child(pole)
		var fl := Node3D.new()
		fl.position = Vector3(-22, 5.7, -d)
		add_child(fl)
		var cloth := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.02, 0.6, 1.2)
		cloth.mesh = bm
		cloth.material_override = Mats.prop(Color(1.0, 0.45, 0.1), 0.9)
		cloth.position = Vector3(0, 0, 0.6)
		fl.add_child(cloth)
		flags.append(fl)


func reset_targets() -> void:
	for r in resettable:
		if is_instance_valid(r) and r.has_method("reset"):
			r.reset()
	for d in get_tree().get_nodes_in_group("debris"):
		d.queue_free()
	for g in resettable:
		if g is Targets.Gel:
			for c in g.get_children():
				if c is MeshInstance3D and c.mesh is CylinderMesh:
					c.queue_free()
	Fx.clear_holes()

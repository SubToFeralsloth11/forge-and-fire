extends Node3D
## The gunsmith bench: pick a platform, swap parts per slot, tune barrel length,
## calibre, ammo and paint, and watch the numbers change live.

signal test_fire

const UI := preload("res://scripts/ui_kit.gd")
const STAT_ROWS := [
	["v", "Muzzle velocity", "m/s", 0.0, 1000.0, true],
	["e", "Muzzle energy", "J", 0.0, 8000.0, true],
	["eff", "Effective range", "m", 0.0, 1200.0, true],
	["moa", "Group size", "MOA", 0.0, 6.0, false],
	["kick", "Recoil per shot", "deg", 0.0, 3.0, false],
	["ads", "Aim-down-sight time", "s", 0.0, 1.0, false],
	["hip", "Hip-fire spread", "deg", 0.0, 6.0, false],
	["kg", "Loaded weight", "kg", 0.0, 15.0, false],
	["rpm", "Fire rate", "rpm", 0.0, 1200.0, true],
	["cap", "Capacity", "rds", 0.0, 100.0, true],
	["pen", "Penetration (steel)", "mm", 0.0, 25.0, true],
	["db", "Loudness", "dB", 120.0, 180.0, false],
]

var build := {}
var gun: Node3D
var cam: Camera3D
var we: WorldEnvironment
var sel_slot := "barrel"
var _undo: Array = []
var _redo: Array = []
var _yaw := -0.55
var _pitch := -0.18
var _dist := 1.3
var _target := Vector3.ZERO
var _drag := false
var _idle := 0.0
var _stats := {}
var _hover_stats := {}
var _length_cm := 0.0
var _markers: Array = []

var ui: Control
var name_edit: LineEdit
var rcv_opt: OptionButton
var cal_opt: OptionButton
var ammo_opt: OptionButton
var blen_slider: HSlider
var blen_label: Label
var slot_box: VBoxContainer
var part_box: VBoxContainer
var param_box: VBoxContainer
var fin_box: GridContainer
var desc_label: Label
var stat_labels := {}
var stat_bars := {}
var traj_label: RichTextLabel
var header_label: Label
var saved_menu: MenuButton
var _rcv_ids: Array = []


func _ready() -> void:
	_setup_scene()
	_setup_ui()
	load_build(Game.build)


# ------------------------------------------------------------------ scene
func _setup_scene() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.055, 0.065)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.48, 0.55)
	env.ambient_light_energy = 0.55
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.4
	we = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.3, 0.33, 0.4)
	sm.sky_horizon_color = Color(0.6, 0.6, 0.62)
	sm.ground_bottom_color = Color(0.1, 0.09, 0.08)
	sm.ground_horizon_color = Color(0.4, 0.38, 0.35)
	sky.sky_material = sm
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	var key := SpotLight3D.new()
	key.position = Vector3(0.9, 1.6, 0.9)
	key.look_at_from_position(key.position, Vector3.ZERO)
	key.spot_angle = 38
	key.spot_range = 6
	key.light_energy = 6.0
	key.light_color = Color(1.0, 0.95, 0.88)
	key.shadow_enabled = true
	add_child(key)
	var rim := SpotLight3D.new()
	rim.position = Vector3(-1.0, 1.1, -1.2)
	rim.look_at_from_position(rim.position, Vector3.ZERO)
	rim.spot_angle = 40
	rim.spot_range = 6
	rim.light_energy = 4.0
	rim.light_color = Color(0.7, 0.8, 1.0)
	add_child(rim)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-0.6, 0.5, 1.2)
	fill.light_energy = 0.8
	fill.omni_range = 4
	add_child(fill)
	# Bench: walnut top, steel legs, pegboard wall.
	var top := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 0.08, 1.4)
	top.mesh = bm
	top.material_override = Mats.get_mat("main", "Walnut")
	top.position = Vector3(0, -0.32, 0)
	add_child(top)
	var mat_mi := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(1.6, 0.006, 0.7)
	mat_mi.mesh = mm
	mat_mi.material_override = Mats.prop(Color(0.12, 0.2, 0.16), 0.95)
	mat_mi.position = Vector3(0, -0.277, 0)
	add_child(mat_mi)
	var wall := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(6, 3, 0.05)
	wall.mesh = wm
	wall.material_override = Mats.prop(Color(0.28, 0.24, 0.2), 0.9)
	wall.position = Vector3(0, 0.6, -1.2)
	add_child(wall)
	var floor_mi := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(10, 0.05, 10)
	floor_mi.mesh = fm
	floor_mi.material_override = Mats.prop(Color(0.16, 0.16, 0.17), 0.8)
	floor_mi.position = Vector3(0, -1.2, 0)
	add_child(floor_mi)
	for i in 14:
		for j in 6:
			var hole := MeshInstance3D.new()
			var hm := CylinderMesh.new()
			hm.top_radius = 0.008
			hm.bottom_radius = 0.008
			hm.height = 0.01
			hole.mesh = hm
			hole.material_override = Mats.get_mat("bore")
			hole.rotation = Vector3(PI * 0.5, 0, 0)
			hole.position = Vector3(-1.3 + i * 0.2, 0.1 + j * 0.2, -1.17)
			add_child(hole)
	cam = Camera3D.new()
	cam.fov = 40
	cam.near = 0.02
	add_child(cam)
	cam.current = true


func _update_cam(delta: float) -> void:
	_idle += delta
	if _idle > 6.0:
		_yaw += delta * 0.12
	var dir := Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch))
	cam.position = _target + dir * _dist
	cam.look_at(_target, Vector3.UP)


func _process(delta: float) -> void:
	if not visible:
		return
	_update_cam(delta)
	var mp := get_viewport().get_mouse_position()
	for m in _markers:
		var mi: MeshInstance3D = m[0]
		var on: bool = m[1] == sel_slot
		var sp := cam.unproject_position(mi.global_position)
		var near := sp.distance_to(mp) < 14.0
		mi.scale = Vector3.ONE * (1.6 if on or near else 1.0)


func _unhandled_input(ev: InputEvent) -> void:
	if not visible:
		return
	if ev is InputEventMouseButton:
		_idle = 0.0
		if ev.button_index == MOUSE_BUTTON_RIGHT or ev.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = ev.pressed
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			_dist = maxf(0.25, _dist * 0.9)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			_dist = minf(4.0, _dist * 1.1)
		elif ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
			_pick_marker(ev.position)
	elif ev is InputEventMouseMotion and _drag:
		_idle = 0.0
		_yaw -= ev.relative.x * 0.008
		_pitch = clampf(_pitch + ev.relative.y * 0.006, -1.3, 1.3)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_Z and ev.ctrl_pressed:
			_do_undo()
		elif ev.keycode == KEY_Y and ev.ctrl_pressed:
			_do_redo()
		elif ev.keycode == KEY_ENTER:
			_on_test()


func _pick_marker(p: Vector2) -> void:
	var best := ""
	var bd := 16.0
	for m in _markers:
		var sp := cam.unproject_position(m[0].global_position)
		if sp.distance_to(p) < bd:
			bd = sp.distance_to(p)
			best = m[1]
	if best != "":
		select_slot(best)


# ------------------------------------------------------------------ build
func load_build(b: Dictionary) -> void:
	build = b.duplicate(true)
	Gun.validate(build)
	_rebuild(true)


func _push_undo() -> void:
	_undo.append(build.duplicate(true))
	if _undo.size() > 60:
		_undo.pop_front()
	_redo.clear()


func _do_undo() -> void:
	if _undo.is_empty():
		return
	_redo.append(build.duplicate(true))
	build = _undo.pop_back()
	_rebuild(false)


func _do_redo() -> void:
	if _redo.is_empty():
		return
	_undo.append(build.duplicate(true))
	build = _redo.pop_back()
	_rebuild(false)


func _rebuild(reframe: bool) -> void:
	Gun.validate(build)
	Game.build = build
	if gun:
		gun.queue_free()
	gun = Gun.assemble(build)
	add_child(gun)
	var aabb := _gun_aabb(gun)
	_length_cm = aabb.size.z * 100.0
	gun.position = Vector3(-aabb.get_center().x, -0.27 - aabb.position.y + 0.06, -aabb.get_center().z)
	if reframe:
		_target = Vector3(0, gun.position.y + aabb.get_center().y, 0)
		_dist = clampf(aabb.size.z * 1.35 + 0.25, 0.45, 3.0)
	_place_markers()
	_stats = Gun.compute(build)
	_hover_stats = {}
	_refresh_ui()
	if not Parts.RCV[build.rcv].slots.has(sel_slot) or not Gun.slot_available(build, sel_slot):
		sel_slot = "barrel"
	_fill_parts()


## Bounding box of every mesh under `n`, in `n`'s local space.
func _gun_aabb(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var a := _local_aabb(n, mi)
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out


func _local_aabb(root: Node3D, mi: MeshInstance3D) -> AABB:
	var t := Transform3D.IDENTITY
	var cur: Node = mi
	while cur != root and cur is Node3D:
		t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t * mi.get_aabb()


func _place_markers() -> void:
	for m in _markers:
		m[0].queue_free()
	_markers.clear()
	var info: Dictionary = gun.get_meta("info")
	var socks: Dictionary = info.socks
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(UI.ACCENT, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.render_priority = 10
	var sm := SphereMesh.new()
	sm.radius = 0.006
	sm.height = 0.012
	for slot in Parts.SLOTS:
		if not Gun.slot_available(build, slot):
			continue
		var pos: Vector3
		if info.slots.has(slot):
			var node: Node3D = info.slots[slot]
			var box := AABB()
			var first := true
			for mi in node.find_children("*", "MeshInstance3D", true, false):
				var a := _local_aabb(gun, mi)
				box = a if first else box.merge(a)
				first = false
			pos = box.get_center()
		elif socks.has(slot):
			pos = socks[slot].origin
		else:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = mat
		gun.add_child(mi)
		mi.position = pos
		_markers.append([mi, slot])


# ------------------------------------------------------------------ UI
func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UI.make_theme()
	layer.add_child(ui)
	# Top bar.
	var top := UI.panel()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 10
	top.offset_right = -10
	top.offset_top = 10
	ui.add_child(top)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 8)
	top.add_child(th)
	th.add_child(UI.label("FORGE & FIRE", 22, UI.HOT))
	th.add_child(UI.label("  Design", 14, UI.MUTED))
	name_edit = LineEdit.new()
	name_edit.custom_minimum_size.x = 220
	name_edit.text_changed.connect(func(t): build.name = t)
	th.add_child(name_edit)
	var presets := MenuButton.new()
	presets.text = "Presets ▾"
	presets.flat = false
	var pp := presets.get_popup()
	for nm in Designs.names():
		pp.add_item(nm)
	pp.index_pressed.connect(func(i): _push_undo(); load_build(Designs.preset(Designs.names()[i])))
	th.add_child(presets)
	saved_menu = MenuButton.new()
	saved_menu.text = "My Designs ▾"
	saved_menu.flat = false
	saved_menu.about_to_popup.connect(_fill_saved)
	saved_menu.get_popup().index_pressed.connect(_on_saved_pick)
	th.add_child(saved_menu)
	th.add_child(UI.button("Save", _on_save, "Save this design (overwrites one with the same name)"))
	th.add_child(UI.button("Surprise me", func(): _push_undo(); load_build(Designs.random_build()), "Random platform, calibre, parts and paint"))
	th.add_child(UI.button("Undo", _do_undo, "Ctrl+Z"))
	th.add_child(UI.button("Redo", _do_redo, "Ctrl+Y"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(sp)
	header_label = UI.label("", 14, UI.MUTED)
	th.add_child(header_label)
	th.add_child(UI.accent_button("  TEST FIRE ▶  ", _on_test, UI.HOT, "Take it to the range (Enter)"))
	# Left: platform + slots.
	var left := UI.panel()
	left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left = 10
	left.offset_top = 70
	left.offset_bottom = -232
	left.custom_minimum_size.x = 300
	ui.add_child(left)
	var ls := ScrollContainer.new()
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(ls)
	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_constant_override("separation", 6)
	ls.add_child(lv)
	lv.add_child(UI.label("PLATFORM", 13, UI.MUTED))
	rcv_opt = OptionButton.new()
	rcv_opt.fit_to_longest_item = false
	for cat in Parts.CATS:
		rcv_opt.add_separator(cat)
		for rid in Parts.RCV:
			if Parts.RCV[rid].cat == cat:
				rcv_opt.add_item(Parts.RCV[rid].name)
				rcv_opt.set_item_metadata(rcv_opt.item_count - 1, rid)
	rcv_opt.item_selected.connect(_on_rcv)
	lv.add_child(rcv_opt)
	var cr := HBoxContainer.new()
	lv.add_child(cr)
	cal_opt = OptionButton.new()
	cal_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cal_opt.item_selected.connect(_on_cal)
	cr.add_child(cal_opt)
	ammo_opt = OptionButton.new()
	ammo_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ammo_opt.item_selected.connect(_on_ammo)
	cr.add_child(ammo_opt)
	blen_label = UI.label("Barrel", 14)
	lv.add_child(blen_label)
	blen_slider = HSlider.new()
	blen_slider.step = 0.5
	blen_slider.value_changed.connect(_on_blen)
	blen_slider.drag_ended.connect(func(_c): _rebuild(false))
	lv.add_child(blen_slider)
	lv.add_child(UI.label("RECEIVER FINISH", 13, UI.MUTED))
	var rf := GridContainer.new()
	rf.columns = 8
	lv.add_child(rf)
	_finish_grid(rf, func(f): _push_undo(); build.fin = f; _rebuild(false))
	lv.add_child(UI.label("PARTS  (click a slot or a blue dot on the gun)", 13, UI.MUTED))
	slot_box = VBoxContainer.new()
	slot_box.add_theme_constant_override("separation", 4)
	lv.add_child(slot_box)
	# Right: parts for the selected slot.
	var right := UI.panel()
	right.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right.offset_right = -10
	right.offset_top = 70
	right.offset_bottom = -232
	right.offset_left = -360
	ui.add_child(right)
	var rs := ScrollContainer.new()
	rs.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(rs)
	var rv := VBoxContainer.new()
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rv.add_theme_constant_override("separation", 6)
	rs.add_child(rv)
	part_box = VBoxContainer.new()
	part_box.add_theme_constant_override("separation", 4)
	rv.add_child(part_box)
	desc_label = UI.label("", 13, UI.MUTED)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 320
	rv.add_child(desc_label)
	param_box = VBoxContainer.new()
	rv.add_child(param_box)
	rv.add_child(UI.label("PART FINISH", 13, UI.MUTED))
	fin_box = GridContainer.new()
	fin_box.columns = 8
	rv.add_child(fin_box)
	_finish_grid(fin_box, _on_part_finish)
	rv.add_child(UI.button("Paint every part this finish", _paint_all))
	# Bottom stats.
	var bot := UI.panel()
	bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_left = 10
	bot.offset_right = -10
	bot.offset_bottom = -10
	bot.offset_top = -222
	ui.add_child(bot)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 18)
	bot.add_child(bh)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(grid)
	for row in STAT_ROWS:
		var h := HBoxContainer.new()
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl := UI.label(row[1], 13, UI.MUTED)
		nl.custom_minimum_size.x = 150
		h.add_child(nl)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(140, 10)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_theme_stylebox_override("background", UI.box(Color(1, 1, 1, 0.08), 4, Color(0, 0, 0, 0), 0))
		bar.add_theme_stylebox_override("fill", UI.box(UI.ACCENT, 4, Color(0, 0, 0, 0), 0))
		h.add_child(bar)
		var vl := UI.label("", 13)
		vl.custom_minimum_size.x = 150
		h.add_child(vl)
		grid.add_child(h)
		stat_labels[row[0]] = vl
		stat_bars[row[0]] = bar
	traj_label = RichTextLabel.new()
	traj_label.bbcode_enabled = true
	traj_label.fit_content = true
	traj_label.custom_minimum_size = Vector2(380, 190)
	traj_label.add_theme_font_size_override("normal_font_size", 13)
	bh.add_child(traj_label)


func _finish_grid(g: GridContainer, cb: Callable) -> void:
	for f in Mats.finish_names():
		var b := Button.new()
		b.custom_minimum_size = Vector2(28, 22)
		b.tooltip_text = f
		b.focus_mode = Control.FOCUS_NONE
		var spec: Array = Mats.FINISHES[f]
		var c: Color
		match spec[0]:
			"solid": c = spec[1]
			"wood": c = spec[2]
			"camo": c = spec[1]
			"carbon": c = Color(0.12, 0.12, 0.13)
			_: c = Color(0.5, 0.5, 0.52)
		b.add_theme_stylebox_override("normal", UI.box(c, 5, Color(1, 1, 1, 0.25), 0))
		b.add_theme_stylebox_override("hover", UI.box(c.lightened(0.2), 5, Color.WHITE, 0))
		b.add_theme_stylebox_override("pressed", UI.box(c, 5, UI.ACCENT, 0))
		b.pressed.connect(cb.bind(f))
		g.add_child(b)


func _refresh_ui() -> void:
	var r: Dictionary = Parts.RCV[build.rcv]
	name_edit.text = build.get("name", "")
	for i in rcv_opt.item_count:
		if rcv_opt.get_item_metadata(i) == build.rcv:
			rcv_opt.select(i)
	cal_opt.clear()
	for c in r.cals:
		cal_opt.add_item(Cal.get_cal(c).name)
		cal_opt.set_item_metadata(cal_opt.item_count - 1, c)
		if c == build.cal:
			cal_opt.select(cal_opt.item_count - 1)
	ammo_opt.clear()
	for a in Cal.ammo_for(build.cal):
		ammo_opt.add_item(Cal.AMMO[a].name)
		ammo_opt.set_item_metadata(ammo_opt.item_count - 1, a)
		if a == build.ammo:
			ammo_opt.select(ammo_opt.item_count - 1)
	blen_slider.set_block_signals(true)
	blen_slider.min_value = r.blen[0]
	blen_slider.max_value = r.blen[1]
	blen_slider.value = build.blen
	blen_slider.editable = r.blen[0] < r.blen[1]
	blen_slider.set_block_signals(false)
	blen_label.text = "Barrel length  %.1f cm" % build.blen
	header_label.text = "%s  ·  %s  ·  %.1f cm overall  ·  %.2f kg   " % [r.name, Cal.get_cal(build.cal).name, _length_cm, _stats.get("kg", 0.0)]
	for c in slot_box.get_children():
		c.queue_free()
	for slot in Parts.SLOTS:
		if not Gun.slot_available(build, slot):
			continue
		var cur: Dictionary = build.parts.get(slot, {})
		var nm: String = Parts.get_part(cur.id).name if not cur.is_empty() else "— none —"
		var b := UI.button("%s:  %s" % [Parts.SLOT_NAMES[slot], nm], select_slot.bind(slot))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if slot == sel_slot:
			b.add_theme_stylebox_override("normal", UI.box(UI.ACCENT.darkened(0.45), 8, UI.ACCENT, 10))
		slot_box.add_child(b)
	_show_stats()


func select_slot(slot: String) -> void:
	sel_slot = slot
	Sfx.play("ui")
	_refresh_ui()
	_fill_parts()


func _fill_parts() -> void:
	for c in part_box.get_children():
		c.queue_free()
	for c in param_box.get_children():
		c.queue_free()
	part_box.add_child(UI.label(Parts.SLOT_NAMES.get(sel_slot, sel_slot).to_upper(), 15, UI.HOT))
	var cur: Dictionary = build.parts.get(sel_slot, {})
	var opts := Parts.options(build.rcv, sel_slot)
	if not Parts.required(build.rcv, sel_slot):
		opts = [""] + opts
	for id in opts:
		var d := Parts.get_part(id)
		var label: String = d.name if id != "" else "None"
		if id != "" and d.kg > 0.0:
			label += "   %d g" % int(d.kg * 1000.0)
		if sel_slot == "mag" and id != "":
			var tag: String = Parts.RCV[build.rcv].slots.mag
			label += "   %d rds" % Parts.CAPS.get(tag, {}).get(id, 0)
		var b := UI.button(label, _on_part.bind(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if cur.get("id", "") == id:
			b.add_theme_stylebox_override("normal", UI.box(UI.ACCENT.darkened(0.45), 8, UI.ACCENT, 10))
		b.mouse_entered.connect(_on_hover.bind(id))
		b.mouse_exited.connect(_on_hover_end)
		part_box.add_child(b)
	var d := Parts.get_part(cur.get("id", ""))
	desc_label.text = d.get("desc", "")
	for k in d.get("p", {}):
		var spec: Array = d.p[k]
		var lab := UI.label("%s  %.1f %s" % [k.to_upper(), cur.p.get(k, spec[3]), spec[4]], 14)
		param_box.add_child(lab)
		var s := HSlider.new()
		s.min_value = spec[0]
		s.max_value = spec[1]
		s.step = spec[2]
		s.value = cur.p.get(k, spec[3])
		s.value_changed.connect(func(val): cur.p[k] = val; lab.text = "%s  %.1f %s" % [k.to_upper(), val, spec[4]])
		s.drag_ended.connect(func(_c): _rebuild(false))
		param_box.add_child(s)


func _show_stats() -> void:
	for row in STAT_ROWS:
		var k: String = row[0]
		var val: float = _stats.get(k, 0.0)
		var bar: ProgressBar = stat_bars[k]
		bar.min_value = row[3]
		bar.max_value = row[4]
		bar.value = clampf(val, row[3], row[4])
		var txt := _fmt(k, val)
		if not _hover_stats.is_empty():
			var hv: float = _hover_stats.get(k, val)
			var diff := hv - val
			if absf(diff) > absf(val) * 0.004 + 0.0001:
				var better: bool = (diff > 0.0) == row[5]
				txt += "  [%s%s]" % ["+" if diff > 0 else "", _fmt(k, diff, true)]
				stat_labels[k].add_theme_color_override("font_color", UI.GOOD if better else UI.BAD)
			else:
				stat_labels[k].add_theme_color_override("font_color", UI.TEXT)
		else:
			stat_labels[k].add_theme_color_override("font_color", UI.TEXT)
		stat_labels[k].text = txt
	var s := _stats if _hover_stats.is_empty() else _hover_stats
	if s.is_empty():
		return
	var t := "[color=#93a0b0]BALLISTICS (bore level, no wind)[/color]\n"
	t += "[color=#93a0b0]%-8s %8s %9s %9s[/color]\n" % ["range", "speed", "energy", "drop"]
	for p in s.traj:
		t += "%-8s %6d m/s %7d J %7.1f cm\n" % ["%d m" % p.d, p.v, p.e, p.drop * 100.0]
	t += "\n[color=#93a0b0]Modes:[/color] %s   [color=#93a0b0]Reload:[/color] %.1f s\n" % [" / ".join(s.modes).to_upper(), s.reload]
	t += "[color=#93a0b0]Free recoil:[/color] %.1f J  [color=#93a0b0]Felt:[/color] %.1f J\n" % [s.free, s.felt]
	if s.pellets > 1:
		t += "[color=#93a0b0]Pellets:[/color] %d  ·  pattern %.0f cm at 20 m\n" % [s.pellets, tan(deg_to_rad(s.pellet_deg)) * 2000.0 * 2.0]
	t += "[color=#93a0b0]Damage/hit:[/color] %.0f  ·  [color=#93a0b0]Jam rate:[/color] 1 in %d" % [s.dmg, int(1.0 / maxf(s.jam, 0.00001)) if s.jam > 0.0 else 0]
	if s.jam <= 0.0:
		t = t.trim_suffix("1 in 0") + "never"
	traj_label.text = t


func _fmt(k: String, v: float, delta := false) -> String:
	match k:
		"v", "e", "eff", "rpm", "db":
			return "%d %s" % [int(round(v)), _unit(k)]
		"cap":
			return "%d" % int(v)
		"moa", "kick", "hip":
			return "%.2f %s" % [v, _unit(k)]
		"ads":
			return "%.2f s" % v
		"kg":
			return "%.2f kg" % v
		"pen":
			return "%.1f mm" % v
	return str(v)


func _unit(k: String) -> String:
	for row in STAT_ROWS:
		if row[0] == k:
			return row[2]
	return ""


# ------------------------------------------------------------------ callbacks
func _on_rcv(idx: int) -> void:
	var rid = rcv_opt.get_item_metadata(idx)
	if rid == null or rid == build.rcv:
		return
	_push_undo()
	var nm: String = build.get("name", "")
	build = Gun.new_build(rid)
	if nm != "":
		build.name = Parts.RCV[rid].name
	sel_slot = "barrel"
	_rebuild(true)


func _on_cal(idx: int) -> void:
	_push_undo()
	build.cal = cal_opt.get_item_metadata(idx)
	_rebuild(false)


func _on_ammo(idx: int) -> void:
	_push_undo()
	build.ammo = ammo_opt.get_item_metadata(idx)
	_rebuild(false)


func _on_blen(v: float) -> void:
	build.blen = v
	blen_label.text = "Barrel length  %.1f cm" % v


func _on_part(id: String) -> void:
	_push_undo()
	Sfx.play("select")
	if id == "":
		build.parts.erase(sel_slot)
	else:
		var d := Parts.get_part(id)
		var old: Dictionary = build.parts.get(sel_slot, {})
		var params := {}
		for k in d.get("p", {}):
			params[k] = old.get("p", {}).get(k, d.p[k][3])
		build.parts[sel_slot] = {"id": id, "p": params, "f": d.fin}
	_rebuild(false)


func _on_hover(id: String) -> void:
	var b := build.duplicate(true)
	if id == "":
		b.parts.erase(sel_slot)
	else:
		var d := Parts.get_part(id)
		var params := {}
		for k in d.get("p", {}):
			params[k] = d.p[k][3]
		b.parts[sel_slot] = {"id": id, "p": params, "f": d.fin}
	_hover_stats = Gun.compute(b)
	var d2 := Parts.get_part(id)
	desc_label.text = d2.get("desc", "No part in this slot.")
	_show_stats()


func _on_hover_end() -> void:
	_hover_stats = {}
	_show_stats()
	desc_label.text = Parts.get_part(build.parts.get(sel_slot, {}).get("id", "")).get("desc", "")


func _on_part_finish(f: String) -> void:
	if not build.parts.has(sel_slot):
		return
	_push_undo()
	build.parts[sel_slot].f = f
	_rebuild(false)


func _paint_all() -> void:
	if not build.parts.has(sel_slot):
		return
	_push_undo()
	var f: String = build.parts[sel_slot].f
	build.fin = f
	for s in build.parts:
		build.parts[s].f = f
	_rebuild(false)


func _on_save() -> void:
	if build.get("name", "").strip_edges() == "":
		build.name = "My " + Parts.RCV[build.rcv].name
	Game.save_design(build)
	Sfx.play("select")
	header_label.text = "Saved \"%s\"" % build.name


func _fill_saved() -> void:
	var p := saved_menu.get_popup()
	p.clear()
	if Game.saved.is_empty():
		p.add_item("(nothing saved yet)")
		p.set_item_disabled(0, true)
		return
	for d in Game.saved:
		p.add_item("Load: " + d.name)
	p.add_separator()
	for d in Game.saved:
		p.add_item("Delete: " + d.name)


func _on_saved_pick(i: int) -> void:
	var n := Game.saved.size()
	if i < n:
		_push_undo()
		load_build(Game.saved[i])
	elif i > n:
		Game.delete_design(Game.saved[i - n - 1].name)


func _on_test() -> void:
	Game.build = build.duplicate(true)
	test_fire.emit()

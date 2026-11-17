extends Control
## Range HUD: crosshair, ammo, fire mode, zero, wind, hit log with ballistics
## numbers, scope reticles (mil-accurate), rangefinder, help and pause menu.

signal to_workshop
signal reset_range
signal resume

const UI := preload("res://scripts/ui_kit.gd")

var weapon: Node3D
var player: CharacterBody3D
var bal: Node3D
var ammo_l: Label
var info_l: Label
var name_l: Label
var hit_l: RichTextLabel
var help_l: Label
var center_l: Label
var pause_panel: PanelContainer
var _hits: Array = []
var _marker := 0.0
var _marker_col := Color.WHITE
var _lrf := -1.0
var _wind_l: Label
var _last_pellet := 0
var hit_panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UI.make_theme()
	var br := UI.panel(Color(0.05, 0.06, 0.08, 0.7))
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.offset_left = -330
	br.offset_top = -132
	br.offset_right = -16
	br.offset_bottom = -16
	br.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(br)
	var bv := VBoxContainer.new()
	br.add_child(bv)
	name_l = UI.label("", 14, UI.MUTED)
	bv.add_child(name_l)
	ammo_l = UI.label("", 34)
	bv.add_child(ammo_l)
	info_l = UI.label("", 14, UI.MUTED)
	bv.add_child(info_l)
	var hl := UI.panel(Color(0.05, 0.06, 0.08, 0.6))
	hl.visible = false
	hit_panel = hl
	hl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hl.offset_left = -520
	hl.offset_right = -16
	hl.offset_top = 16
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hl)
	hit_l = RichTextLabel.new()
	hit_l.bbcode_enabled = true
	hit_l.fit_content = true
	hit_l.custom_minimum_size = Vector2(490, 20)
	hit_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_l.add_theme_font_size_override("normal_font_size", 13)
	hl.add_child(hit_l)
	var wp := UI.panel(Color(0.05, 0.06, 0.08, 0.6))
	wp.set_anchors_preset(Control.PRESET_TOP_LEFT)
	wp.offset_left = 16
	wp.offset_top = 16
	wp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wp)
	_wind_l = UI.label("", 14)
	wp.add_child(_wind_l)
	help_l = UI.label("WASD move · Shift sprint / hold breath · Space jump · C crouch · Z prone\nLMB fire · RMB aim · R reload/clear jam · B fire mode · T zoom / magnifier\nPgUp/PgDn or mouse wheel (aimed) zero · G underbarrel · L light · V inspect\nE start drill · N next preset · F5 reset targets · Tab workshop · Esc menu · H hide help", 13, Color(1, 1, 1, 0.8))
	help_l.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help_l.offset_left = 16
	help_l.offset_top = -100
	help_l.offset_bottom = -16
	add_child(help_l)
	center_l = UI.label("", 20, UI.HOT)
	center_l.set_anchors_preset(Control.PRESET_CENTER)
	center_l.offset_top = 60
	center_l.offset_left = -300
	center_l.offset_right = 300
	center_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(center_l)
	_build_pause()


func _build_pause() -> void:
	pause_panel = UI.panel()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -220
	pause_panel.offset_right = 220
	pause_panel.offset_top = -250
	pause_panel.offset_bottom = 250
	pause_panel.visible = false
	add_child(pause_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pause_panel.add_child(v)
	v.add_child(UI.label("PAUSED", 24, UI.HOT))
	v.add_child(UI.button("Resume", func(): resume.emit()))
	v.add_child(UI.button("Back to workshop (Tab)", func(): to_workshop.emit()))
	v.add_child(UI.button("Reset all targets (F5)", func(): reset_range.emit()))
	_slider(v, "Wind speed", "wind", 0.0, 15.0, 0.5, " m/s")
	_slider(v, "Wind from (deg, 0 = from targets)", "wind_dir", 0.0, 359.0, 15.0, "°")
	_slider(v, "Mouse sensitivity", "sens", 0.2, 3.0, 0.05, "")
	_slider(v, "Field of view", "fov", 60.0, 100.0, 1.0, "°")
	_slider(v, "Volume", "volume", -30.0, 6.0, 1.0, " dB")
	var tr := OptionButton.new()
	for t in ["Bullet trails: off", "Bullet trails: tracer rounds only", "Bullet trails: every bullet"]:
		tr.add_item(t)
	tr.select(int(Game.settings.trails))
	tr.item_selected.connect(func(i): Game.settings.trails = i; Game.save_settings())
	v.add_child(tr)
	v.add_child(UI.button("Quit game", func(): get_tree().quit()))


func _slider(v: VBoxContainer, title: String, key: String, lo: float, hi: float, step: float, unit: String) -> void:
	var l := UI.label("%s: %s%s" % [title, str(Game.settings[key]), unit], 14)
	v.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(Game.settings[key])
	s.value_changed.connect(func(val):
		Game.settings[key] = val
		l.text = "%s: %s%s" % [title, str(val), unit]
		if bal:
			bal.update_wind()
		Game.save_settings())
	v.add_child(s)


func on_hit(h: Dictionary) -> void:
	var what: String = h.mat
	var col: Object = h.collider
	if col and col.has_meta("label"):
		what = col.get_meta("label")
	var now := Time.get_ticks_msec()
	if h.get("pellet", false) and now - _last_pellet < 120:
		_marker = 1.0
		return
	if h.get("pellet", false):
		_last_pellet = now
	var line: String
	if what == "explosion":
		line = "[color=#ff7a2f]BOOM[/color]  %d m  ·  flight %.2f s" % [h.dist, h.tof]
	else:
		var e: float = h.energy
		line = "[color=#ffb070]%s[/color]  %d m · %d m/s · %s · drop %.0f cm · %.2f s" % [what.to_upper(), h.dist, h.v, ("%.2f kJ" % (e / 1000.0)) if e >= 1000.0 else ("%d J" % e), h.drop * 100.0, h.tof]
	_hits.push_front(line)
	if _hits.size() > 7:
		_hits.pop_back()
	hit_l.text = "\n".join(_hits)
	hit_panel.visible = true
	if h.mat in ["steel", "dummy", "paper", "glass", "melon", "armor", "gel", "wood", "concrete", "tire", "explosion"]:
		_marker = 1.0
		_marker_col = Color(1, 0.3, 0.2) if h.mat == "dummy" else Color(1, 1, 1)


func _process(delta: float) -> void:
	if weapon == null or weapon.gun == null:
		return
	_marker = maxf(0.0, _marker - delta * 3.0)
	var w: Dictionary = weapon.build
	var st: Dictionary = weapon.stats
	name_l.text = "%s  ·  %s  ·  %s" % [w.get("name", ""), Cal.get_cal(w.cal).name, Cal.AMMO.get(w.ammo, {}).get("name", "")]
	var cap_txt := "%d / %d" % [weapon.ammo, weapon.cap]
	ammo_l.text = cap_txt
	ammo_l.add_theme_color_override("font_color", UI.BAD if weapon.ammo == 0 else UI.TEXT)
	var z: float = weapon.zoom()
	var t := "%s  ·  zero %d m" % [String(weapon.modes[weapon.mode]).to_upper(), int(weapon.zero)]
	if z > 1.01 or (weapon.info.get("zoom", [1.0]) as Array).size() > 1:
		t += "  ·  %.1fx" % z
	if weapon.ub_kind != "":
		t += "  ·  %s %d" % ["40mm" if weapon.ub_kind == "gl" else "UBSG", weapon.ub_ammo]
	t += "\nheat %d%%  ·  shots %d  ·  split %.2f s" % [int(clampf(weapon.heat, 0.0, 1.0) * 100.0), weapon.shots, weapon.last_split]
	if player.bipod_ready(st):
		t += "  ·  BIPOD"
	info_l.text = t
	var wind: Vector3 = bal.wind
	var stance_name: String = ["standing", "crouched", "prone"][player.stance]
	_wind_l.text = "Wind %.1f m/s from %d°  ·  %s  ·  breath %d%%" % [wind.length(), int(Game.settings.wind_dir), stance_name, int(player.breath * 100.0)]
	if weapon.jammed:
		center_l.text = "JAMMED — press R to clear"
	elif weapon.ammo == 0 and weapon._reload_t < 0.0:
		center_l.text = "EMPTY — press R"
	else:
		center_l.text = ""
	_lrf = -1.0
	if weapon.scoped():
		var cam: Camera3D = player.cam
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_basis.z * 3000.0)
		q.collision_mask = 1 | 2
		var hit := cam.get_world_3d().direct_space_state.intersect_ray(q)
		if hit:
			_lrf = cam.global_position.distance_to(hit.position)
	queue_redraw()


func _draw() -> void:
	if weapon == null or weapon.gun == null:
		return
	var sz := size
	var c := sz * 0.5
	if weapon.scoped():
		_draw_scope(c, sz)
	elif weapon.ads < 0.3:
		var spread: float = weapon.stats.hip * (1.0 - weapon.ads) + Vector2(player.velocity.x, player.velocity.z).length() * 0.4
		var px := tan(deg_to_rad(spread * 0.5)) / tan(deg_to_rad(player.cam.fov * 0.5)) * sz.y * 0.5 + 6.0
		var col := Color(1, 1, 1, 0.85 * (1.0 - weapon.ads * 3.0))
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			draw_line(c + d * px, c + d * (px + 9.0), col, 2.0)
		draw_circle(c, 1.5, col)
	if _marker > 0.0:
		var m := 10.0 + (1.0 - _marker) * 6.0
		var col2 := Color(_marker_col, _marker)
		for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			draw_line(c + d * m * 0.5, c + d * m, col2, 2.0)
	if player.holding_breath or player.breath < 1.0:
		var w := 120.0
		draw_rect(Rect2(c + Vector2(-w * 0.5, 120), Vector2(w, 5)), Color(0, 0, 0, 0.4))
		draw_rect(Rect2(c + Vector2(-w * 0.5, 120), Vector2(w * player.breath, 5)), Color(0.5, 0.8, 1.0, 0.8))


## Scope view: black surround, reticle drawn in true milliradians.
func _draw_scope(c: Vector2, sz: Vector2) -> void:
	var r := sz.y * 0.47
	var black := Color(0, 0, 0, 1)
	var steps := 64
	var pts := PackedVector2Array()
	for i in steps + 1:
		var a := TAU * i / steps
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	# Mask outside the circle with thick rectangles and a ring.
	draw_rect(Rect2(Vector2.ZERO, Vector2(c.x - r, sz.y)), black)
	draw_rect(Rect2(Vector2(c.x + r, 0), Vector2(sz.x - c.x - r, sz.y)), black)
	draw_arc(c, r + sz.y * 0.25, 0, TAU, 96, black, sz.y * 0.5)
	draw_arc(c, r, 0, TAU, 96, Color(0, 0, 0, 0.6), 18.0)
	var cam: Camera3D = player.cam
	var px_per_mil := (sz.y * 0.5) / tan(deg_to_rad(cam.fov * 0.5)) * 0.001
	var oid: String = weapon.info.optic_id
	var col := Color(0.02, 0.02, 0.02)
	var red := Color(1, 0.15, 0.1)
	match oid:
		"opt_39":
			draw_line(c - Vector2(r, 0), c - Vector2(px_per_mil * 3.0, 0), col, 5.0)
			draw_line(c + Vector2(px_per_mil * 3.0, 0), c + Vector2(r, 0), col, 5.0)
			draw_line(c + Vector2(0, px_per_mil * 3.0), c + Vector2(0, r), col, 5.0)
			draw_line(c - Vector2(0, r), c - Vector2(0, px_per_mil * 3.0), col, 5.0)
			draw_line(c - Vector2(px_per_mil * 3.0, 0), c + Vector2(px_per_mil * 3.0, 0), col, 1.2)
			draw_line(c - Vector2(0, px_per_mil * 3.0), c + Vector2(0, px_per_mil * 3.0), col, 1.2)
		"opt_acog", "opt_prism":
			draw_line(c, c + Vector2(-px_per_mil * 1.2, px_per_mil * 1.2), red, 2.5)
			draw_line(c, c + Vector2(px_per_mil * 1.2, px_per_mil * 1.2), red, 2.5)
			draw_line(c + Vector2(0, px_per_mil * 2.0), c + Vector2(0, r), col, 1.5)
			for i in range(1, 7):
				var y := c.y + px_per_mil * (1.8 + i * 1.6 + i * i * 0.18)
				var hw := px_per_mil * (1.4 - i * 0.12)
				draw_line(Vector2(c.x - hw, y), Vector2(c.x + hw, y), col, 1.5)
				_text(Vector2(c.x + hw + 4, y + 5), str(200 + i * 100), col)
		"opt_lpvo", "opt_holomag":
			draw_arc(c, px_per_mil * 10.0, 0, TAU, 64, red, 2.0)
			draw_circle(c, 2.5, red)
			draw_line(c - Vector2(r, 0), c - Vector2(px_per_mil * 10.0, 0), col, 3.0)
			draw_line(c + Vector2(px_per_mil * 10.0, 0), c + Vector2(r, 0), col, 3.0)
			draw_line(c + Vector2(0, px_per_mil * 10.0), c + Vector2(0, r), col, 3.0)
		_:
			# Mil-dot / mil-hash reticle (10x, 5-25x).
			draw_line(c - Vector2(r, 0), c + Vector2(r, 0), col, 1.2)
			draw_line(c - Vector2(0, r), c + Vector2(0, r), col, 1.2)
			for i in range(-10, 11):
				if i == 0:
					continue
				var len := 6.0 if i % 5 != 0 else 11.0
				draw_line(c + Vector2(i * px_per_mil, -len * 0.5), c + Vector2(i * px_per_mil, len * 0.5), col, 1.2)
				draw_line(c + Vector2(-len * 0.5, i * px_per_mil), c + Vector2(len * 0.5, i * px_per_mil), col, 1.2)
				if i > 0 and i % 2 == 0 and px_per_mil > 8.0:
					_text(c + Vector2(-22, i * px_per_mil + 4), str(i), col)
			draw_circle(c, 1.6, red)
	if _lrf > 0.0:
		_text(c + Vector2(r * 0.45, r * 0.75), "LRF %d m" % int(_lrf), Color(1, 0.4, 0.2))
	_text(c + Vector2(-r * 0.7, r * 0.75), "%.1fx · zero %d m" % [weapon.zoom(), int(weapon.zero)], Color(1, 0.4, 0.2))


func _text(p: Vector2, s: String, col: Color) -> void:
	draw_string(get_theme_default_font(), p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)

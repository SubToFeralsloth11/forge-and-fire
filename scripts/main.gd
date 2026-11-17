extends Node3D
## Flow: workshop <-> proving ground. Routes input while on the range.

const Workshop := preload("res://scripts/workshop.gd")
const RangeWorld := preload("res://scripts/range.gd")
const Player := preload("res://scripts/player.gd")
const Hud := preload("res://scripts/hud.gd")

var workshop: Node3D
var range_world: Node3D
var player: CharacterBody3D
var hud: Control
var hud_layer: CanvasLayer
var mode := "workshop"
var paused := false
var _preset_i := 0


func _ready() -> void:
	if "--check" in OS.get_cmdline_user_args():
		get_tree().create_timer(90.0).timeout.connect(get_tree().quit)
		var c = load("res://tools/check.gd").new()
		add_child(c)
		c.run()
		return
	workshop = Workshop.new()
	workshop.test_fire.connect(go_range)
	add_child(workshop)
	if "--shots" in OS.get_cmdline_user_args() or "--simtest" in OS.get_cmdline_user_args():
		var s = load("res://tools/shots.gd").new()
		s.main = self
		add_child(s)


func go_range() -> void:
	if range_world == null:
		range_world = RangeWorld.new()
		range_world.name = "Range"
		add_child(range_world)
		player = Player.new()
		range_world.add_child(player)
		player.weapon.bal = range_world.bal
		hud_layer = CanvasLayer.new()
		add_child(hud_layer)
		hud = Hud.new()
		hud.weapon = player.weapon
		hud.player = player
		hud.bal = range_world.bal
		hud_layer.add_child(hud)
		range_world.bal.hit_report.connect(hud.on_hit)
		hud.to_workshop.connect(go_workshop)
		hud.reset_range.connect(range_world.reset_targets)
		hud.resume.connect(_set_paused.bind(false))
		player.global_transform = range_world.spawn
	workshop.visible = false
	workshop.process_mode = Node.PROCESS_MODE_DISABLED
	workshop.ui.visible = false
	range_world.visible = true
	range_world.process_mode = Node.PROCESS_MODE_INHERIT
	hud_layer.visible = true
	Fx.root = range_world
	player.cam.current = true
	player.weapon.equip(Game.build)
	range_world.bal.update_wind()
	mode = "range"
	_set_paused(false)


func go_workshop() -> void:
	_set_paused(false)
	mode = "workshop"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if range_world:
		range_world.visible = false
		range_world.process_mode = Node.PROCESS_MODE_DISABLED
		hud_layer.visible = false
	workshop.visible = true
	workshop.process_mode = Node.PROCESS_MODE_INHERIT
	workshop.ui.visible = true
	workshop.cam.current = true
	workshop.load_build(Game.build)


func _set_paused(p: bool) -> void:
	paused = p
	if hud:
		hud.pause_panel.visible = p
	if range_world:
		range_world.process_mode = Node.PROCESS_MODE_DISABLED if p else Node.PROCESS_MODE_INHERIT
	if mode == "range":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_CAPTURED


func _unhandled_input(ev: InputEvent) -> void:
	if mode != "range":
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		_set_paused(not paused)
		return
	if paused:
		return
	var w: Node3D = player.weapon
	if ev is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.look(ev.relative)
	elif ev is InputEventMouseButton:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		match ev.button_index:
			MOUSE_BUTTON_LEFT: w.set_trigger(ev.pressed)
			MOUSE_BUTTON_RIGHT: w.ads_on = ev.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if ev.pressed and w.ads > 0.5: w.adjust_zero(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if ev.pressed and w.ads > 0.5: w.adjust_zero(-1)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_R: w.reload()
			KEY_B: w.switch_mode()
			KEY_T: w.cycle_zoom()
			KEY_PAGEUP: w.adjust_zero(1)
			KEY_PAGEDOWN: w.adjust_zero(-1)
			KEY_G: w.fire_underbarrel()
			KEY_L: w.toggle_light()
			KEY_V: w.inspect()
			KEY_C: player.toggle_stance(1)
			KEY_Z: player.toggle_stance(2)
			KEY_H: hud.help_l.visible = not hud.help_l.visible
			KEY_F5: range_world.reset_targets()
			KEY_TAB: go_workshop()
			KEY_N: _next_preset(-1 if ev.shift_pressed else 1)
			KEY_E:
				if player.global_position.distance_to(range_world.drill_button) < 3.0:
					range_world.start_drill()


func _next_preset(d: int) -> void:
	var names := Designs.names()
	var pool: Array = []
	for nm in names:
		pool.append(Designs.preset(nm))
	for s in Game.saved:
		pool.append(s)
	_preset_i = wrapi(_preset_i + d, 0, pool.size())
	Game.build = pool[_preset_i].duplicate(true)
	player.weapon.equip(Game.build)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "range" and not paused:
		_set_paused(true)

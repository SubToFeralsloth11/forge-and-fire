extends Node
## Automated checks.
##   --simtest : headless. Fires every preset at steel, reloads, cycles actions,
##               checks hits and that nothing errors.
##   --shots   : windowed. Saves screenshots of the workshop and range to tools/out/.

var main: Node3D
var results: Array = []
var hits := 0


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if "--shots" in OS.get_cmdline_user_args():
		await _shots()
	else:
		await _simtest()
	get_tree().quit()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _aim_at(target: Vector3) -> void:
	var p: CharacterBody3D = main.player
	var eye: Vector3 = p.cam.global_position
	var d := target - eye
	p.yaw = atan2(-d.x, -d.z)
	p.pitch = atan2(d.y, Vector2(d.x, d.z).length())
	p._rec_pitch = 0.0
	p._rec_yaw = 0.0


func _on_hit(h: Dictionary) -> void:
	hits += 1


func _simtest() -> void:
	main.go_range()
	Engine.time_scale = 3.0
	Engine.physics_ticks_per_second = 180
	var bal: Node3D = main.range_world.bal
	bal.hit_report.connect(_on_hit)
	Game.settings.wind = 0.0
	bal.update_wind()
	var names := Designs.names()
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	for nm in names:
		if only != "" and not nm.contains(only):
			continue
		var b := Designs.preset(nm)
		Game.build = b
		var w: Node3D = main.player.weapon
		w.equip(b)
		main.player.global_transform = main.range_world.spawn
		main.player.velocity = Vector3.ZERO
		main.player.toggle_stance(0)
		await _wait(0.7)
		var target := Vector3(0, 0.56, -300) if w.stats.eff > 250.0 else Vector3(-6, 0.68, -100)
		if w.stats.proj.cls in ["pistol", "shotgun", "magnum", "grenade"] or w.stats.eff < 120.0:
			target = Vector3(-16, 1.35, -25)
		var dist: float = (target - main.player.cam.global_position).length()
		w.zero = clampf(snappedf(dist, 25.0), 25.0, 1500.0)
		w._compute_zero()
		w.ads_on = true
		await _wait(0.8)
		hits = 0
		var shots := 0
		var start_ammo: int = w.ammo
		for i in 6:
			_aim_at(target)
			w.set_trigger(true)
			await _wait(0.05)
			w.set_trigger(false)
			shots += 1
			await _wait(0.9)
		await _wait(dist / 300.0 + 0.6)
		var after: int = w.ammo
		w.ads_on = false
		w.reload()
		await _wait(w._reload_dur * (w.cap - after + 1 if w._reload_kind == "tube" else 1) + 1.0)
		var ok_reload: bool = w.ammo >= w.cap
		results.append("%-22s fired %d (ammo %d->%d) hits %d at %dm  reload %s  jam %s  jamrate %.5f" % [nm, shots, start_ammo, after, hits, int(dist), "ok" if ok_reload else "FAIL(%d/%d)" % [w.ammo, w.cap], w.jammed, w.stats.jam])
		print(results[-1])
	# Penetration / props / explosion sanity: shoot the yard with the .50.
	var big := Designs.preset("Big Fifty")
	main.player.weapon.equip(big)
	await _wait(0.8)
	hits = 0
	_aim_at(Vector3(-36 - 5 + 5 * 1.6, 1.3, -20))
	await _wait(0.3)
	var a0: int = main.player.weapon.ammo
	main.player.weapon.set_trigger(true)
	await _wait(0.05)
	main.player.weapon.set_trigger(false)
	await _wait(1.0)
	print("armour/plate hit test hits=%d ammo %d->%d busy=%s swap=%.2f cd=%.2f" % [hits, a0, main.player.weapon.ammo, main.player.weapon.busy(), main.player.weapon._swap_t, main.player.weapon.cooldown])
	var gl := Designs.preset("Thumper")
	main.player.weapon.equip(gl)
	await _wait(0.8)
	hits = 0
	_aim_at(Vector3(38, 6, -30))
	main.player.weapon.set_trigger(true)
	await _wait(0.05)
	main.player.weapon.set_trigger(false)
	await _wait(3.0)
	print("grenade test reports=%d" % hits)
	print("SIMTEST DONE %d designs" % results.size())


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://tools/out/" + path)
	print("saved ", path)


func _shots() -> void:
	var ws: Node3D = main.workshop
	for nm in ["Patrol Carbine", "Kalash Classic", "Precision Bolt", "Service Pistol", "Riot Pump", "Hand Cannon", "Big Fifty", "Bullpup Assault", "Squad Automatic", "Coach Gun", "Brush Gun", "Thumper"]:
		ws.load_build(Designs.preset(nm))
		ws._yaw = -0.9
		ws._pitch = -0.15
		await _wait(0.6)
		await _shot("ws_%s.png" % nm.to_lower().replace(" ", "_"))
	ws.load_build(Designs.preset("Patrol Carbine"))
	ws.select_slot("optic")
	await _wait(0.5)
	await _shot("ws_ui_optic.png")
	main.go_range()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var w: Node3D = main.player.weapon
	for nm in ["Patrol Carbine", "Kalash Classic", "Service Pistol", "Riot Pump", "Precision Bolt"]:
		w.equip(Designs.preset(nm))
		main.player.global_transform = main.range_world.spawn
		_aim_at(Vector3(0, 1.2, -60))
		await _wait(1.0)
		await _shot("range_hip_%s.png" % nm.to_lower().replace(" ", "_"))
		w.ads_on = true
		await _wait(0.9)
		await _shot("range_ads_%s.png" % nm.to_lower().replace(" ", "_"))
		w.ads_on = false
	w.equip(Designs.preset("Precision Bolt"))
	main.player.toggle_stance(2)
	await _wait(0.8)
	_aim_at(Vector3(0, 0.5, -1000))
	w.ads_on = true
	w.zoom_i = 3
	await _wait(1.0)
	await _shot("range_scope_1000.png")
	w.zoom_i = 0
	_aim_at(Vector3(0, 0.8, -300))
	w.set_trigger(true)
	await _wait(0.05)
	w.set_trigger(false)
	await _wait(1.5)
	await _shot("range_scope_hit.png")
	w.ads_on = false
	main.player.toggle_stance(2)
	await _wait(0.6)
	main.player.global_position = Vector3(40, 0.2, -18)
	_aim_at(Vector3(40, 1.0, -30))
	w.equip(Designs.preset("Drum Shotgun"))
	await _wait(0.8)
	await _shot("range_yard.png")
	for i in 4:
		w.set_trigger(true)
		await _wait(0.05)
		w.set_trigger(false)
		await _wait(0.25)
	await _wait(0.3)
	await _shot("range_yard_after.png")
	w.reload()
	await _wait(0.9)
	await _shot("range_reload.png")

extends CharacterBody3D
## First-person shooter body: walk/sprint/crouch/prone, mouse look with
## recoil, breath holding and scope sway. Owns the camera and weapon.

const Weapon := preload("res://scripts/weapon.gd")
const EYE := [1.62, 1.12, 0.32]
const SPEED := [4.2, 2.2, 0.9]

var cam: Camera3D
var weapon: Node3D
var yaw := 0.0
var pitch := 0.0
var stance := 0
var sprinting := false
var breath := 1.0
var holding_breath := false
var _rec_pitch := 0.0
var _rec_yaw := 0.0
var _sway_t := 0.0
var _eye := 1.62
var _kick := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.75
	cs.shape = cap
	cs.position.y = 0.875
	cs.name = "Shape"
	add_child(cs)
	cam = Camera3D.new()
	cam.near = 0.01
	cam.far = 4500.0
	cam.fov = Game.settings.fov
	cam.position.y = EYE[0]
	add_child(cam)
	cam.current = true
	weapon = Weapon.new()
	weapon.player = self
	weapon.cam = cam
	cam.add_child(weapon)


func add_recoil(p_deg: float, y_deg: float) -> void:
	# 65% stays (muzzle climb you have to pull down), the rest springs back.
	pitch += deg_to_rad(p_deg * 0.65)
	yaw += deg_to_rad(y_deg * 0.65)
	_rec_pitch += deg_to_rad(p_deg * 0.35)
	_rec_yaw += deg_to_rad(y_deg * 0.35)
	_kick += p_deg * 0.03 * Game.settings.shake


func bipod_ready(stats: Dictionary) -> bool:
	return stats.get("bipod", false) and stance >= 1


func look(rel: Vector2) -> void:
	var s: float = 0.0022 * Game.settings.sens
	var z: float = weapon.zoom() if weapon.ads > 0.5 else 1.0
	s /= lerpf(1.0, z, 0.85)
	if weapon.ads > 0.5:
		s *= 0.8
	yaw -= rel.x * s
	pitch = clampf(pitch - rel.y * s, -1.5, 1.5)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input.y -= 1
	if Input.is_key_pressed(KEY_S): input.y += 1
	if Input.is_key_pressed(KEY_A): input.x -= 1
	if Input.is_key_pressed(KEY_D): input.x += 1
	input = input.normalized()
	var shift := Input.is_key_pressed(KEY_SHIFT)
	sprinting = shift and input.y < 0.0 and stance == 0 and weapon.ads < 0.3 and not weapon.ads_on
	var speed: float = SPEED[stance] * (1.65 if sprinting else 1.0) * (0.55 if weapon.ads > 0.5 else 1.0)
	var heavy: float = weapon.stats.get("kg", 3.0)
	speed *= clampf(1.08 - heavy * 0.012, 0.8, 1.05)
	var basis_y := Basis(Vector3.UP, yaw)
	var wish := basis_y * Vector3(input.x, 0, input.y) * speed
	var accel := 12.0 if is_on_floor() else 2.0
	velocity.x = move_toward(velocity.x, wish.x, accel * delta * maxf(speed, 1.0))
	velocity.z = move_toward(velocity.z, wish.z, accel * delta * maxf(speed, 1.0))
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif Input.is_key_pressed(KEY_SPACE) and stance == 0:
		velocity.y = 4.2
	elif Input.is_key_pressed(KEY_SPACE) and stance > 0:
		stance = 0
	move_and_slide()
	# Breath hold while scoped.
	holding_breath = shift and weapon.ads > 0.6 and breath > 0.0
	if holding_breath:
		breath = maxf(0.0, breath - delta / 6.0)
	else:
		breath = minf(1.0, breath + delta / (4.0 if not shift else 9.0))


func _process(delta: float) -> void:
	_eye = lerpf(_eye, EYE[stance], clampf(delta * 8.0, 0.0, 1.0))
	cam.position.y = _eye
	_rec_pitch = lerpf(_rec_pitch, 0.0, clampf(delta * 9.0, 0.0, 1.0))
	_rec_yaw = lerpf(_rec_yaw, 0.0, clampf(delta * 9.0, 0.0, 1.0))
	_kick = lerpf(_kick, 0.0, clampf(delta * 14.0, 0.0, 1.0))
	# Aim sway: larger standing, with heavy guns, high zoom; nearly gone on a bipod.
	_sway_t += delta
	var st: Dictionary = weapon.stats
	var amp: float = deg_to_rad(st.get("sway", 1.0) * 0.12) * weapon.ads
	amp *= [1.0, 0.55, 0.3][stance]
	if bipod_ready(st):
		amp *= 0.1
	if holding_breath:
		amp *= 0.15
	elif breath <= 0.0:
		amp *= 2.2
	var vel := Vector2(velocity.x, velocity.z).length()
	amp *= 1.0 + vel * 0.4
	var sx := (sin(_sway_t * 0.9) + sin(_sway_t * 2.3) * 0.4) * amp
	var sy := (sin(_sway_t * 0.63 + 1.3) + cos(_sway_t * 1.7) * 0.35) * amp
	rotation = Vector3(0, yaw + _rec_yaw + sx, 0)
	cam.rotation = Vector3(pitch + _rec_pitch + sy, 0, randf_range(-1, 1) * _kick * 0.01)
	var base_fov: float = Game.settings.fov
	var z: float = weapon.zoom()
	var target := base_fov
	if weapon.ads > 0.0:
		var zf := z if weapon.scoped() else 1.0 + (0.12 if z <= 1.01 else (z - 1.0) * 0.2)
		var fov_ads := rad_to_deg(2.0 * atan(tan(deg_to_rad(base_fov) * 0.5) / zf))
		target = lerpf(base_fov, fov_ads, weapon.ads)
	cam.fov = lerpf(cam.fov, target, clampf(delta * 20.0, 0.0, 1.0))


func toggle_stance(s: int) -> void:
	stance = 0 if stance == s else s
	if stance == 2:
		var cs: CollisionShape3D = get_node("Shape")
		(cs.shape as CapsuleShape3D).height = 0.7
		cs.position.y = 0.35
	elif stance == 1:
		var cs: CollisionShape3D = get_node("Shape")
		(cs.shape as CapsuleShape3D).height = 1.2
		cs.position.y = 0.6
	else:
		var cs: CollisionShape3D = get_node("Shape")
		(cs.shape as CapsuleShape3D).height = 1.75
		cs.position.y = 0.875

extends Node
## Synthesized audio: gunshots shaped by energy, barrel length and suppressors,
## plus mechanical clicks, impacts and ambience. No audio files.

const RATE := 22050
const MAX_ACTIVE := 40

var streams := {}
var _shots := {}
var _active := 0


func _ready() -> void:
	streams["click"] = _wav(_mech(0.04, 2400.0, 0.5, 1))
	streams["ui"] = _wav(_tone(0.05, 1200.0, 0.25, 60.0))
	streams["select"] = _wav(_mech(0.06, 1500.0, 0.4, 2))
	streams["mag_out"] = _wav(_mech(0.12, 900.0, 0.6, 2))
	streams["mag_in"] = _wav(_mech(0.14, 700.0, 0.8, 3))
	streams["bolt_back"] = _wav(_mech(0.12, 1100.0, 0.7, 3))
	streams["bolt_fwd"] = _wav(_mech(0.1, 800.0, 0.9, 2))
	streams["pump"] = _wav(_mech(0.16, 500.0, 0.8, 4))
	streams["shell"] = _wav(_mech(0.08, 650.0, 0.6, 2))
	streams["cyl"] = _wav(_mech(0.07, 1700.0, 0.5, 2))
	streams["dry"] = _wav(_mech(0.03, 3000.0, 0.45, 1))
	streams["tink"] = _wav(_ring_tone(0.25, [4200.0, 6100.0], 0.18, 25.0))
	streams["steel"] = _wav(_ring_tone(1.2, [620.0, 1340.0, 2210.0], 0.7, 3.5))
	streams["steel_hi"] = _wav(_ring_tone(0.9, [980.0, 2050.0, 3300.0], 0.6, 4.5))
	streams["thud"] = _wav(_noise_hit(0.12, 0.15, 0.6))
	streams["wood"] = _wav(_noise_hit(0.1, 0.35, 0.7))
	streams["glass"] = _wav(_glass())
	streams["splat"] = _wav(_noise_hit(0.2, 0.25, 0.8))
	streams["boom"] = _wav(_boom(1.8, 40.0, 1.0))
	streams["whiz"] = _wav(_whiz())
	streams["buzzer"] = _wav(_tone(0.35, 440.0, 0.4, 2.0))
	streams["beep"] = _wav(_tone(0.12, 1760.0, 0.35, 10.0))


func _wav(data: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	return w


## Gunshot. energy in joules, barrel cm, suppressed, braked, supersonic.
func gunshot(energy: float, barrel_cm: float, supp: bool, loud_add: float, supersonic: bool) -> AudioStreamWAV:
	var e_key := int(round(log(maxf(energy, 50.0)) * 4.0))
	var key := "%d:%d:%s:%d:%s" % [e_key, int(barrel_cm / 8.0), supp, int(loud_add), supersonic]
	if _shots.has(key):
		return _shots[key]
	var size := clampf(log(maxf(energy, 50.0) / 200.0) / log(100.0), 0.0, 1.0)
	var dur := 0.45 + size * 1.2
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	var hp_prev := 0.0
	var tone := lerpf(180.0, 55.0, size)
	var short := clampf((40.0 - barrel_cm) / 30.0, 0.0, 1.0)
	var vol := 1.0
	if supp:
		vol = 0.35
	for i in n:
		var t := float(i) / RATE
		var w := randf_range(-1.0, 1.0)
		lp = lerpf(lp, w, lerpf(0.55, 0.25, size) if not supp else 0.12)
		lp2 = lerpf(lp2, lp, 0.18)
		var crack := 0.0
		if supersonic or not supp:
			crack = (w - hp_prev) * exp(-t * 900.0) * (1.4 if supersonic else 0.7)
		hp_prev = w
		var blast := lp * exp(-t * lerpf(60.0, 22.0, size)) * (1.0 + short * 0.6)
		if supp:
			blast = lp * exp(-t * 45.0) * 0.6
		var body := (lp2 * 2.2 + sin(TAU * tone * t) * 0.35 * exp(-t * 18.0)) * exp(-t * lerpf(14.0, 5.0, size))
		var tail := lp2 * 1.6 * exp(-t * lerpf(6.0, 2.2, size)) * minf(1.0, t * 30.0) * (0.25 if supp else 1.0)
		var echo := 0.0
		if t > 0.18 and not supp:
			echo = lp2 * 0.9 * exp(-(t - 0.18) * 4.0) * size
		out[i] = clampf((crack + blast + body * (0.4 if supp else 1.0) + tail + echo) * vol * (1.0 + loud_add * 0.03), -1.0, 1.0)
	var s := _wav(out)
	_shots[key] = s
	return s


func _mech(dur: float, f: float, vol: float, clicks: int) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var gap := dur / float(clicks + 1)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for c in clicks:
			var tc := t - gap * c * 0.8
			if tc >= 0.0:
				s += (randf_range(-1, 1) * 0.6 + sin(TAU * f * (1.0 + c * 0.3) * tc) * 0.6) * exp(-tc * 140.0)
		out[i] = s * vol
	return out


func _tone(dur: float, f: float, vol: float, decay: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = sin(TAU * f * t) * exp(-t * decay) * vol * minf(1.0, t * 400.0)
	return out


func _ring_tone(dur: float, fs: Array, vol: float, decay: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := randf_range(-1, 1) * exp(-t * 300.0) * 0.6
		for k in fs.size():
			s += sin(TAU * fs[k] * t) * exp(-t * decay * (1.0 + k * 0.5)) / (1.0 + k * 0.6)
		out[i] = s * vol * 0.6
	return out


func _noise_hit(dur: float, smooth: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerpf(lp, randf_range(-1, 1), smooth)
		out[i] = lp * exp(-t * 30.0) * vol * 2.0
	return out


func _glass() -> PackedFloat32Array:
	var n := int(0.6 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := randf_range(-1, 1) * exp(-t * 12.0) * 0.5
		for k in 4:
			var tk := t - k * 0.05
			if tk > 0:
				s += sin(TAU * (3000.0 + k * 900.0) * tk) * exp(-tk * 20.0) * 0.25
		out[i] = s
	return out


func _boom(dur: float, tone: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 4.0 / dur) * minf(1.0, t * 400.0)
		lp = lerpf(lp, randf_range(-1, 1), 0.12)
		lp2 = lerpf(lp2, lp, 0.3)
		var thump := sin(TAU * tone * t * (1.0 - t * 0.3)) * exp(-t * 6.0)
		out[i] = clampf((lp2 * 3.2 + thump * 0.9) * env * vol, -1, 1)
	return out


func _whiz() -> PackedFloat32Array:
	var n := int(0.25 * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp = lerpf(lp, randf_range(-1, 1), 0.6)
		out[i] = lp * sin(PI * t / 0.25) * 0.5
	return out


func play_stream(s: AudioStream, pos: Variant = null, vol := 0.0, pitch := 1.0) -> void:
	if s == null or _active >= MAX_ACTIVE:
		return
	var p: Node
	if pos == null:
		var a := AudioStreamPlayer.new()
		a.stream = s
		a.volume_db = vol + Game.settings.volume
		a.pitch_scale = pitch
		p = a
	else:
		var a3 := AudioStreamPlayer3D.new()
		a3.stream = s
		a3.volume_db = vol + Game.settings.volume
		a3.unit_size = 18.0
		a3.max_distance = 2500.0
		a3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		a3.pitch_scale = pitch
		a3.position = pos
		p = a3
	add_child(p)
	_active += 1
	p.finished.connect(_done.bind(p))
	p.play()


func play(nm: String, pos: Variant = null, vol := 0.0, pitch := 1.0) -> void:
	if streams.has(nm):
		play_stream(streams[nm], pos, vol, pitch * randf_range(0.95, 1.05))


## Plays a sound after the time it takes to travel `dist` metres (343 m/s).
func play_delayed(nm: String, pos: Vector3, dist: float, vol := 0.0, pitch := 1.0) -> void:
	var delay := dist / 343.0
	if delay < 0.02:
		play(nm, pos, vol, pitch)
		return
	get_tree().create_timer(delay).timeout.connect(play.bind(nm, pos, vol, pitch))


func _done(p: Node) -> void:
	_active -= 1
	p.queue_free()

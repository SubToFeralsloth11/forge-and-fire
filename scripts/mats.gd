extends Node
## Material library: paintable finishes (cerakote, anodizing, wood, camo, carbon)
## and the fixed materials every gun shares (steel, bore, glass, reticles, brass).
## Textured finishes use triplanar mapping, so meshes need no UVs.

## name -> [type, colour, metallic, roughness, extra colours...]
const FINISHES := {
	"Black": ["solid", Color(0.045, 0.047, 0.05), 0.15, 0.62],
	"Graphite": ["solid", Color(0.15, 0.155, 0.16), 0.25, 0.55],
	"Flat Dark Earth": ["solid", Color(0.53, 0.43, 0.31), 0.0, 0.78],
	"Coyote Tan": ["solid", Color(0.6, 0.5, 0.36), 0.0, 0.8],
	"OD Green": ["solid", Color(0.24, 0.27, 0.17), 0.0, 0.78],
	"Ranger Green": ["solid", Color(0.2, 0.24, 0.19), 0.05, 0.72],
	"Wolf Grey": ["solid", Color(0.36, 0.38, 0.4), 0.1, 0.6],
	"Sniper Grey": ["solid", Color(0.27, 0.29, 0.3), 0.2, 0.55],
	"Parkerized": ["solid", Color(0.11, 0.115, 0.11), 0.6, 0.58],
	"Blued Steel": ["solid", Color(0.05, 0.06, 0.09), 0.92, 0.28],
	"Stainless": ["solid", Color(0.6, 0.61, 0.62), 0.95, 0.3],
	"Chrome": ["solid", Color(0.86, 0.87, 0.89), 1.0, 0.07],
	"Gold": ["solid", Color(0.95, 0.72, 0.3), 1.0, 0.2],
	"Rose Gold": ["solid", Color(0.86, 0.55, 0.47), 1.0, 0.22],
	"Bronze": ["solid", Color(0.55, 0.38, 0.2), 0.9, 0.35],
	"Crimson": ["solid", Color(0.5, 0.05, 0.06), 0.2, 0.5],
	"Cobalt": ["solid", Color(0.08, 0.2, 0.58), 0.3, 0.42],
	"Robin Egg": ["solid", Color(0.35, 0.68, 0.7), 0.1, 0.5],
	"Purple Haze": ["solid", Color(0.3, 0.12, 0.45), 0.3, 0.45],
	"Hot Pink": ["solid", Color(0.9, 0.3, 0.55), 0.1, 0.5],
	"Safety Orange": ["solid", Color(0.95, 0.38, 0.06), 0.0, 0.6],
	"Bone White": ["solid", Color(0.85, 0.83, 0.77), 0.0, 0.62],
	"Walnut": ["wood", Color(0.24, 0.12, 0.06), Color(0.42, 0.24, 0.12)],
	"Birch": ["wood", Color(0.62, 0.45, 0.27), Color(0.8, 0.64, 0.42)],
	"Mahogany": ["wood", Color(0.32, 0.09, 0.05), Color(0.5, 0.2, 0.1)],
	"Laminate": ["wood", Color(0.18, 0.2, 0.14), Color(0.45, 0.35, 0.22)],
	"Woodland Camo": ["camo", Color(0.2, 0.24, 0.13), Color(0.36, 0.3, 0.18), Color(0.07, 0.07, 0.06), Color(0.3, 0.36, 0.2)],
	"Desert Camo": ["camo", Color(0.72, 0.62, 0.45), Color(0.55, 0.43, 0.3), Color(0.4, 0.3, 0.2), Color(0.8, 0.72, 0.56)],
	"Urban Camo": ["camo", Color(0.5, 0.52, 0.55), Color(0.25, 0.26, 0.28), Color(0.08, 0.08, 0.09), Color(0.72, 0.73, 0.75)],
	"Arctic Camo": ["camo", Color(0.9, 0.92, 0.94), Color(0.65, 0.68, 0.72), Color(0.35, 0.38, 0.42), Color(0.96, 0.97, 0.98)],
	"Tiger Stripe": ["camo", Color(0.42, 0.42, 0.24), Color(0.1, 0.1, 0.07), Color(0.28, 0.2, 0.1), Color(0.5, 0.48, 0.3)],
	"Carbon Fiber": ["carbon"],
	"Damascus": ["damascus"],
}

## Fixed (non-paintable) roles used by part models.
const ROLES := ["steel", "steel2", "bore", "glass", "lens", "glow", "glow_g", "rubber", "brass", "alu", "white", "copper"]

var _cache := {}


func finish_names() -> Array:
	return FINISHES.keys()


func get_mat(role: String, finish := "Black") -> Material:
	var key := role + ":" + (finish if role == "main" else "")
	if _cache.has(key):
		return _cache[key]
	var m: Material
	if role == "main":
		m = _finish(finish)
	else:
		m = _role(role)
	_cache[key] = m
	return m


func _std(c: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	m.metallic_specular = 0.55
	return m


func _role(role: String) -> Material:
	match role:
		"steel":
			return _std(Color(0.1, 0.105, 0.11), 0.7, 0.45)
		"steel2":
			return _std(Color(0.55, 0.56, 0.58), 0.95, 0.25)
		"bore":
			return _std(Color(0.015, 0.015, 0.016), 0.4, 0.8)
		"alu":
			return _std(Color(0.08, 0.085, 0.09), 0.5, 0.42)
		"rubber":
			return _std(Color(0.04, 0.04, 0.042), 0.0, 0.92)
		"brass":
			return _std(Color(0.83, 0.62, 0.28), 1.0, 0.28)
		"copper":
			return _std(Color(0.78, 0.42, 0.25), 1.0, 0.3)
		"white":
			return _std(Color(0.9, 0.9, 0.88), 0.0, 0.5)
		"glass":
			var g := _std(Color(0.12, 0.22, 0.3, 0.32), 0.85, 0.04)
			g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			g.cull_mode = BaseMaterial3D.CULL_DISABLED
			return g
		"lens":
			return _std(Color(0.05, 0.12, 0.2), 0.9, 0.05)
		"glow", "glow_g":
			var e := StandardMaterial3D.new()
			e.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var c := Color(1.0, 0.12, 0.08) if role == "glow" else Color(0.3, 1.0, 0.3)
			e.albedo_color = c
			e.emission_enabled = true
			e.emission = c
			e.emission_energy_multiplier = 3.0
			return e
	return _std(Color.MAGENTA, 0, 1)


func _finish(nm: String) -> Material:
	var f: Array = FINISHES.get(nm, FINISHES["Black"])
	match f[0]:
		"solid":
			return _std(f[1], f[2], f[3])
		"wood":
			return _wood(f[1], f[2])
		"camo":
			return _camo(f.slice(1))
		"carbon":
			return _carbon()
		"damascus":
			return _damascus()
	return _std(Color.MAGENTA, 0, 1)


func _noise_tex(noise: FastNoiseLite, grad: Gradient, size := 512) -> NoiseTexture2D:
	var t := NoiseTexture2D.new()
	t.width = size
	t.height = size
	t.seamless = true
	t.noise = noise
	t.color_ramp = grad
	return t


func _wood(dark: Color, light: Color) -> StandardMaterial3D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.012
	n.fractal_octaves = 4
	n.domain_warp_enabled = true
	n.domain_warp_amplitude = 18.0
	var g := Gradient.new()
	g.set_color(0, dark)
	g.set_color(1, light)
	g.add_point(0.45, dark.lerp(light, 0.65))
	g.add_point(0.55, dark.lerp(light, 0.2))
	var m := _std(Color.WHITE, 0.0, 0.42)
	m.albedo_texture = _noise_tex(n, g)
	m.uv1_triplanar = true
	# Stretch the grain along the gun's length (Z).
	m.uv1_scale = Vector3(14.0, 14.0, 1.6)
	m.clearcoat_enabled = true
	m.clearcoat = 0.4
	m.clearcoat_roughness = 0.35
	return m


func _camo(cols: Array) -> StandardMaterial3D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = 0.008
	n.fractal_octaves = 3
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.set_offset(0, 0.0)
	g.set_color(0, cols[0])
	g.set_offset(1, 0.82)
	g.set_color(1, cols[3])
	g.add_point(0.38, cols[1])
	g.add_point(0.58, cols[2])
	var m := _std(Color.WHITE, 0.0, 0.8)
	m.albedo_texture = _noise_tex(n, g)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(5, 5, 3)
	return m


func _carbon() -> StandardMaterial3D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 32:
			var cell := (x / 4 + y / 4) % 2
			var ph := float((x if cell == 0 else y) % 4) / 4.0
			var v := 0.07 + 0.09 * sin(ph * PI)
			img.set_pixel(x, y, Color(v, v, v * 1.08))
	var m := _std(Color.WHITE, 0.35, 0.28)
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(60, 60, 60)
	m.clearcoat_enabled = true
	m.clearcoat = 0.9
	m.clearcoat_roughness = 0.1
	return m


func _damascus() -> StandardMaterial3D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.02
	n.domain_warp_enabled = true
	n.domain_warp_amplitude = 40.0
	var g := Gradient.new()
	g.set_color(0, Color(0.12, 0.12, 0.13))
	g.set_color(1, Color(0.7, 0.7, 0.72))
	g.add_point(0.5, Color(0.25, 0.25, 0.27))
	var m := _std(Color.WHITE, 0.95, 0.3)
	m.albedo_texture = _noise_tex(n, g)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(8, 8, 2.5)
	return m


## A plain coloured material for world props (cached by colour+params).
func prop(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var key := "prop:%s:%.2f:%.2f" % [c.to_html(), rough, metal]
	if _cache.has(key):
		return _cache[key]
	var m := _std(c, metal, rough)
	_cache[key] = m
	return m

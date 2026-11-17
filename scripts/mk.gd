class_name MK
extends RefCounted
## Procedural mesh kit. Every part is built from side-profile extrusions (with a
## rounded bevel), lathes (barrels, scopes, suppressors) and rounded boxes, all
## through SurfaceTool with hand-computed smooth/sharp normals.
##
## Gun space: the bore runs along -Z (toward the muzzle), +Y is up, +X is right.
## 2D side profiles are Vector2(z, y).

const SMOOTH_COS := 0.77  # edges meeting at less than ~40 degrees share a normal


static func new_st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
	var g := (b - a).cross(c - a)
	if g.length_squared() < 1e-16:
		return
	# Godot treats clockwise triangles as front faces: the geometric normal of
	# (a, b, c) has to point away from the surface normal.
	if g.dot(na + nb + nc) > 0.0:
		st.set_normal(na); st.add_vertex(a)
		st.set_normal(nc); st.add_vertex(c)
		st.set_normal(nb); st.add_vertex(b)
	else:
		st.set_normal(na); st.add_vertex(a)
		st.set_normal(nb); st.add_vertex(b)
		st.set_normal(nc); st.add_vertex(c)


static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
	tri(st, a, b, c, na, nb, nc)
	tri(st, a, c, d, na, nc, nd)


static func xf(pos: Vector3, rot_deg := Vector3.ZERO, s := 1.0) -> Transform3D:
	var b := Basis.from_euler(rot_deg * (PI / 180.0))
	return Transform3D(b.scaled(Vector3(s, s, s)), pos)


static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var q := p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return a * 0.5


## Extrudes a closed side profile (Vector2(z, y)) symmetrically along X.
## `bevel` rounds the edge between the flat sides and the outline.
static func extrude(st: SurfaceTool, prof: PackedVector2Array, width: float, t := Transform3D.IDENTITY, bevel := 0.0012, x0 := 0.0) -> void:
	var p := prof.duplicate()
	if p.size() < 3:
		return
	if _area(p) < 0.0:
		p.reverse()
	var n := p.size()
	var en: Array[Vector2] = []
	for i in n:
		var d := p[(i + 1) % n] - p[i]
		var e := Vector2(d.y, -d.x)
		en.append(e.normalized() if e.length_squared() > 0.0 else Vector2.UP)
	var hw := width * 0.5
	var b := minf(bevel, hw * 0.45)
	var inset := PackedVector2Array()
	var vn: Array[Vector2] = []
	var sharp: Array[bool] = []
	for i in n:
		var n0 := en[(i - 1 + n) % n]
		var n1 := en[i]
		var avg := (n0 + n1)
		avg = avg.normalized() if avg.length_squared() > 1e-8 else n1
		vn.append(avg)
		sharp.append(n0.dot(n1) < SMOOTH_COS)
		var c := maxf(avg.dot(n1), 0.35)
		inset.append(p[i] - avg * (b / c))
	var bs := t.basis
	var cap := inset
	var tris := Geometry2D.triangulate_polygon(inset)
	if tris.is_empty():
		cap = p
		tris = Geometry2D.triangulate_polygon(p)
	for s in [1.0, -1.0]:
		var nx := (bs * Vector3(s, 0, 0)).normalized()
		var x: float = x0 + s * hw
		for k in range(0, tris.size(), 3):
			var a := cap[tris[k]]
			var bb := cap[tris[k + 1]]
			var c := cap[tris[k + 2]]
			tri(st, t * Vector3(x, a.y, a.x), t * Vector3(x, bb.y, bb.x), t * Vector3(x, c.y, c.x), nx, nx, nx)
	var xa := x0 + hw - b
	var xb := x0 - hw + b
	for i in n:
		var j := (i + 1) % n
		var n2i: Vector2 = en[i] if sharp[i] else vn[i]
		var n2j: Vector2 = en[i] if sharp[j] else vn[j]
		var ni := (bs * Vector3(0, n2i.y, n2i.x)).normalized()
		var nj := (bs * Vector3(0, n2j.y, n2j.x)).normalized()
		var pi := p[i]
		var pj := p[j]
		quad(st, t * Vector3(xa, pi.y, pi.x), t * Vector3(xa, pj.y, pj.x), t * Vector3(xb, pj.y, pj.x), t * Vector3(xb, pi.y, pi.x), ni, nj, nj, ni)
		if b > 0.0 and cap == inset:
			var qi := inset[i]
			var qj := inset[j]
			for s in [1.0, -1.0]:
				var xo: float = x0 + s * hw
				var xi: float = x0 + s * (hw - b)
				var ax := bs * Vector3(s, 0, 0)
				var oi := (ni * 0.45 + ax).normalized()
				var oj := (nj * 0.45 + ax).normalized()
				var mi := (ni + ax * 0.3).normalized()
				var mj := (nj + ax * 0.3).normalized()
				quad(st, t * Vector3(xo, qi.y, qi.x), t * Vector3(xo, qj.y, qj.x), t * Vector3(xi, pj.y, pj.x), t * Vector3(xi, pi.y, pi.x), oi, oj, mj, mi)


## Revolves a profile of Vector2(r, z) points around the Z axis. Walk the
## outer surface from the rear (+z) to the front (-z); inner surfaces walk back.
static func lathe(st: SurfaceTool, pts: PackedVector2Array, segs := 18, t := Transform3D.IDENTITY, a0 := 0.0, a1 := TAU) -> void:
	var m := pts.size()
	if m < 2:
		return
	var en: Array[Vector2] = []
	for i in m - 1:
		var d := pts[i + 1] - pts[i]
		var e := Vector2(-d.y, d.x)
		en.append(e.normalized() if e.length_squared() > 0.0 else Vector2.RIGHT)
	var bs := t.basis
	var cs := PackedFloat32Array()
	var sn := PackedFloat32Array()
	for s in segs + 1:
		var ang := lerpf(a0, a1, float(s) / segs)
		cs.append(cos(ang))
		sn.append(sin(ang))
	for i in m - 1:
		var na := en[i]
		var nb := en[i]
		if i > 0 and en[i - 1].dot(en[i]) > SMOOTH_COS:
			na = (en[i - 1] + en[i]).normalized()
		if i < m - 2 and en[i + 1].dot(en[i]) > SMOOTH_COS:
			nb = (en[i + 1] + en[i]).normalized()
		var p0 := pts[i]
		var p1 := pts[i + 1]
		for s in segs:
			var c0 := cs[s]
			var s0 := sn[s]
			var c1 := cs[s + 1]
			var s1 := sn[s + 1]
			quad(st,
				t * Vector3(p0.x * c0, p0.x * s0, p0.y), t * Vector3(p1.x * c0, p1.x * s0, p1.y),
				t * Vector3(p1.x * c1, p1.x * s1, p1.y), t * Vector3(p0.x * c1, p0.x * s1, p0.y),
				(bs * Vector3(na.x * c0, na.x * s0, na.y)).normalized(), (bs * Vector3(nb.x * c0, nb.x * s0, nb.y)).normalized(),
				(bs * Vector3(nb.x * c1, nb.x * s1, nb.y)).normalized(), (bs * Vector3(na.x * c1, na.x * s1, na.y)).normalized())


## Solid cylinder along Z, centred on the transform origin.
static func cyl(st: SurfaceTool, r: float, length: float, t := Transform3D.IDENTITY, segs := 16, chamfer := 0.0) -> void:
	var h := length * 0.5
	var c := minf(chamfer, minf(r * 0.4, h * 0.4))
	if c > 0.0:
		lathe(st, PackedVector2Array([Vector2(0, h), Vector2(r - c, h), Vector2(r, h - c), Vector2(r, -h + c), Vector2(r - c, -h), Vector2(0, -h)]), segs, t)
	else:
		lathe(st, PackedVector2Array([Vector2(0, h), Vector2(r, h), Vector2(r, -h), Vector2(0, -h)]), segs, t)


## Hollow tube along Z, centred on the transform origin.
static func tube(st: SurfaceTool, ro: float, ri: float, length: float, t := Transform3D.IDENTITY, segs := 16) -> void:
	var h := length * 0.5
	lathe(st, PackedVector2Array([Vector2(ri, h), Vector2(ro, h), Vector2(ro, -h), Vector2(ri, -h), Vector2(ri, h)]), segs, t)


static func sphere(st: SurfaceTool, r: float, t := Transform3D.IDENTITY, segs := 14, rings := 8) -> void:
	var pts := PackedVector2Array()
	for i in rings + 1:
		var a := PI * float(i) / rings
		pts.append(Vector2(sin(a) * r, cos(a) * r))
	lathe(st, pts, segs, t)


## Rounded rectangle outline in (z, y), centred on `c`.
static func rrect(lz: float, hy: float, r := 0.002, c := Vector2.ZERO, segs := 3) -> PackedVector2Array:
	var out := PackedVector2Array()
	r = minf(r, minf(lz, hy) * 0.49)
	var hz := lz * 0.5
	var hh := hy * 0.5
	var corners := [Vector2(hz - r, hh - r), Vector2(-hz + r, hh - r), Vector2(-hz + r, -hh + r), Vector2(hz - r, -hh + r)]
	var starts := [0.0, PI * 0.5, PI, PI * 1.5]
	for k in 4:
		if r <= 0.0:
			out.append(c + corners[k] + Vector2(signf(corners[k].x) * 0.0, 0))
			continue
		for s in segs + 1:
			var a: float = starts[k] + PI * 0.5 * float(s) / segs
			out.append(c + corners[k] + Vector2(cos(a), sin(a)) * r)
	if r <= 0.0:
		out = PackedVector2Array([c + Vector2(hz, hh), c + Vector2(-hz, hh), c + Vector2(-hz, -hh), c + Vector2(hz, -hh)])
	return out


## Rounded box: size = (x width, y height, z length).
static func box(st: SurfaceTool, size: Vector3, t := Transform3D.IDENTITY, r := 0.0015, bevel := 0.0008) -> void:
	extrude(st, rrect(size.z, size.y, r), size.x, t, minf(bevel, size.x * 0.3))


## Polyline helper: a thick band following `path` (z, y), `th` thick, as one polygon.
static func band(path: PackedVector2Array, th: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := path.size()
	for i in n:
		var d: Vector2
		if i == 0:
			d = path[1] - path[0]
		elif i == n - 1:
			d = path[n - 1] - path[n - 2]
		else:
			d = path[i + 1] - path[i - 1]
		var nn := Vector2(-d.y, d.x).normalized() * th * 0.5
		left.append(path[i] + nn)
		right.append(path[i] - nn)
	right.reverse()
	left.append_array(right)
	return left


## Arc of points (z, y) around centre c from angle a0 to a1 (radians, 0 = +z).
static func arc(c: Vector2, r: float, a0: float, a1: float, n := 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out


## Picatinny rail along -Z starting at the transform origin (top of the base at y=0).
static func rail(st: SurfaceTool, length: float, t := Transform3D.IDENTITY) -> void:
	box(st, Vector3(0.0156, 0.0042, length), t * xf(Vector3(0, -0.0021, -length * 0.5)), 0.0006, 0.0004)
	var n := maxi(1, int(length / 0.01))
	for i in n:
		var z := -0.0035 - i * 0.01
		if -z > length - 0.002:
			break
		box(st, Vector3(0.0212, 0.0036, 0.0052), t * xf(Vector3(0, 0.0018, z)), 0.0006, 0.0005)


## M-LOK style slot cutouts are drawn as dark inset boxes on a surface.
static func slots(st: SurfaceTool, count: int, pitch: float, t := Transform3D.IDENTITY) -> void:
	for i in count:
		box(st, Vector3(0.002, 0.007, 0.032), t * xf(Vector3(0, 0, -i * pitch)), 0.003, 0.0004)


## Accumulates geometry per (group, role) while a part model is being built.
class PB:
	var sts := {}
	var sockets := {}
	var anchors := {}
	var info := {}

	func s(role := "main", group := "") -> SurfaceTool:
		var k := group + "|" + role
		if not sts.has(k):
			sts[k] = MK.new_st()
		return sts[k]

	func sock(nm: String, pos: Vector3, rot_deg := Vector3.ZERO) -> void:
		sockets[nm] = MK.xf(pos, rot_deg)

	func anchor(nm: String, pos: Vector3) -> void:
		anchors[nm] = pos

	## Commits every surface tool into a dictionary of "group|role" -> ArrayMesh.
	func bake() -> Dictionary:
		var out := {}
		for k in sts:
			var st: SurfaceTool = sts[k]
			var m := st.commit()
			if m.get_surface_count() > 0:
				out[k] = m
		return {"meshes": out, "sockets": sockets, "anchors": anchors, "info": info}

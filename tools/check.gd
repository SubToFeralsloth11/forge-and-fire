extends Node
## Headless check: assemble every preset and every receiver default, print stats.

func run() -> void:
	await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	var n := 0
	for nm in Designs.names():
		var b := Designs.preset(nm)
		var g := Gun.assemble(b)
		var s := Gun.compute(b)
		var info: Dictionary = g.get_meta("info")
		print("%-22s %-10s v=%4d m/s E=%6d J kg=%.2f moa=%.2f kick=%.2f cap=%d eff=%dm sight=%s" % [nm, b.cal, s.v, s.e, s.kg, s.moa, s.kick, s.cap, s.eff, info.anchors.sight])
		g.free()
		n += 1
	for rid in Parts.RCV:
		for i in 6:
			var b := Designs.random_build() if i > 0 else Gun.new_build(rid)
			var g := Gun.assemble(b)
			Gun.compute(b)
			g.free()
			n += 1
	print("assembled %d guns in %d ms" % [n, Time.get_ticks_msec() - t0])
	get_tree().quit()

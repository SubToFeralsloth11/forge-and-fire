extends Node3D

func _ready() -> void:
	if "--check" in OS.get_cmdline_user_args():
		get_tree().create_timer(90.0).timeout.connect(get_tree().quit)
		var c = load("res://tools/check.gd").new()
		add_child(c)
		c.run()

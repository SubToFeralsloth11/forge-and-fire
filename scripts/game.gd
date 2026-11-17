extends Node
## Session state: the design on the bench, saved designs and settings.

const SAVE := "user://designs.json"
const SETTINGS := "user://settings.cfg"

var build := {}
var saved: Array = []
var settings := {
	"sens": 1.0, "fov": 75.0, "wind": 2.0, "wind_dir": 60.0, "trails": 1, "shake": 1.0, "volume": 0.0,
}


func _ready() -> void:
	_load_designs()
	_load_settings()
	build = Designs.preset("Patrol Carbine")


func _load_designs() -> void:
	if not FileAccess.file_exists(SAVE):
		return
	var f := FileAccess.open(SAVE, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if data is Array:
		saved = []
		for d in data:
			if d is Dictionary and Parts.RCV.has(d.get("rcv", "")):
				saved.append(_fix_types(d))


## JSON turns every number into a float; nothing in a build needs ints, but
## part params must stay dictionaries.
func _fix_types(d: Dictionary) -> Dictionary:
	var b := d.duplicate(true)
	if not b.has("parts") or not (b.parts is Dictionary):
		b.parts = {}
	for k in b.parts:
		if not b.parts[k].has("p"):
			b.parts[k]["p"] = {}
	return b


func save_design(b: Dictionary) -> void:
	var copy := b.duplicate(true)
	for i in saved.size():
		if saved[i].name == copy.name:
			saved[i] = copy
			_write()
			return
	saved.append(copy)
	_write()


func delete_design(nm: String) -> void:
	for i in saved.size():
		if saved[i].name == nm:
			saved.remove_at(i)
			break
	_write()


func _write() -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(saved, "  "))


func _load_settings() -> void:
	var c := ConfigFile.new()
	if c.load(SETTINGS) != OK:
		return
	for k in settings:
		settings[k] = c.get_value("s", k, settings[k])


func save_settings() -> void:
	var c := ConfigFile.new()
	for k in settings:
		c.set_value("s", k, settings[k])
	c.save(SETTINGS)

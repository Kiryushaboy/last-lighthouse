extends SceneTree
## Рисует заставку art/splash.png (720x1280). Запуск с окном:
## xvfb-run godot --path . --resolution 720x1280 --rendering-driver opengl3 -s res://tools/make_splash.gd

const BG_TOP := Color("#0b1630")
const BG_BOTTOM := Color("#05223a")

var n := 0


func _initialize() -> void:
	var root_node := Node2D.new()
	root_node.set_script(load("res://tools/splash_draw.gd"))
	root.add_child(root_node)


func _process(_d: float) -> bool:
	n += 1
	if n == 20:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png("res://art/splash.png")
		quit()
	return false

extends Control
## Заставка при запуске: картинка плавно проявляется, держится и плавно гаснет, затем меню.

const NEXT_SCENE := "res://scenes/menu.tscn"
const FADE_IN := 0.9
const HOLD := 2.6
const FADE_OUT := 0.8

@onready var _image: TextureRect = $Image


func _ready() -> void:
	_image.modulate.a = 0.0
	_image.pivot_offset = size / 2.0
	_image.scale = Vector2(1.04, 1.04)
	# Меню грузим заранее, пока идёт заставка, чтобы переход был без задержки.
	ResourceLoader.load_threaded_request(NEXT_SCENE)
	# Картинка всё время чуть «отъезжает» — отдельной анимацией, чтобы не сбивать тайминг.
	create_tween().tween_property(_image, "scale", Vector2.ONE, FADE_IN + HOLD + FADE_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var tw := create_tween()
	tw.tween_property(_image, "modulate:a", 1.0, FADE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_interval(HOLD)
	tw.tween_property(_image, "modulate:a", 0.0, FADE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_go)


func _go() -> void:
	var scene := ResourceLoader.load_threaded_get(NEXT_SCENE) as PackedScene
	get_tree().change_scene_to_packed(scene)

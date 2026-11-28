extends Control
## Заставка при запуске: картинка плавно проявляется, держится и плавно гаснет, затем меню.

const NEXT_SCENE := "res://scenes/menu.tscn"
const FADE_IN := 0.9
const HOLD := 2.6
const FADE_OUT := 0.8

@onready var _image: TextureRect = $Image


func _ready() -> void:
	_image.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_image, "modulate:a", 1.0, FADE_IN).set_trans(Tween.TRANS_SINE)
	# Меню грузим в фоне, только когда картинка уже проявилась: загрузка не дёргает анимацию.
	tw.tween_callback(func(): ResourceLoader.load_threaded_request(NEXT_SCENE))
	tw.tween_interval(HOLD)
	tw.tween_property(_image, "modulate:a", 0.0, FADE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_go)


func _go() -> void:
	var scene := ResourceLoader.load_threaded_get(NEXT_SCENE) as PackedScene
	get_tree().change_scene_to_packed(scene)

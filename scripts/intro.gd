extends Control
## Интро-ролик «С чего всё началось». Показывается при самом первом запуске игры вместо заставки.
## Пропустить его нельзя. После ролика открывается меню.

const MENU_SCENE := "res://scenes/menu.tscn"
const VIDEO := "res://video/intro.ogv"
const FADE := 0.4

var _player: VideoStreamPlayer
var _cover: ColorRect
var _leaving := false


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_player = VideoStreamPlayer.new()
	_player.stream = load(Lang.localized_path(VIDEO))
	_player.expand = true
	_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Settings.sound_on and not Settings.music_on:
		_player.volume_db = -80.0
	_player.finished.connect(_leave)
	add_child(_player)

	_cover = ColorRect.new()
	_cover.color = Color.BLACK
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cover)
	create_tween().tween_property(_cover, "color:a", 0.0, FADE)

	Settings.mark_intro_seen()
	_player.play()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(_cover, "color:a", 1.0, FADE)
	tw.parallel().tween_property(_player, "volume_db", -40.0, FADE)
	tw.tween_callback(_go)


func _go() -> void:
	_player.stop()
	get_tree().change_scene_to_file(MENU_SCENE)

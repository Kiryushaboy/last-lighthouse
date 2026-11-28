class_name Outro
extends CanvasLayer
## Аутро-ролик: огонь возвращается на побережье. Играет поверх забега после победы над Левиафаном
## в последней ночи, один раз. Пропустить его нельзя. По окончании — сигнал finished.

signal finished

const VIDEO_PATH := "res://video/outro.ogv"
const FADE := 0.5

var _player: VideoStreamPlayer
var _cover: ColorRect
var _leaving := false


## Ролик показываем, когда пройдена последняя ночь кампании и аутро ещё не видели.
static func should_play(night_index: int, tutorial: bool, endless: bool) -> bool:
	return not tutorial and not endless and night_index == Nights.count() - 1 and not Settings.outro_seen


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # забег на паузе, а ролик идёт

	_cover = ColorRect.new()
	_cover.color = Color(0, 0, 0, 0)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cover)

	var path: String = VIDEO_PATH
	_player = VideoStreamPlayer.new()
	_player.stream = load(path)
	_player.expand = true
	_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player.modulate.a = 0.0
	if not Settings.sound_on and not Settings.music_on:
		_player.volume_db = -80.0
	_player.finished.connect(_leave)
	add_child(_player)

	Settings.mark_outro_seen()
	Sound.set_music_paused(true)
	# Экран забега плавно уходит в чёрное, затем проявляется ролик.
	var tw := create_tween()
	tw.tween_property(_cover, "color:a", 1.0, FADE)
	tw.tween_callback(_player.play)
	tw.tween_property(_player, "modulate:a", 1.0, FADE)


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(_player, "modulate:a", 0.0, FADE)
	tw.parallel().tween_property(_player, "volume_db", -40.0, FADE)
	tw.tween_callback(_player.stop)
	tw.tween_callback(Sound.set_music_paused.bind(false))
	tw.tween_property(_cover, "color:a", 0.0, FADE)
	tw.tween_callback(func():
		finished.emit()
		queue_free())

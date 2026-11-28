class_name Outro
extends CanvasLayer
## Аутро-ролик: огонь возвращается на побережье. Играет поверх забега после победы над Левиафаном
## в последней ночи, один раз. Касание, клик или клавиша пропускают. По окончании — сигнал finished.

signal finished

const VIDEO_PATH := "res://video/outro.ogv"
const SKIP_AFTER := 1.0
const FADE := 0.5

var _player: VideoStreamPlayer
var _hint: Label
var _cover: ColorRect
var _elapsed := 0.0
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

	_hint = Label.new()
	_hint.text = "Коснитесь, чтобы пропустить"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -70
	_hint.offset_bottom = -40
	_hint.offset_left = -300
	_hint.offset_right = 300
	_hint.modulate.a = 0.0
	add_child(_hint)

	Settings.mark_outro_seen()
	Sound.set_music_paused(true)
	# Экран забега плавно уходит в чёрное, затем проявляется ролик.
	var tw := create_tween()
	tw.tween_property(_cover, "color:a", 1.0, FADE)
	tw.tween_callback(_player.play)
	tw.tween_property(_player, "modulate:a", 1.0, FADE)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed > SKIP_AFTER + FADE and _hint.modulate.a == 0.0 and not _leaving:
		var tw := create_tween()
		tw.tween_property(_hint, "modulate:a", 1.0, 0.5)
		tw.tween_interval(2.5)
		tw.tween_property(_hint, "modulate:a", 0.35, 0.8)


func _input(event: InputEvent) -> void:
	if _elapsed < SKIP_AFTER + FADE:
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if pressed:
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(_player, "modulate:a", 0.0, FADE)
	tw.parallel().tween_property(_player, "volume_db", -40.0, FADE)
	tw.parallel().tween_property(_hint, "modulate:a", 0.0, FADE)
	tw.tween_callback(_player.stop)
	tw.tween_callback(Sound.set_music_paused.bind(false))
	tw.tween_property(_cover, "color:a", 0.0, FADE)
	tw.tween_callback(func():
		finished.emit()
		queue_free())

extends Control
## Интро-ролик «С чего всё началось». Показывается при первом нажатии «Играть», до обучения.
## Касание, клик или любая клавиша пропускают ролик (после короткой паузы, чтобы не пропустить случайно).

const TUTORIAL_SCENE := "res://scenes/main.tscn"  ## учебная ночь, если обучение ещё не пройдено
const MAP_SCENE := "res://scenes/map.tscn"
const VIDEO := "res://video/intro.ogv"
const SKIP_AFTER := 1.0  ## через сколько секунд можно пропустить
const FADE := 0.4

var _player: VideoStreamPlayer
var _hint: Label
var _cover: ColorRect
var _elapsed := 0.0
var _leaving := false


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_player = VideoStreamPlayer.new()
	_player.stream = load(VIDEO)
	_player.expand = true
	_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	_cover = ColorRect.new()
	_cover.color = Color.BLACK
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cover)
	create_tween().tween_property(_cover, "color:a", 0.0, FADE)

	Settings.mark_intro_seen()
	_player.play()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed > SKIP_AFTER and _hint.modulate.a == 0.0 and not _leaving:
		var tw := create_tween()
		tw.tween_property(_hint, "modulate:a", 1.0, 0.5)
		tw.tween_interval(2.5)
		tw.tween_property(_hint, "modulate:a", 0.35, 0.8)


func _input(event: InputEvent) -> void:
	if _elapsed < SKIP_AFTER:
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if pressed:
		_leave()


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
	# Дальше — как после кнопки «Играть»: обучение при первом запуске, иначе карта маяков.
	if not SaveData.tutorial_done:
		SaveData.current_night = Nights.TUTORIAL
		get_tree().change_scene_to_file(TUTORIAL_SCENE)
	else:
		get_tree().change_scene_to_file(MAP_SCENE)

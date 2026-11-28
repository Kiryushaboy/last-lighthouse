class_name FakeAd
extends CanvasLayer
## Пробный «ролик» для тестовых сборок без плагина AdMob: тёмный экран с отсчётом.
## Настоящая реклама выглядит иначе, но порядок тот же: ролик, крестик, награда.
## Закрыть раньше времени — без награды, как и в настоящей рекламе за награду.

signal finished(rewarded: bool)

const LENGTH := 4.0

var _left := LENGTH
var _count: Label
var _close: Button
var _done := false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var tag := Label.new()
	tag.text = tr("ТЕСТОВАЯ РЕКЛАМА")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 26)
	tag.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	box.add_child(tag)
	var t := Label.new()
	t.theme_type_variation = &"TitleLabel"
	t.text = tr("Здесь будет ролик")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 44)
	box.add_child(t)
	_count = Label.new()
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count.add_theme_font_size_override("font_size", 30)
	box.add_child(_count)

	_close = Button.new()
	_close.text = "✕"
	_close.focus_mode = Control.FOCUS_NONE
	_close.anchor_left = 1.0
	_close.anchor_right = 1.0
	_close.offset_left = -120
	_close.offset_right = -30
	_close.offset_top = 70
	_close.offset_bottom = 160
	_close.pressed.connect(_finish)
	add_child(_close)
	_close.modulate.a = 0.4


func _process(delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
	_count.text = tr("Награда через %d с") % ceili(_left) if _left > 0.0 else tr("Награда получена! Можно закрыть")
	_close.modulate.a = 1.0 if _left <= 0.0 else 0.4


func _finish() -> void:
	if _done:
		return
	_done = true
	queue_free()
	finished.emit(_left <= 0.0)

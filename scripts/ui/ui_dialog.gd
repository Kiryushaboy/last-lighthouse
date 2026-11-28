class_name UiDialog
extends CanvasLayer
## Окно с вопросом и кнопками поверх всего. Работает и во время паузы.
## dlg.setup(заголовок, текст); dlg.add_choice(надпись, главная?, действие); dlg.open().
## Любая кнопка закрывает окно и выполняет своё действие.

var _dim: ColorRect
var _card: PanelContainer
var _box: VBoxContainer
var _buttons: VBoxContainer


func _init() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.72)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(620, 0)
	center.add_child(_card)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 18)
	_card.add_child(_box)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)


func setup(title: String, text: String, title_color := Color(1, 0.88, 0.55)) -> void:
	var t := Label.new()
	t.theme_type_variation = &"TitleLabel"
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("font_size", 42)
	t.add_theme_color_override("font_color", title_color)
	_box.add_child(t)
	if text != "":
		var l := Label.new()
		l.text = text
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 25)
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		_box.add_child(l)
	_box.add_child(_buttons)


func add_choice(text: String, primary: bool, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 100 if primary else 84)
	if primary:
		b.theme_type_variation = &"PrimaryButton"
	b.pressed.connect(func() -> void:
		queue_free()
		action.call())
	_buttons.add_child(b)
	return b


func open() -> void:
	UiFx.pop_in(_card, _dim)

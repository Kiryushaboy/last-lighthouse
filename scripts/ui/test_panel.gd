class_name TestPanel
extends CanvasLayer
## Скрытое окно тестового режима. Открывается долгим нажатием на «Настройки» в главном меню.
## Сначала просит код; когда режим включён, показывает его состояние и быстрые кнопки.

signal closed

var _dim: ColorRect
var _card: PanelContainer
var _box: VBoxContainer
var _code: LineEdit
var _hint: Label


func _ready() -> void:
	layer = 20
	hide()
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.75)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Окно держим в верхней половине, чтобы его не закрывала клавиатура телефона.
	center.anchor_bottom = 0.62
	add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(600, 0)
	center.add_child(_card)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 16)
	_card.add_child(_box)


func open() -> void:
	_rebuild()
	show()
	UiFx.pop_in(_card, _dim)


func _rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()
	_code = null
	var title := Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.text = "Тестовый режим"
	_box.add_child(title)
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 24)
	_box.add_child(_hint)
	if SaveData.test_mode:
		_hint.text = "Включён. Все ночи и герои открыты, а в мастерской у каждого бонуса кнопки «−» и «+»."
		_hint.add_theme_color_override("font_color", Color(0.6, 1.0, 0.82))
		_button("+1000 ракушек", _add_shells, true)
		_button("Интро и обучение заново", _reset_tutorial, false)
		_button("Посмотреть аутро", _play_outro, false)
		_button("Сбросить покупки и сундук", _reset_shop, false)
		_button("Выключить и вернуть бонусы", _turn_off, false)
	else:
		_hint.text = "Введите код"
		_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		_code = LineEdit.new()
		_code.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_code.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
		_code.secret = true
		_code.max_length = 20
		_code.custom_minimum_size = Vector2(0, 84)
		_code.add_theme_font_size_override("font_size", 36)
		_code.text_submitted.connect(func(_t): _try_code())
		_box.add_child(_code)
		_button("Открыть", _try_code, true)
		_code.grab_focus.call_deferred()
	_button("Закрыть", close, false)


func _button(text: String, action: Callable, primary: bool) -> void:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 84)
	if primary:
		b.theme_type_variation = &"PrimaryButton"
	b.pressed.connect(action)
	_box.add_child(b)


func _try_code() -> void:
	if SaveData.enter_test_code(_code.text):
		Sound.play("levelup")
		Settings.vibrate(60, 0.7)
		DisplayServer.virtual_keyboard_hide()
		_rebuild()
	else:
		Sound.play("warning", -6.0)
		_code.text = ""
		_hint.text = "Неверный код"
		_hint.add_theme_color_override("font_color", Color(1, 0.45, 0.45))


func _add_shells() -> void:
	SaveData.add_shells(1000)
	Sound.play("shell")
	_hint.text = "Ракушек: %d" % SaveData.shells


func _reset_tutorial() -> void:
	SaveData.set_tutorial_done(false)
	Settings.reset_intro()
	Sound.play("shell")
	_hint.text = "Интро покажется при следующем запуске игры, обучение — по кнопке «Играть»."


func _reset_shop() -> void:
	SaveData.reset_shop()
	Sound.play("shell")
	_hint.text = "Покупки забыты, сундук дня снова доступен."


func _play_outro() -> void:
	get_tree().root.add_child(Outro.new())


func _turn_off() -> void:
	SaveData.leave_test_mode()
	Sound.play("shell")
	_rebuild()


func close() -> void:
	DisplayServer.virtual_keyboard_hide()
	hide()
	closed.emit()

class_name SettingsPanel
extends VBoxContainer
## Настройки: чувствительность, звук, музыка, вибрация. Один и тот же блок в паузе и в главном меню.

const TRACK := preload("res://ui/slider_track.tres")
const FILL := preload("res://ui/slider_fill.tres")

var _sens_label: Label
var _sound: Button
var _music: Button


func _ready() -> void:
	add_theme_constant_override("separation", 20)

	_sens_label = Label.new()
	_sens_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_sens_label)

	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(0, 80)
	slider.min_value = Settings.SENSITIVITY_MIN
	slider.max_value = Settings.SENSITIVITY_MAX
	slider.step = 0.1
	slider.value = Settings.sensitivity
	slider.add_theme_stylebox_override("slider", TRACK)
	slider.add_theme_stylebox_override("grabber_area", FILL)
	slider.add_theme_stylebox_override("grabber_area_highlight", FILL)
	slider.value_changed.connect(func(v): Settings.set_sensitivity(v); _update_label())
	add_child(slider)

	var hint := Label.new()
	hint.text = "Больше — меньше вести пальцем до полной скорости"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	add_child(hint)

	_sound = _toggle("Звуки", Settings.sound_on, Settings.set_sound)
	_music = _toggle("Музыка", Settings.music_on, Settings.set_music)
	_toggle("Вибрация", Settings.vibration_on, Settings.set_vibration)
	_update_label()


## Большая кнопка-переключатель: на телефоне в неё легко попасть пальцем.
func _toggle(title: String, on: bool, setter: Callable) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = on
	b.custom_minimum_size = Vector2(0, 90)
	var refresh := func(state: bool): b.text = "%s: %s" % [title, "вкл" if state else "выкл"]
	refresh.call(on)
	b.toggled.connect(func(state: bool): setter.call(state); refresh.call(state))
	add_child(b)
	return b


func _update_label() -> void:
	_sens_label.text = "Чувствительность: %.1f×" % Settings.sensitivity

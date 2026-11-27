class_name PauseMenu
extends CanvasLayer
## Меню паузы: продолжить, начать заново, настроить чувствительность управления.

signal resume_pressed
signal restart_pressed
signal open_requested  ## нажали Esc, когда меню закрыто; решает Main

@onready var _sens_label: Label = $Box/SensLabel
@onready var _sens_slider: HSlider = $Box/SensSlider
@onready var _resume: Button = $Box/Resume
@onready var _restart: Button = $Box/Restart


func _ready() -> void:
	_sens_slider.min_value = Settings.SENSITIVITY_MIN
	_sens_slider.max_value = Settings.SENSITIVITY_MAX
	_sens_slider.value = Settings.sensitivity
	_update_label()
	_sens_slider.value_changed.connect(_on_slider)
	_resume.pressed.connect(resume_pressed.emit)
	_restart.pressed.connect(restart_pressed.emit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			resume_pressed.emit()
		else:
			open_requested.emit()
		get_viewport().set_input_as_handled()


func _on_slider(value: float) -> void:
	Settings.set_sensitivity(value)
	_update_label()


func _update_label() -> void:
	_sens_label.text = "Чувствительность: %.1f×" % Settings.sensitivity

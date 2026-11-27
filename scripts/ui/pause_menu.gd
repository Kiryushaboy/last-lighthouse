class_name PauseMenu
extends CanvasLayer
## Меню паузы: продолжить, начать заново, настройки, выход в главное меню.

signal resume_pressed
signal restart_pressed
signal menu_pressed
signal open_requested  ## нажали Esc, когда меню закрыто; решает Main

@onready var _resume: Button = $Card/Box/Resume
@onready var _restart: Button = $Card/Box/Restart
@onready var _to_menu: Button = $Card/Box/ToMenu


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_resume.pressed.connect(resume_pressed.emit)
	_restart.pressed.connect(restart_pressed.emit)
	_to_menu.pressed.connect(menu_pressed.emit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			resume_pressed.emit()
		else:
			open_requested.emit()
		get_viewport().set_input_as_handled()


## Окно появляется с анимацией каждый раз, когда его показывают.
func _on_visibility_changed() -> void:
	if visible:
		UiFx.pop_in($Card, $Dim)
		UiFx.stagger($Card/Box.get_children())

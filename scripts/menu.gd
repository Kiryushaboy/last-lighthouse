extends Node2D
## Главное меню: маяк светит на фоне, кнопки «Начать ночь», «Мастерская», «Настройки».

const GAME_SCENE := "res://scenes/main.tscn"

@onready var _ui: Control = $UI/Root
@onready var _shells: Label = $UI/Root/Box/Shells
@onready var _play: Button = $UI/Root/Box/Play
@onready var _workshop_btn: Button = $UI/Root/Box/Workshop
@onready var _settings_btn: Button = $UI/Root/Box/Settings
@onready var _workshop: Workshop = $Workshop
@onready var _settings: CanvasLayer = $SettingsLayer
@onready var _settings_back: Button = $SettingsLayer/Box/Back


func _ready() -> void:
	get_tree().paused = false
	_play.pressed.connect(func(): get_tree().change_scene_to_file(GAME_SCENE))
	_workshop_btn.pressed.connect(func(): _ui.hide(); _workshop.open())
	_workshop.closed.connect(_show_menu)
	_settings_btn.pressed.connect(func(): _ui.hide(); _settings.show())
	_settings_back.pressed.connect(func(): _settings.hide(); _show_menu())
	_show_menu()


func _show_menu() -> void:
	_shells.text = "Ракушки: %d" % SaveData.shells
	_ui.show()


func _unhandled_input(event: InputEvent) -> void:
	# Кнопка «Назад» на Android и Esc на ноутбуке закрывают окна меню.
	if event.is_action_pressed("ui_cancel"):
		if _settings.visible:
			_settings_back.pressed.emit()
		elif _workshop.visible:
			_workshop.hide()
			_workshop.closed.emit()

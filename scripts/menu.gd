extends Node2D
## Главное меню: маяк светит на фоне, кнопки «Играть», «Мастерская» (бонусы и герои), «Настройки», «Выйти».

const GAME_SCENE := "res://scenes/map.tscn"  ## «Начать ночь» ведёт на карту маяков

const HOLD_TIME := 1.2  ## сколько держать «Настройки», чтобы открылось тестовое окно

var _test_panel: TestPanel
var _hold := 0.0
var _holding := false
var _held := false

@onready var _ui: Control = $UI/Root
@onready var _shells: Label = $UI/Root/Box/Shells
@onready var _play: Button = $UI/Root/Box/Play
@onready var _workshop_btn: Button = $UI/Root/Box/Workshop
@onready var _settings_btn: Button = $UI/Root/Box/Settings
@onready var _workshop: Workshop = $Workshop
@onready var _settings: CanvasLayer = $SettingsLayer
@onready var _settings_back: Button = $SettingsLayer/Card/Box/Back


func _ready() -> void:
	SafeArea.apply(_ui)
	get_tree().paused = false
	UiTheme.apply(Nights.progress_chapter())
	Sound.play_music("menu")
	_play.pressed.connect(_on_play)
	_workshop_btn.pressed.connect(func(): _ui.hide(); _workshop.open())
	_workshop.closed.connect(_show_menu)
	_settings_btn.pressed.connect(_on_settings_pressed)
	# Долгое нажатие на «Настройки» открывает скрытое окно тестового режима.
	_settings_btn.button_down.connect(func(): _hold = 0.0; _holding = true; _held = false)
	_settings_btn.button_up.connect(func(): _holding = false)
	_test_panel = TestPanel.new()
	add_child(_test_panel)
	_test_panel.closed.connect(_on_test_closed)
	$UI/Root/Box/Quit.pressed.connect(func(): get_tree().quit())
	_settings_back.pressed.connect(func(): _settings.hide(); _show_menu())
	_settings.visibility_changed.connect(_on_settings_visibility)
	_show_menu()
	UiFx.stagger([$UI/Root/Title, $UI/Root/Subtitle] + $UI/Root/Box.get_children(), 0.08, 0.1)


func _on_play() -> void:
	# Самое первое «Играть»: сначала интро-ролик, после него интро само откроет обучение или карту.
	if not Settings.intro_seen:
		get_tree().change_scene_to_file("res://scenes/intro.tscn")
		return
	# Первый запуск: вместо карты — короткая учебная ночь.
	if not SaveData.tutorial_done:
		SaveData.current_night = Nights.TUTORIAL
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_pressed() -> void:
	if _held:
		return
	_ui.hide()
	_settings.show()


func _on_test_closed() -> void:
	# Тема и открытые главы могли измениться.
	_show_menu()


func _show_menu() -> void:
	_shells.text = "Ракушки: %d" % SaveData.shells
	_ui.show()


func _unhandled_input(event: InputEvent) -> void:
	# Кнопка «Назад» на Android и Esc на ноутбуке закрывают окна меню.
	if event.is_action_pressed("ui_cancel"):
		if _test_panel.visible:
			_test_panel.close()
		elif _settings.visible:
			_settings_back.pressed.emit()
		elif _workshop.visible:
			_workshop.close()


func _on_settings_visibility() -> void:
	if _settings.visible:
		UiFx.pop_in($SettingsLayer/Card, $SettingsLayer/Dim)


func _process(_delta: float) -> void:
	if _holding and not _held:
		_hold += _delta
		if _hold >= HOLD_TIME:
			_held = true
			_holding = false
			Settings.vibrate(40, 0.6)
			_ui.hide()
			_test_panel.open()
	# Название мягко покачивается, как на волнах.
	var t := Time.get_ticks_msec() / 1000.0
	$UI/Root/Title.rotation = sin(t * 0.8) * 0.015
	$UI/Root/Title.pivot_offset = $UI/Root/Title.size / 2.0

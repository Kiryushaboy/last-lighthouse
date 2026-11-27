class_name EndScreen
extends CanvasLayer
## Экран конца ночи: победа на рассвете или гибель, ракушки, вход в мастерскую.

signal restart_pressed
signal workshop_pressed
signal menu_pressed

@onready var _title: Label = $Card/Box/Title
@onready var _stats: Label = $Card/Box/Stats
@onready var _shells: Label = $Card/Box/Shells
@onready var _restart: Button = $Card/Box/Restart
@onready var _workshop: Button = $Card/Box/Workshop
@onready var _to_menu: Button = $Card/Box/ToMenu


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_restart.pressed.connect(restart_pressed.emit)
	_workshop.pressed.connect(workshop_pressed.emit)
	_to_menu.pressed.connect(menu_pressed.emit)


func show_result(won: bool, level: int, survived: float, shells: int) -> void:
	_title.text = "Рассвет! Маяк устоял" if won else "Маяк погас"
	_title.add_theme_color_override("font_color", Color(1, 0.85, 0.45) if won else Color(1, 0.5, 0.5))
	var s := int(survived)
	_stats.text = "Продержались %d:%02d\nУровень %d" % [s / 60, s % 60, level]
	show()
	# Ракушки досчитываются на глазах — приятно смотреть на награду.
	var tw := create_tween().set_ignore_time_scale()
	tw.tween_interval(0.4)
	tw.tween_method(func(v: float): _shells.text = "Ракушек за ночь: %d (всего %d)" % [int(v), SaveData.shells - shells + int(v)],
			0.0, float(shells), clampf(shells * 0.04, 0.3, 1.2))
	tw.tween_callback(func(): UiFx.bump(_shells, 1.2))


## Окно появляется с анимацией каждый раз, когда его показывают.
func _on_visibility_changed() -> void:
	if visible:
		UiFx.pop_in($Card, $Dim)
		UiFx.stagger($Card/Box.get_children())

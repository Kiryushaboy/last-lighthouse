class_name EndScreen
extends CanvasLayer
## Экран конца ночи: победа на рассвете или гибель, ракушки, вход в мастерскую.

signal restart_pressed
signal workshop_pressed

@onready var _title: Label = $Box/Title
@onready var _stats: Label = $Box/Stats
@onready var _shells: Label = $Box/Shells
@onready var _restart: Button = $Box/Restart
@onready var _workshop: Button = $Box/Workshop


func _ready() -> void:
	_restart.pressed.connect(restart_pressed.emit)
	_workshop.pressed.connect(workshop_pressed.emit)


func show_result(won: bool, level: int, survived: float, shells: int) -> void:
	_title.text = "Рассвет! Маяк устоял" if won else "Маяк погас"
	var s := int(survived)
	_stats.text = "Продержались %d:%02d\nУровень %d" % [s / 60, s % 60, level]
	_shells.text = "Ракушек за ночь: %d (всего %d)" % [shells, SaveData.shells]
	show()

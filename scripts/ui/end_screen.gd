class_name EndScreen
extends CanvasLayer
## Экран конца ночи: победа на рассвете или гибель.

signal restart_pressed

@onready var _title: Label = $Box/Title
@onready var _stats: Label = $Box/Stats
@onready var _restart: Button = $Box/Restart


func _ready() -> void:
	_restart.pressed.connect(restart_pressed.emit)


func show_result(won: bool, level: int, survived: float) -> void:
	_title.text = "Рассвет! Маяк устоял" if won else "Маяк погас"
	var s := int(survived)
	_stats.text = "Продержались %d:%02d\nУровень %d" % [s / 60, s % 60, level]
	show()

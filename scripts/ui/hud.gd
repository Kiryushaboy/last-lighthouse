class_name Hud
extends CanvasLayer
## Интерфейс поверх игры: таймер, опыт, жизни, уровень, кнопка паузы.

signal pause_pressed

@onready var _time: Label = $Root/TimeLabel
@onready var _hp: Label = $Root/HPLabel
@onready var _level: Label = $Root/LevelLabel
@onready var _xp_bar: ProgressBar = $Root/XPBar


func _ready() -> void:
	$Root/PauseButton.pressed.connect(pause_pressed.emit)


func set_time(seconds_left: float) -> void:
	var s := int(ceil(maxf(seconds_left, 0.0)))
	_time.text = "%d:%02d" % [s / 60, s % 60] if s > 0 else "Рассвет близко"


func set_health(hp: int, max_hp: int) -> void:
	_hp.text = "Жизни: %d/%d" % [maxi(hp, 0), max_hp]


func set_xp(xp: int, xp_to_next: int, level: int) -> void:
	_xp_bar.max_value = xp_to_next
	_xp_bar.value = xp
	_level.text = "Ур. %d" % level


func show_boss(hp: int, max_hp: int) -> void:
	$Root/BossLabel.show()
	$Root/BossBar.show()
	set_boss_health(hp, max_hp)


func set_boss_health(hp: int, max_hp: int) -> void:
	var bar: ProgressBar = $Root/BossBar
	bar.max_value = max_hp
	bar.value = hp


func set_shells(count: int) -> void:
	$Root/ShellsLabel.text = "Ракушки: %d" % count

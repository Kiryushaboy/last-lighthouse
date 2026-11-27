class_name Hud
extends CanvasLayer
## Интерфейс поверх игры: таймер, опыт, жизни, уровень, кнопка паузы.

signal pause_pressed

@onready var _time: Label = $Root/TimeLabel
@onready var _hearts: Hearts = $Root/Hearts
@onready var _level: Label = $Root/LevelLabel
@onready var _xp_bar: ProgressBar = $Root/XPBar

var _xp_tween: Tween


func _ready() -> void:
	$Root/PauseButton.pressed.connect(pause_pressed.emit)


func set_time(seconds_left: float) -> void:
	var s := int(ceil(maxf(seconds_left, 0.0)))
	var text := "%d:%02d" % [s / 60, s % 60] if s > 0 else "Рассвет близко"
	if text != _time.text:
		_time.text = text
		# Последние 10 секунд таймер вздрагивает и желтеет — рассвет близко.
		if s <= 10 and s > 0:
			_time.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
			UiFx.bump(_time, 1.2)


func set_health(hp: int, max_hp: int) -> void:
	_hearts.set_values(hp, max_hp)


func set_xp(xp: int, xp_to_next: int, level: int) -> void:
	var new_level := "Ур. %d" % level
	if new_level != _level.text:
		_level.text = new_level
		UiFx.bump(_level, 1.5)
		_xp_bar.value = 0.0
	_xp_bar.max_value = xp_to_next
	# Полоса опыта плавно доезжает до нового значения.
	if _xp_tween:
		_xp_tween.kill()
	_xp_tween = create_tween().set_ignore_time_scale()
	_xp_tween.tween_property(_xp_bar, "value", float(xp), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
	UiFx.bump($Root/ShellsLabel, 1.3)

class_name EndScreen
extends CanvasLayer
## Экран конца ночи: победа на рассвете или гибель, ракушки, вход в мастерскую.

signal restart_pressed
signal workshop_pressed
signal menu_pressed
signal next_pressed

@onready var _title: Label = $Card/Box/Title
@onready var _stats: Label = $Card/Box/Stats
@onready var _shells: Label = $Card/Box/Shells
@onready var _restart: Button = $Card/Box/Restart
@onready var _workshop: Button = $Card/Box/Workshop
@onready var _to_menu: Button = $Card/Box/ToMenu
@onready var _next: Button = $Card/Box/Next


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_restart.pressed.connect(restart_pressed.emit)
	_workshop.pressed.connect(workshop_pressed.emit)
	_to_menu.pressed.connect(menu_pressed.emit)
	_next.pressed.connect(next_pressed.emit)


func show_result(r: Dictionary) -> void:
	var won: bool = r.won
	_title.text = "Рассвет! Маяк устоял" if won else "Маяк погас"
	_title.add_theme_color_override("font_color", Color(1, 0.85, 0.45) if won else Color(1, 0.5, 0.5))
	$Card/Box/Night.text = "Ночь %d · %s" % [r.night + 1, r.title]
	($Card/Box/Stars as StarsView).set_stars(r.stars, true)
	# Три условия звёзд с галочками — видно, чего не хватило.
	var checks: VBoxContainer = $Card/Box/Checks
	for c in checks.get_children():
		c.queue_free()
	var lines := [
		"Пережить ночь",
		"Потерять не больше %d сердец (потеряно %d)" % [Nights.MAX_HITS_FOR_STAR, r.hits],
		"%s: %d/%d" % [r.task, mini(r.task_progress, r.task_goal), r.task_goal],
	]
	for i in 3:
		var l := Label.new()
		l.text = ("✓  " if r.stars[i] else "✗  ") + lines[i]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 23)
		l.add_theme_color_override("font_color", Color(0.55, 1, 0.8) if r.stars[i] else Color(1, 1, 1, 0.45))
		checks.add_child(l)
	var s := int(r.survived)
	_stats.text = "Продержались %d:%02d · уровень %d" % [s / 60, s % 60, r.level]
	_next.visible = won and r.has_next
	show()
	# Ракушки досчитываются на глазах — приятно смотреть на награду.
	var shells: int = r.shells
	var bonus := "" if r.star_bonus == 0 else "\nиз них %d — за новые звёзды" % r.star_bonus
	var tw := create_tween().set_ignore_time_scale()
	tw.tween_interval(0.8)
	tw.tween_method(func(v: float): _shells.text = "Ракушек за ночь: %d (всего %d)%s" % [int(v), SaveData.shells - shells + int(v), bonus],
			0.0, float(shells), clampf(shells * 0.03, 0.3, 1.2))
	tw.tween_callback(func(): UiFx.bump(_shells, 1.2))


## Окно появляется с анимацией каждый раз, когда его показывают.
func _on_visibility_changed() -> void:
	if visible:
		UiFx.pop_in($Card, $Dim)
		UiFx.stagger($Card/Box.get_children())

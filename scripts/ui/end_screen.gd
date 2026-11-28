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

var _double: Button  ## «Удвоить ракушки» за рекламу, один раз
var _run_shells := 0


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_restart.pressed.connect(restart_pressed.emit)
	_workshop.pressed.connect(workshop_pressed.emit)
	_to_menu.pressed.connect(menu_pressed.emit)
	_next.pressed.connect(next_pressed.emit)
	_double = Button.new()
	_double.focus_mode = Control.FOCUS_NONE
	_double.custom_minimum_size = Vector2(0, 90)
	_double.add_theme_color_override("font_color", Color(1, 0.8, 0.86))
	_double.pressed.connect(_on_double)
	$Card/Box.add_child(_double)
	$Card/Box.move_child(_double, _shells.get_index() + 1)


## Показать кнопку удвоения, если за ночь что-то собрано.
func _offer_double(shells: int, allowed: bool) -> void:
	_run_shells = shells
	_double.visible = allowed and shells > 0
	_double.disabled = false
	_double.text = ("Удвоить ракушки: +%d" if SaveData.no_ads else "▶  Удвоить ракушки за рекламу: +%d") % shells


func _on_double() -> void:
	_double.disabled = true
	Shop.rewarded("double", func(ok: bool) -> void:
		if not ok:
			_double.disabled = false
			return
		SaveData.add_shells(_run_shells)
		_shells.text = "Ракушек за ночь: %d × 2 = %d (всего %d)" % [_run_shells, _run_shells * 2, SaveData.shells]
		_double.hide()
		Sound.play("shell")
		UiFx.bump(_shells, 1.25))


func show_result(r: Dictionary) -> void:
	var won: bool = r.won
	if r.endless:
		_show_endless(r)
		return
	$Card/Box/Stars.show()
	_title.text = "Рассвет! Маяк устоял" if won else "Маяк погас"
	_title.add_theme_color_override("font_color", Color(1, 0.85, 0.45) if won else Color(1, 0.5, 0.5))
	$Card/Box/Night.text = "Ночь %d · %s" % [r.night + 1, r.title]
	if r.get("tutorial", false):
		_title.text = "Вахта сдана! Вы готовы" if won else "Маяк погас. Бывает!"
		$Card/Box/Night.text = "Обучение · %s" % r.title
		$Card/Box/Stars.hide()
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
	checks.visible = not r.get("tutorial", false)
	var s := int(r.survived)
	_stats.text = "Продержались %d:%02d · уровень %d" % [s / 60, s % 60, r.level]
	_next.visible = won and r.has_next
	_fit_title()
	show()
	# Ракушки досчитываются на глазах — приятно смотреть на награду.
	var shells: int = r.shells
	_offer_double(shells, not r.get("tutorial", false))
	var bonus := "" if r.star_bonus == 0 else "\nиз них %d — за новые звёзды" % r.star_bonus
	if r.get("tutorial", false):
		bonus = "\nиз них %d — подарок старого смотрителя" % r.star_bonus
	var tw := create_tween().set_ignore_time_scale()
	tw.tween_interval(0.8)
	tw.tween_method(func(v: float): _shells.text = "Ракушек за ночь: %d (всего %d)%s" % [int(v), SaveData.shells - shells + int(v), bonus],
			0.0, float(shells), clampf(shells * 0.03, 0.3, 1.2))
	tw.tween_callback(func(): UiFx.bump(_shells, 1.2))


## Итог бесконечной ночи: счётчики и рекорды вместо звёзд.
func _show_endless(r: Dictionary) -> void:
	var new_record: bool = r.records[0] or r.records[1]
	_title.text = "Новый рекорд!" if new_record else "Маяк погас"
	_title.add_theme_color_override("font_color", Color(1, 0.85, 0.45) if new_record else Color(1, 0.5, 0.5))
	$Card/Box/Night.text = "Бесконечная ночь"
	$Card/Box/Stars.hide()
	var checks: VBoxContainer = $Card/Box/Checks
	for c in checks.get_children():
		c.queue_free()
	var s := int(r.survived)
	var b := int(SaveData.best_time)
	var lines := [
		["Продержались %d:%02d (рекорд %d:%02d)" % [s / 60, s % 60, b / 60, b % 60], r.records[0]],
		["Побеждено врагов: %d (рекорд %d)" % [r.kills, SaveData.best_kills], r.records[1]],
	]
	for line in lines:
		var l := Label.new()
		l.text = ("★  " if line[1] else "") + line[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 26)
		l.add_theme_color_override("font_color", Color(1, 0.85, 0.4) if line[1] else Color(1, 1, 1, 0.8))
		checks.add_child(l)
	_stats.text = "Уровень %d" % r.level
	_next.visible = false
	_fit_title()
	show()
	var shells: int = r.shells
	_offer_double(shells, true)
	_shells.text = "Ракушек за ночь: %d (всего %d)" % [shells, SaveData.shells]
	if new_record:
		UiFx.bump(_title, 1.3)


## Длинный заголовок уменьшаем, чтобы он помещался в окно в одну строку.
func _fit_title() -> void:
	var font := _title.get_theme_font("font")
	var fs := 52
	while fs > 34 and font.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 540.0:
		fs -= 2
	_title.add_theme_font_size_override("font_size", fs)


## Окно появляется с анимацией каждый раз, когда его показывают.
func _on_visibility_changed() -> void:
	if visible:
		UiFx.pop_in($Card, $Dim)
		UiFx.stagger($Card/Box.get_children())

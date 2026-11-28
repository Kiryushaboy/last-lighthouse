class_name Hud
extends CanvasLayer
## Интерфейс поверх игры: таймер, опыт, жизни, уровень, кнопка паузы.

signal pause_pressed

@onready var _time: Label = $Root/TimeLabel
@onready var _hearts: Hearts = $Root/Hearts
@onready var _level: Label = $Root/LevelLabel
@onready var _xp_bar: ProgressBar = $Root/XPBar

var _xp_tween: Tween

var _hint_box: PanelContainer
var _hint_text: Label
var _hint_tween: Tween


func _ready() -> void:
	SafeArea.apply($Root)
	$Root/PauseButton.pressed.connect(pause_pressed.emit)


func set_time(seconds: float, counting_up := false) -> void:
	var s := int(seconds) if counting_up else int(ceil(maxf(seconds, 0.0)))
	var text := "%d:%02d" % [s / 60, s % 60] if (s > 0 or counting_up) else "Рассвет близко"
	if counting_up:
		_time.text = text
		return
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


func show_boss(hp: int, max_hp: int, title := "") -> void:
	if title != "":
		$Root/BossLabel.text = title
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


## Задание ночи в углу: «Победить 70 врагов: 23/70», галочка, когда готово.
## Три звезды ночи — три строки: дожить, не терять много сердец, выполнить задание.
## Звезда горит золотом, когда условие выполнено, и гаснет, если его уже не выполнить.
func set_star_tasks(hits: int, max_hits: int, task: String, progress: int, goal: int) -> void:
	if _star_rows.is_empty():
		_build_star_rows()
	_set_star_row(0, "Дожить до рассвета", 0)
	var hits_state := 0 if hits <= max_hits else -1
	_set_star_row(1, "Потерять не больше %d сердец: %d/%d" % [max_hits, mini(hits, max_hits + 1), max_hits], hits_state)
	_set_star_row(2, "%s: %d/%d" % [task, mini(progress, goal), goal], 1 if progress >= goal else 0)


var _star_rows: Array[Label] = []


func _build_star_rows() -> void:
	var box := VBoxContainer.new()
	box.position = $Root/TaskLabel.position
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(box)
	$Root/TaskLabel.hide()
	for i in 3:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 21)
		l.add_theme_constant_override("outline_size", 6)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		l.set_meta("state", 0)
		box.add_child(l)
		_star_rows.append(l)


## state: 1 — выполнено, 0 — в процессе, -1 — провалено.
func _set_star_row(i: int, text: String, state: int) -> void:
	var l := _star_rows[i]
	l.text = "★ " + text
	var col := Color(1, 1, 1, 0.8)
	if state == 1:
		col = Color(1.0, 0.85, 0.35)
	elif state == -1:
		col = Color(1, 1, 1, 0.3)
	l.add_theme_color_override("font_color", col)
	if state != int(l.get_meta("state")):
		l.set_meta("state", state)
		if state == 1:
			UiFx.bump(l, 1.3)


## Заставка в начале ночи: название, особое условие, задание. Сама исчезает.
func show_night_banner(title: String, modifier: String, task: String) -> void:
	var banner: Control = $Root/Banner
	$Root/Banner/Title.text = title
	$Root/Banner/Modifier.text = modifier
	$Root/Banner/Modifier.visible = modifier != ""
	$Root/Banner/Task.text = "Задание: " + task
	banner.show()
	banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.4)
	tw.tween_interval(2.6)
	tw.tween_property(banner, "modulate:a", 0.0, 0.6)
	tw.tween_callback(banner.hide)


## Крупная надпись при появлении босса. Работает и пока игра на паузе.
func show_boss_banner(title: String, subtitle: String) -> void:
	var banner: Control = $Root/Banner
	$Root/Banner/Title.text = title
	$Root/Banner/Modifier.text = subtitle
	$Root/Banner/Modifier.visible = true
	$Root/Banner/Task.text = ""
	banner.show()
	banner.modulate.a = 0.0
	banner.pivot_offset = banner.size / 2.0
	banner.scale = Vector2(1.4, 1.4)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.6)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(banner.hide)


## Бесконечная ночь: в углу рекорд и счётчик врагов этой ночи.
func set_record(record_text: String, kills: int) -> void:
	$Root/TaskLabel.text = "Врагов: %d   %s" % [kills, record_text]


func hide_boss() -> void:
	$Root/BossLabel.hide()
	$Root/BossBar.hide()


## Подсказка обучения: табличка со словами старого смотрителя. Выезжает снизу и сама уходит.
func show_hint(text: String) -> void:
	if _hint_box == null:
		_hint_box = PanelContainer.new()
		_hint_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hint_box.anchor_left = 0.0
		_hint_box.anchor_right = 1.0
		_hint_box.anchor_top = 0.27
		_hint_box.anchor_bottom = 0.27
		_hint_box.offset_left = 24
		_hint_box.offset_right = -24
		_hint_box.grow_vertical = Control.GROW_DIRECTION_END
		$Root.add_child(_hint_box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hint_box.add_child(row)
		var face := TextureRect.new()
		face.texture = preload("res://art/sprites/lighthouse.svg")
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.custom_minimum_size = Vector2(72, 72)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(face)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)
		var who := Label.new()
		who.text = "Старый смотритель"
		who.add_theme_font_size_override("font_size", 20)
		who.add_theme_color_override("font_color", Color(1, 0.85, 0.45))
		col.add_child(who)
		_hint_text = Label.new()
		_hint_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_hint_text.add_theme_font_size_override("font_size", 25)
		col.add_child(_hint_text)
	_hint_text.text = text
	_hint_box.show()
	_hint_box.modulate.a = 0.0
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint_box, "modulate:a", 1.0, 0.3)
	_hint_tween.tween_interval(6.0)
	_hint_tween.tween_property(_hint_box, "modulate:a", 0.0, 0.5)
	_hint_tween.tween_callback(_hint_box.hide)
	Sound.play("click", -6.0)

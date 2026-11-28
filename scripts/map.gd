extends Control
## Карта «Маяки побережья»: пять глав-страниц и бесконечная ночь. На странице — рисунок главы
## с тропой из шести маяков; нажали на маяк — внизу карточка ночи и кнопка «В бой».

const GAME_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
const SHELL := preload("res://art/sprites/seashell.svg")
const MODIFIER_ICON := {"fog": "🌫", "storm": "⚡", "swarm": "🦀", "dark": "🌑"}

var _chapter := 0
var _selected := 0
var _pages := Nights.CHAPTERS.size() + 1  ## последняя страница — бесконечная ночь

var _path: MapPath
var _title: Label
var _sub: Label
var _total: Label
var _prev: Button
var _next: Button
var _info: PanelContainer
var _info_title: Label
var _info_enemies: HBoxContainer
var _info_lines: VBoxContainer
var _go: Button
var _endless_box: VBoxContainer
var _swipe_from := Vector2.INF


func _ready() -> void:
	get_tree().paused = false
	Sound.play_music("map")
	_build()
	# Открываем на первой непройденной ночи.
	var target := 0
	for i in Nights.count():
		if Nights.is_unlocked(i):
			target = i
			if SaveData.stars_of(i) == 0:
				break
	_selected = target
	_show_page(target / Nights.NIGHTS_PER_CHAPTER)
	UiFx.stagger([_title, _sub, _path, _info], 0.07, 0.05)


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)
	SafeArea.apply_margin(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	# Шапка: стрелки по бокам, название главы и время суток в середине.
	var head := HBoxContainer.new()
	box.add_child(head)
	_prev = _arrow("◀", -1)
	head.add_child(_prev)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	_title = _label("", 40, Color(1, 0.88, 0.55))
	_title.theme_type_variation = &"TitleLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(_title)
	_sub = _label("", 22, Color(0.7, 0.92, 1))
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles.add_child(_sub)
	_next = _arrow("▶", 1)
	head.add_child(_next)

	_total = _label("", 24, Color(1, 0.82, 0.4))
	_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_total)

	_path = MapPath.new()
	_path.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_path.night_selected.connect(_select)
	box.add_child(_path)

	_endless_box = VBoxContainer.new()
	_endless_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_endless_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_endless_box.add_theme_constant_override("separation", 14)
	_endless_box.hide()
	box.add_child(_endless_box)

	# Карточка выбранной ночи.
	_info = PanelContainer.new()
	box.add_child(_info)
	var ib := VBoxContainer.new()
	ib.add_theme_constant_override("separation", 6)
	_info.add_child(ib)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	ib.add_child(top)
	_info_title = _label("", 30, Color(1, 0.88, 0.55))
	_info_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_info_title)
	_info_enemies = HBoxContainer.new()
	_info_enemies.add_theme_constant_override("separation", 2)
	top.add_child(_info_enemies)
	_info_lines = VBoxContainer.new()
	_info_lines.add_theme_constant_override("separation", 0)
	ib.add_child(_info_lines)
	_go = Button.new()
	_go.theme_type_variation = &"PrimaryButton"
	_go.custom_minimum_size = Vector2(0, 96)
	_go.focus_mode = Control.FOCUS_NONE
	_go.add_theme_font_size_override("font_size", 34)
	_go.pressed.connect(_start)
	ib.add_child(_go)

	var back := Button.new()
	back.text = tr("Назад")
	back.custom_minimum_size = Vector2(0, 104)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_back)
	box.add_child(back)


func _arrow(text: String, step: int) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(76, 76)
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_turn.bind(step))
	return b


func _turn(step: int) -> void:
	var page := clampi(_chapter + step, 0, _pages - 1)
	if page == _chapter:
		return
	if page < Nights.CHAPTERS.size():
		# На новой странице выбираем первую непройденную открытую ночь главы.
		_selected = page * Nights.NIGHTS_PER_CHAPTER
		for i in Nights.NIGHTS_PER_CHAPTER:
			var n := page * Nights.NIGHTS_PER_CHAPTER + i
			if Nights.is_unlocked(n):
				_selected = n
				if SaveData.stars_of(n) == 0:
					break
	_show_page(page)
	UiFx.bump(_title, 1.12)


func _show_page(page: int) -> void:
	_chapter = page
	_prev.disabled = page == 0
	_next.disabled = page == _pages - 1
	_total.text = tr("★ %d из %d      Ракушки: %d") % [SaveData.total_stars(), Nights.count() * 3, SaveData.shells]
	var endless_page := page >= Nights.CHAPTERS.size()
	var ch: Dictionary = Nights.CHAPTERS[mini(page, Nights.CHAPTERS.size() - 1)]
	UiTheme.apply(mini(page, Nights.CHAPTERS.size() - 1))
	var mat := $Bg.material as ShaderMaterial
	for key in ["deep", "shallow", "foam"]:
		mat.set_shader_parameter(key, ch.theme[key])
	_path.visible = not endless_page
	_endless_box.visible = endless_page
	if endless_page:
		_title.text = tr("Бесконечная ночь")
		_sub.text = tr("Награда за кампанию")
		_fill_endless()
		return
	_title.text = ch.title
	_sub.text = tr("Глава %d · %s") % [page + 1, tr(ch.time_of_day)]
	_path.set_chapter(page)
	_select(_selected)


func _select(night: int) -> void:
	_selected = night
	_path.selected = night
	var n := Nights.get_night(night)
	var unlocked := Nights.is_unlocked(night)
	_info_title.text = "%d. %s" % [night + 1, tr(n.title)]
	for c in _info_enemies.get_children():
		c.queue_free()
	for c in _info_lines.get_children():
		c.queue_free()
	if not unlocked:
		_info_lines.add_child(_label(tr("Откроется после ночи %d") % night, 22, Color(1, 1, 1, 0.5)))
		_go.text = tr("Закрыто")
		_go.disabled = true
		return
	# Кто встретится этой ночью — картинками.
	var shown := {}
	for e in n.enemies:
		if shown.has(e[0]) or shown.size() >= 6:
			continue
		shown[e[0]] = true
		var tr := TextureRect.new()
		tr.texture = load("res://art/sprites/%s.svg" % e[0])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(44, 44)
		_info_enemies.add_child(tr)
	var mod: String = n.get("modifier", "")
	if n.has("boss_at"):
		var boss: Dictionary = Boss.KINDS[Nights.chapter_of(night).boss]
		_info_lines.add_child(_label(tr("☠ Босс: %s") % tr(boss.title), 22, Color(1, 0.5, 0.5)))
	if mod != "":
		_info_lines.add_child(_label("%s %s" % [MODIFIER_ICON[mod], tr(Nights.MODIFIER_TEXT[mod])], 21, Color(0.7, 0.92, 1)))
	_info_lines.add_child(_label("★★★ %s" % Nights.task_text(n.task), 21, Color(1, 1, 1, 0.75)))
	_go.text = tr("В бой")
	_go.disabled = false


func _fill_endless() -> void:
	for c in _endless_box.get_children():
		c.queue_free()
	for c in _info_lines.get_children():
		c.queue_free()
	for c in _info_enemies.get_children():
		c.queue_free()
	var unlocked := Nights.endless_unlocked()
	var big := _label("∞", 220, Color(1, 0.85, 0.45) if unlocked else Color(1, 1, 1, 0.2))
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_endless_box.add_child(big)
	_info_title.text = tr("Бесконечная ночь")
	_selected = Nights.ENDLESS
	if unlocked:
		var b := int(SaveData.best_time)
		var rec := tr("Рекорд: %d:%02d · врагов %d") % [b / 60, b % 60, SaveData.best_kills] if b > 0 else tr("Сколько продержитесь?")
		var r := _label(rec, 30, Color(1, 0.88, 0.55))
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_endless_box.add_child(r)
		_info_lines.add_child(_label(tr("Событие каждые 2 минуты, босс каждые 5"), 21, Color(0.7, 0.92, 1)))
		_go.text = tr("В бой")
		_go.disabled = false
	else:
		_info_lines.add_child(_label(tr("Откроется после ночи %d") % (Nights.ENDLESS_AFTER + 1), 22, Color(1, 1, 1, 0.5)))
		_go.text = tr("Закрыто")
		_go.disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()
	# Листание глав свайпом влево-вправо.
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_from = event.position
		elif _swipe_from != Vector2.INF:
			var d: Vector2 = event.position - _swipe_from
			_swipe_from = Vector2.INF
			if absf(d.x) > 120.0 and absf(d.x) > absf(d.y) * 1.5:
				_turn(-1 if d.x > 0.0 else 1)


func _back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _label(t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _start() -> void:
	SaveData.current_night = _selected
	get_tree().change_scene_to_file(GAME_SCENE)

class_name Tutorial
extends CanvasLayer
## Обучение первой ночи. Старый смотритель рассказывает об игре по шагам:
## игра встаёт на паузу, экран темнеет, а то, о чём речь, остаётся в светящемся окне.
## Шаги приходят по событиям боя (первый враг, первая искра, первое улучшение…).

const SHADER := preload("res://shaders/spotlight.gdshader")
const FACE := preload("res://art/sprites/keeper_old.svg")
const GAP := 1.6  ## пауза между шагами, чтобы не сыпались подряд
const WALK_GOAL := 520.0  ## сколько пройти в упражнении на движение
const GOLD := Color(1.0, 0.84, 0.4)

var main: Node  ## главная сцена боя
var hold := true  ## пока игрок учится ходить, ночь не идёт и враги не приходят
var skipped := false

var _queue: Array[Dictionary] = []
var _seen := {}
var _step := {}  ## текущий шаг с паузой; пусто — обучение молчит
var _page := 0
var _cool := 0.6
var _beam_from := -1.0  ## когда выбрано первое улучшение: после него рассказ про луч
var _passive := ""  ## ключ подсказки без паузы (поверх выбора улучшения)
var _walked := -1.0  ## пройдено в упражнении; -1 — упражнение не идёт
var _last_pos := Vector2.ZERO
var _typing: Tween
var _card_tween: Tween
var _hole_tween: Tween
var _shown_at := 0.0  ## сколько секунд страница на экране

var _root: Control
var _dim: ColorRect
var _mat: ShaderMaterial
var _demo: Control
var _card: PanelContainer
var _title: Label
var _text: Label
var _dots: Label
var _next: Label
var _skip: Button
var _chip: PanelContainer
var _chip_text: Label
var _chip_bar: ProgressBar


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


# --- Что говорит смотритель --------------------------------------------

func begin() -> void:
	_say("welcome", [
		{"title": tr("Первая вахта"), "text": tr("Добро пожаловать на маяк, юнга! Я сорок лет зажигаю этот огонь. Сегодня покажу, как дожить до рассвета.")},
		{"title": tr("Движение"), "text": tr("Коснитесь нижней части экрана и ведите пальцем — герой пойдёт следом. Отпустите палец, и он остановится."),
				"target": _move_zone, "demo": true},
	])


func on_upgrade_offered() -> void:
	if skipped or _seen.has("upgrade"):
		return
	_seen["upgrade"] = true
	_passive = "upgrade"
	_show_passive(tr("Улучшения"), tr("Выберите одно из трёх. Оно останется с вами до конца ночи, а взятое повторно станет сильнее."),
			main.upgrade_menu.get_node("Box/Choices"))


func on_upgrade_chosen() -> void:
	if _passive == "upgrade":
		_hide_passive()
		_beam_from = main.elapsed


func on_hit() -> void:
	_say_hud()


func _say_hud() -> void:
	_say("hud", [
		{"title": tr("Сердца"), "text": tr("Каждое касание врага стоит одного сердца. Кончатся сердца — ночь проиграна. На первую вахту я выдал вам запас."),
				"target": _control_rect.bind("Hearts", Vector2(10, 2))},
		{"title": tr("Рассвет"), "text": tr("Это время до рассвета. Доживёте — ночь ваша."), "target": _control_rect.bind("TimeLabel", Vector2(-190, 2))},
		{"title": tr("Звёзды"), "text": tr("За ночь дают до трёх звёзд: дожить до рассвета, сберечь сердца и выполнить задание. Звёзды приносят ракушки."),
				"target": _stars_rect},
	])


func busy() -> bool:
	return not _step.is_empty()


# --- Ход обучения ------------------------------------------------------

func _process(delta: float) -> void:
	if skipped or main == null:
		return
	_shown_at += delta
	if busy() or get_tree().paused:
		return
	_cool -= delta
	if _walked >= 0.0:
		_track_walk()
		return
	if hold:
		if _cool <= 0.0 and not _queue.is_empty():
			_start(_queue.pop_front())
		return
	if main.elapsed >= 45.0:
		_say_hud()
	# Шаги «по месту» начинаются, только когда то, о чём речь, видно на экране.
	if _cool <= 0.0 and _queue.is_empty() and _passive == "" and main.can_tutor():
		_look_around()
	if not _seen.has("dawn") and main.time_left <= 15.0:
		_seen["dawn"] = true
		_passive = "dawn"
		_show_passive(tr("Рассвет близко"), tr("Ещё немного, юнга! Продержитесь до первых лучей."), null)
		get_tree().create_timer(5.0).timeout.connect(_hide_passive.bind("dawn"))
	if _cool <= 0.0 and not _queue.is_empty() and _passive == "" and main.can_tutor():
		_start(_queue.pop_front())


func _say(key: String, pages: Array) -> void:
	if skipped or _seen.has(key):
		return
	_seen[key] = true
	_queue.append({"key": key, "pages": pages})


func _look_around() -> void:
	var me: Vector2 = main.player.global_position
	if not _seen.has("enemy"):
		for e: Node2D in main.enemies.get_children():
			if me.distance_to(e.global_position) < 380.0 and _on_screen(e, 70.0):
				_say("enemy", [
					{"title": tr("Гости из глубины"), "text": tr("Морские твари ползут на свет маяка. Стрелять не нужно: герой сам бьёт ближайшего. Ваше дело — не дать себя окружить."),
							"target": _around.bind(e, 64.0)},
				])
				return
		return
	for g: Node2D in main.gems.get_children():
		if g.is_queued_for_deletion() or not _on_screen(g, 60.0):
			continue
		if g.get("is_shell") and not _seen.has("shells"):
			_say("shells", [
				{"title": tr("Ракушки"), "text": tr("А вот и ракушка! Подберите её — это здешние деньги."), "target": _around.bind(g, 54.0)},
				{"title": tr("Ракушки"), "text": tr("Счёт ракушек — здесь. После ночи загляните в мастерскую: за ракушки там продают вечные бонусы и новых героев."),
						"target": _label_rect.bind("ShellsLabel")},
			])
			return
		if not g.get("is_shell") and not _seen.has("xp"):
			_say("xp", [
				{"title": tr("Искры опыта"), "text": tr("Из побеждённых тварей выпадают искры. Подойдите ближе — они притянутся сами."), "target": _around.bind(g, 54.0)},
				{"title": tr("Искры опыта"), "text": tr("Искры заполняют эту полосу. Когда она заполнится, вы выберете улучшение."),
						"target": _control_rect.bind("XPBar", Vector2(10, 10))},
			])
			return
	# Про луч рассказываем, когда маяк в кадре (или если игрок долго к нему не подходит).
	if _beam_from >= 0.0 and not _seen.has("beam") and (_on_screen(main.beam, 130.0) or main.elapsed - _beam_from > 12.0):
		_say("beam", [
			{"title": tr("Луч маяка"), "text": tr("Свет маяка — ваш союзник. Враги в луче замедляются и получают двойной урон. Заманивайте их под луч!"),
					"target": _lighthouse},
		])


func _on_screen(node: Node2D, margin: float) -> bool:
	return Rect2(Vector2.ZERO, _screen()).grow(-margin).has_point(_to_screen(node))


func _start(step: Dictionary) -> void:
	_step = step
	_page = 0
	main.joystick.reset()
	get_tree().paused = true
	_root.show()
	_dim.show()
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip.show()
	_mat.set_shader_parameter("dim", 0.8)
	var tw := create_tween()
	tw.tween_method(_set_open, 0.0, 1.0, 0.25)
	_show_page()


func _show_page() -> void:
	var page: Dictionary = _step.pages[_page]
	_shown_at = 0.0
	var rect := Rect2()
	if page.has("target"):
		rect = (page.target as Callable).call()
	_focus(rect, page.get("round", false))
	_demo.visible = page.get("demo", false)
	await _fill_card(page.title, page.text, "%d / %d" % [_page + 1, _step.pages.size()] if _step.pages.size() > 1 else "")
	if not busy():
		return
	_place_card(rect)
	_next.show()
	Sound.play("click", -8.0)


## Нажатие в любом месте: сначала дописать текст, потом — дальше.
func advance() -> void:
	if not busy():
		return
	if _typing and _typing.is_running():
		_typing.kill()
		_text.visible_ratio = 1.0
		return
	# Защита от случайного двойного касания.
	if _shown_at < 0.35:
		return
	_page += 1
	if _page < _step.pages.size():
		_show_page()
	else:
		_finish_step()


func _finish_step() -> void:
	var key: String = _step.key
	_step = {}
	_cool = GAP
	_demo.hide()
	_skip.hide()
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_method(_set_open, 1.0, 0.0, 0.2)
	tw.parallel().tween_property(_card, "modulate:a", 0.0, 0.2)
	tw.tween_callback(_after_hide)
	get_tree().paused = false
	if key == "welcome" and not skipped:
		_walked = 0.0
		_last_pos = main.player.global_position
		_chip_text.text = tr("Пройдитесь по причалу")
		_chip_bar.value = 0.0
		_show_chip()


func _after_hide() -> void:
	if not busy() and _passive == "":
		_card.hide()
		_dim.hide()


func _track_walk() -> void:
	var pos: Vector2 = main.player.global_position
	_walked += pos.distance_to(_last_pos)
	_last_pos = pos
	_chip_bar.value = _walked / WALK_GOAL
	if _walked >= WALK_GOAL:
		_walked = -1.0
		hold = false
		_cool = 1.0
		_chip_text.text = tr("Отлично! Теперь — в бой")
		_chip_text.add_theme_color_override("font_color", Color(0.6, 1.0, 0.8))
		Sound.play("levelup", -10.0)
		UiFx.bump(_chip, 1.12)
		var tw := create_tween()
		tw.tween_interval(1.6)
		tw.tween_property(_chip, "modulate:a", 0.0, 0.4)
		tw.tween_callback(_chip.hide)


func _on_skip() -> void:
	skipped = true
	hold = false
	_walked = -1.0
	_queue.clear()
	_chip.hide()
	if busy():
		_finish_step()


## Бой кончился: убираем всё с экрана.
func close() -> void:
	skipped = true
	_step = {}
	_passive = ""
	_root.hide()


# --- Подсказка без паузы (поверх выбора улучшения) ----------------------

func _show_passive(title: String, text: String, around: Control) -> void:
	_root.show()
	_skip.hide()
	_demo.hide()
	_next.hide()
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rect := Rect2()
	if around:
		# Меню только что открылось: ждём кадр, пока контейнер разложит карточки.
		await get_tree().process_frame
		await get_tree().process_frame
		if _passive == "":
			return
		rect = around.get_global_rect().grow(12.0)
	_dim.visible = around != null
	_mat.set_shader_parameter("dim", 0.0)
	_set_open(1.0)
	_focus(rect, false)
	await _fill_card(title, text, "")
	if _passive == "":
		return
	_place_card(rect, true)


func _hide_passive(only := "") -> void:
	if _passive == "" or (only != "" and _passive != only):
		return
	_passive = ""
	_cool = GAP
	if busy():
		return
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 0.0, 0.2)
	tw.parallel().tween_method(_set_open, 1.0, 0.0, 0.2)
	tw.tween_callback(_after_hide)


# --- На что показываем -------------------------------------------------

func _screen() -> Vector2:
	return get_viewport().get_visible_rect().size


func _to_screen(node: Node2D) -> Vector2:
	return node.get_global_transform_with_canvas().origin


## Круглое окно вокруг предмета в мире.
func _around(node: Variant, r: float) -> Rect2:
	if not is_instance_valid(node):
		return Rect2()
	var at := _to_screen(node as Node2D)
	return Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0)


func _lighthouse() -> Rect2:
	var at := _to_screen(main.beam)
	if not Rect2(Vector2.ZERO, _screen()).grow(-40.0).has_point(at):
		return Rect2()
	return Rect2(at - Vector2(120, 120), Vector2(240, 240))


func _control_rect(node_name: String, pad: Vector2) -> Rect2:
	var c := main.hud.get_node("Root/" + node_name) as Control
	return c.get_global_rect().grow_individual(pad.x, pad.y, pad.x, pad.y)


## Окно по размеру самой надписи, а не всей её строки.
func _label_rect(node_name: String) -> Rect2:
	var l := main.hud.get_node("Root/" + node_name) as Label
	return Rect2(l.global_position, l.get_minimum_size()).grow_individual(12, 1, 14, 1)


func _stars_rect() -> Rect2:
	var rows: Array = main.hud._star_rows
	if rows.is_empty():
		return Rect2()
	var box := (rows[0] as Control).get_parent() as Control
	return box.get_global_rect().grow(12.0)


func _move_zone() -> Rect2:
	var s := _screen()
	return Rect2(s.x * 0.5 - 250.0, s.y * 0.74 - 180.0, 500.0, 360.0)


# --- Оформление --------------------------------------------------------

func _set_open(v: float) -> void:
	_mat.set_shader_parameter("open", v)


func _focus(rect: Rect2, _round: bool) -> void:
	_mat.set_shader_parameter("screen", _screen())
	if rect.size == Vector2.ZERO:
		_mat.set_shader_parameter("hole", Vector4(-9999, -9999, 0, 0))
		return
	var half := rect.size / 2.0
	var c := rect.get_center()
	_mat.set_shader_parameter("hole", Vector4(c.x, c.y, half.x, half.y))
	# Круглые цели получают круглое окно, полосы и строки — скруглённый прямоугольник.
	_mat.set_shader_parameter("radius", minf(half.x, half.y) if absf(half.x - half.y) < 2.0 else 22.0)
	if _hole_tween:
		_hole_tween.kill()
	_hole_tween = create_tween()
	_hole_tween.tween_method(func(g: float) -> void: _mat.set_shader_parameter("grow", g), 260.0, 0.0, 0.45) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_demo.position = c
	_demo.queue_redraw()


func _fill_card(title: String, text: String, dots: String) -> void:
	title = tr(title)
	text = tr(text)
	_title.text = title
	_text.text = text
	_dots.text = dots
	var font: Font = ThemeDB.get_project_theme().default_font
	if font == null:
		font = ThemeDB.fallback_font
	var width := _screen().x - 48.0 - 44.0 - 132.0 - 18.0
	_text.custom_minimum_size = Vector2(width, font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, 25).y + 4.0)
	# Перенос строк считается кадром позже, поэтому карточку показываем после него.
	_card.modulate.a = 0.0
	_card.show()
	_card.size = Vector2(_screen().x - 48.0, 0.0)
	await get_tree().process_frame
	_card.size = Vector2(_screen().x - 48.0, 0.0)
	_text.visible_ratio = 0.0
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, text.length() / 70.0)


## Карточка встаёт рядом с окном, но не закрывает его; без окна — по центру.
func _place_card(rect: Rect2, prefer_below := false) -> void:
	var s := _screen()
	var h := _card.size.y
	var y := s.y * 0.5 - h * 0.5
	if prefer_below and rect.size == Vector2.ZERO:
		y = s.y * 0.2  # подсказка без паузы не должна закрывать героя
	if rect.size != Vector2.ZERO:
		if prefer_below and rect.end.y + 28.0 + h <= s.y - 16.0:
			y = rect.end.y + 28.0
			_card.show()
			_card.position = Vector2(24.0, y)
			_card.modulate.a = 0.0
			create_tween().tween_property(_card, "modulate:a", 1.0, 0.25)
			return
		if rect.get_center().y < s.y * 0.5:
			y = rect.end.y + 44.0
		else:
			y = rect.position.y - h - 44.0
	y = clampf(y, 150.0, s.y - h - 60.0)
	var from_below := rect.size == Vector2.ZERO or rect.get_center().y < s.y * 0.5
	_card.show()
	_card.position = Vector2(24.0, y + (36.0 if from_below else -36.0))
	_card.modulate.a = 0.0
	if _card_tween:
		_card_tween.kill()
	_card_tween = create_tween().set_parallel()
	_card_tween.tween_property(_card, "position:y", y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_card_tween.tween_property(_card, "modulate:a", 1.0, 0.2)


func _show_chip() -> void:
	_chip.show()
	_chip.reset_size()
	_chip.position = Vector2((_screen().x - _chip.size.x) / 2.0, _screen().y * 0.24)
	_chip.modulate.a = 0.0
	create_tween().tween_property(_chip, "modulate:a", 1.0, 0.3)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("glow", UiTheme.accent.lerp(Color.WHITE, 0.25))
	_mat.set_shader_parameter("open", 0.0)
	_dim.material = _mat
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.gui_input.connect(_on_dim_input)
	_dim.hide()
	_root.add_child(_dim)

	_demo = TouchDemo.new()
	_demo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_demo.hide()
	_root.add_child(_demo)

	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UiTheme.tile_bg().darkened(0.25), 0.97)
	sb.set_corner_radius_all(30)
	sb.corner_detail = 12
	sb.set_border_width_all(3)
	sb.border_color = Color(GOLD, 0.9)
	sb.shadow_color = Color(GOLD, 0.28)
	sb.shadow_size = 22
	sb.anti_aliasing_size = 1.5
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 20
	sb.content_margin_bottom = 18
	_card.add_theme_stylebox_override("panel", sb)
	_card.hide()
	_root.add_child(_card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(row)

	var face := TextureRect.new()
	face.texture = FACE
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.custom_minimum_size = Vector2(132, 132)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(face)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)

	var who := Label.new()
	who.text = tr("СТАРЫЙ СМОТРИТЕЛЬ")
	who.add_theme_font_size_override("font_size", 17)
	who.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	col.add_child(who)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 31)
	_title.add_theme_color_override("font_color", GOLD)
	col.add_child(_title)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 25)
	_text.add_theme_constant_override("line_spacing", 2)
	col.add_child(_text)

	var foot := HBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(foot)
	_dots = Label.new()
	_dots.add_theme_font_size_override("font_size", 19)
	_dots.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_dots)
	_next = Label.new()
	_next.text = tr("Нажмите, чтобы продолжить  ›")
	_next.add_theme_font_size_override("font_size", 19)
	_next.add_theme_color_override("font_color", GOLD)
	foot.add_child(_next)
	var blink := create_tween().set_loops()
	blink.tween_property(_next, "modulate:a", 0.35, 0.6).set_trans(Tween.TRANS_SINE)
	blink.tween_property(_next, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

	_skip = Button.new()
	_skip.text = tr("Пропустить обучение")
	_skip.flat = true
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.add_theme_font_size_override("font_size", 21)
	_skip.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	_skip.anchor_left = 1.0
	_skip.anchor_right = 1.0
	_skip.anchor_top = 1.0
	_skip.anchor_bottom = 1.0
	_skip.offset_left = -300
	_skip.offset_right = -20
	_skip.offset_top = -84
	_skip.offset_bottom = -28
	_skip.pressed.connect(_on_skip)
	_skip.hide()
	_root.add_child(_skip)

	_chip = PanelContainer.new()
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cb := sb.duplicate() as StyleBoxFlat
	cb.set_corner_radius_all(26)
	cb.content_margin_top = 14
	cb.content_margin_bottom = 16
	cb.content_margin_left = 30
	cb.content_margin_right = 30
	cb.shadow_size = 14
	_chip.add_theme_stylebox_override("panel", cb)
	_chip.hide()
	_root.add_child(_chip)
	var chip_col := VBoxContainer.new()
	chip_col.add_theme_constant_override("separation", 10)
	_chip.add_child(chip_col)
	_chip_text = Label.new()
	_chip_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip_text.add_theme_font_size_override("font_size", 26)
	_chip_text.add_theme_color_override("font_color", GOLD)
	chip_col.add_child(_chip_text)
	_chip_bar = ProgressBar.new()
	_chip_bar.max_value = 1.0
	_chip_bar.step = 0.001
	_chip_bar.show_percentage = false
	_chip_bar.custom_minimum_size = Vector2(340, 14)
	chip_col.add_child(_chip_bar)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		advance()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		advance()


## Показ жеста: палец касается экрана и ведёт в сторону, за ним тянется джойстик.
class TouchDemo:
	extends Control

	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()

	func _draw() -> void:
		var t := fmod(Time.get_ticks_msec() / 1000.0, 2.6)
		# 0–0.4 — касание, 0.4–1.9 — ведём по кругу, дальше — отпускаем.
		var press := clampf(t / 0.4, 0.0, 1.0)
		var fade := 1.0 - clampf((t - 2.1) / 0.5, 0.0, 1.0)
		var a := press * fade
		var drag := clampf((t - 0.4) / 0.5, 0.0, 1.0)
		var ang := -PI / 2.0 + (t - 0.4) * 2.4
		var knob := Vector2.from_angle(ang) * 78.0 * ease(drag, 0.4)
		draw_circle(Vector2.ZERO, 110.0, Color(1, 1, 1, 0.07 * a))
		draw_arc(Vector2.ZERO, 110.0, 0.0, TAU, 64, Color(1, 1, 1, 0.35 * a), 3.0, true)
		draw_line(Vector2.ZERO, knob, Color(1.0, 0.84, 0.4, 0.5 * a), 4.0, true)
		draw_circle(knob, 40.0, Color(1.0, 0.84, 0.4, 0.3 * a))
		draw_circle(knob, 26.0, Color(1, 1, 1, 0.9 * a))
		draw_arc(knob, 40.0 + 18.0 * (1.0 - press), 0.0, TAU, 48, Color(1.0, 0.84, 0.4, 0.8 * a), 3.0, true)

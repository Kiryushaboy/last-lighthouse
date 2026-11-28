class_name Workshop
extends CanvasLayer
## Мастерская: две вкладки. «Бонусы» — вечные улучшения за ракушки (плитки из SaveData.PERKS),
## «Герои» — выбор и покупка героя (Heroes.LIST). Всё собирается кодом.

signal closed

const SHELL := preload("res://art/sprites/seashell.svg")
const GLOW := preload("res://art/fx/glow.tres")
const WEAPON_TEXT := {"harpoon": "Гарпуны", "lightning": "Цепная молния", "aura": "Огненный круг", "bats": "Летучие мыши", "wave": "Песня-волна"}

var _tab := "perks"
var _shells: Label
var _scroll: ScrollContainer
var _content: Control
var _tab_buttons := {}
var _root: Control


func _ready() -> void:
	_build()


func open(tab := "perks") -> void:
	_tab = tab
	_rebuild()
	show()
	UiFx.pop_in(_root)
	_scroll.scroll_vertical = 0


func close() -> void:
	hide()
	closed.emit()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(UiTheme.tile_bg().darkened(0.55), 1.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	_root = margin
	SafeArea.apply_margin.call_deferred(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = "Мастерская"
	title.add_theme_font_size_override("font_size", 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	# Счётчик ракушек: значок и число.
	var purse := HBoxContainer.new()
	purse.alignment = BoxContainer.ALIGNMENT_CENTER
	purse.add_theme_constant_override("separation", 8)
	box.add_child(purse)
	purse.add_child(_picture(SHELL, 44))
	_shells = Label.new()
	_shells.add_theme_font_size_override("font_size", 38)
	_shells.add_theme_color_override("font_color", Color(1, 0.8, 0.86))
	purse.add_child(_shells)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	box.add_child(tabs)
	for t in [["perks", "Бонусы"], ["heroes", "Герои"]]:
		var b := Button.new()
		b.text = t[1]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 84)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_switch.bind(t[0]))
		tabs.add_child(b)
		_tab_buttons[t[0]] = b

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	box.add_child(_scroll)

	var back := Button.new()
	back.text = "Назад"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(0, 104)
	back.pressed.connect(close)
	box.add_child(back)


func _switch(tab: String) -> void:
	if tab == _tab:
		return
	_tab = tab
	_rebuild()
	_scroll.scroll_vertical = 0
	UiFx.stagger(_content.get_children(), 0.04, 0.0)


func _rebuild() -> void:
	_shells.text = str(SaveData.shells)
	for id in _tab_buttons:
		(_tab_buttons[id] as Button).theme_type_variation = &"PrimaryButton" if id == _tab else &""
	if _content:
		_content.queue_free()
	if _tab == "perks":
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		for p in SaveData.PERKS:
			grid.add_child(_make_perk(p))
		_content = grid
	else:
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 16)
		for h in Heroes.LIST:
			list.add_child(_make_hero(h))
		_content = list
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	UiFx.touch_scroll(_scroll)


## Плитка с рамкой цвета col и мягким свечением.
func _tile(col: Color, strong := false) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiTheme.tile_bg().lerp(col, 0.1)
	style.border_color = Color(col, 0.95 if strong else 0.55)
	style.set_border_width_all(4 if strong else 2)
	style.border_width_bottom = 6
	style.set_corner_radius_all(26)
	style.set_content_margin_all(14)
	style.shadow_color = Color(col, 0.3 if strong else 0.14)
	style.shadow_size = 14
	style.anti_aliasing_size = 1.5
	card.add_theme_stylebox_override("panel", style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card


func _make_perk(p: Dictionary) -> Control:
	var lvl := SaveData.level_of(p.id)
	var cost := SaveData.next_cost(p.id)
	var max_lvl: int = p.costs.size()
	var col := UpgradeIcon.color_of(p.id)
	var card := _tile(col)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var icon := UpgradeIcon.new()
	icon.id = p.id
	icon.icon_size = 132.0
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	var title := _label(p.title, 25, col.lightened(0.45))
	title.custom_minimum_size.y = 64
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(title)
	box.add_child(_label(_change_text(p.id, lvl, lvl >= max_lvl), 21, Color(0.6, 1.0, 0.82)))
	var pips := Pips.new()
	pips.level = lvl
	pips.max_level = max_lvl
	pips.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(pips)

	if SaveData.test_mode:
		# Тестовый режим: уровень бонуса можно свободно убавлять и прибавлять.
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		for step in [-1, 1]:
			var b := Button.new()
			b.text = "−" if step < 0 else "+"
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, 76)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.theme_type_variation = &"PrimaryButton" if step > 0 else &""
			b.disabled = (lvl <= 0) if step < 0 else (lvl >= max_lvl)
			b.pressed.connect(_shift.bind(p.id, step))
			row.add_child(b)
		box.add_child(row)
		return card

	var buy := Button.new()
	buy.focus_mode = Control.FOCUS_NONE
	buy.custom_minimum_size = Vector2(0, 76)
	if cost < 0:
		buy.text = "Макс."
		buy.disabled = true
	else:
		buy.theme_type_variation = &"PrimaryButton"
		buy.disabled = SaveData.shells < cost
		_price(buy, cost)
	buy.pressed.connect(_buy.bind(p.id))
	box.add_child(buy)
	return card


## Цена на кнопке: ракушка и число рядом, вместе по центру.
func _price(button: Button, cost: int) -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_bottom = -6
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.modulate.a = 0.5 if button.disabled else 1.0
	button.add_child(row)
	row.add_child(_picture(SHELL, 36))
	var num := Label.new()
	num.text = str(cost)
	# Обычный шрифт без обводки и с разрядкой: тёмные цифры на жёлтой кнопке не слипаются.
	var font := FontVariation.new()
	font.base_font = ThemeDB.get_project_theme().default_font
	font.spacing_glyph = 2
	num.add_theme_font_override("font", font)
	num.add_theme_font_size_override("font_size", 34)
	num.add_theme_constant_override("outline_size", 0)
	num.add_theme_color_override("font_color", button.get_theme_color("font_color", "PrimaryButton"))
	row.add_child(num)


func _make_hero(h: Dictionary) -> Control:
	var owned: bool = SaveData.hero_owned(h.id)
	var chosen: bool = SaveData.hero == h.id
	var neon: Color = h.neon
	var card := _tile(neon, chosen)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	# Портрет: свечение цвета героя и сам герой, закрытый — тёмным силуэтом.
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(170, 170)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(portrait)
	var glow := _picture(GLOW, 0)
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.modulate = Color(neon, 0.55 if owned else 0.15)
	portrait.add_child(glow)
	var sprite := _picture(load(h.sprite), 0)
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.modulate = Color.WHITE if owned else Color(0.16, 0.18, 0.26)
	portrait.add_child(sprite)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 4)
	row.add_child(text)
	var name_label := _label(h.title, 34, neon.lightened(0.4))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.theme_type_variation = &"TitleLabel"
	text.add_child(name_label)
	var weapon := _label("%s  ·  ♥ %d" % [WEAPON_TEXT.get(h.weapon, ""), h.hp], 22, Color(0.6, 1.0, 0.82))
	weapon.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.add_child(weapon)
	var desc := _label(h.desc, 20, Color(1, 1, 1, 0.75))
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.add_child(desc)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 76)
	if chosen:
		btn.text = "Выбран"
		btn.disabled = true
	elif owned:
		btn.text = "Выбрать"
		btn.theme_type_variation = &"PrimaryButton"
	else:
		btn.theme_type_variation = &"PrimaryButton"
		btn.disabled = SaveData.shells < h.cost
		_price(btn, h.cost)
	btn.pressed.connect(_choose.bind(h.id))
	text.add_child(btn)
	return card


func _picture(tex: Texture2D, side: int) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if side > 0:
		tr.custom_minimum_size = Vector2(side, side)
	return tr


func _label(t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


## Что именно даст следующий уровень, в цифрах.
func _change_text(id: String, lvl: int, maxed: bool) -> String:
	var now := ""
	var next := ""
	match id:
		"hp":
			return ("Сердец: %d" % (5 + lvl)) if maxed else "Сердец: %d → %d" % [5 + lvl, 6 + lvl]
		"power":
			return ("Урон: +%d" % lvl) if maxed else "Урон: +%d → +%d" % [lvl, lvl + 1]
		"crit":
			now = "%d%%" % (lvl * 8); next = "%d%%" % ((lvl + 1) * 8)
			return ("Двойной урон: %s" % now) if maxed else "Двойной урон: %s → %s" % [now, next]
		"speed":
			now = "+%d%%" % (lvl * 5); next = "+%d%%" % ((lvl + 1) * 5)
			return ("Скорость: %s" % now) if maxed else "Скорость: %s → %s" % [now, next]
		"start":
			return ("Улучшений сразу: %d" % lvl) if maxed else "Улучшений сразу: %d → %d" % [lvl, lvl + 1]
		"bubble":
			return "Щит уже на старте" if maxed else "Щит с первой секунды"
		"regen":
			if maxed:
				return "Сердце раз в %d с" % SaveData.REGEN_EVERY[lvl]
			if lvl == 0:
				return "Сердце раз в %d с" % SaveData.REGEN_EVERY[1]
			return "Сердце раз в %d → %d с" % [SaveData.REGEN_EVERY[lvl], SaveData.REGEN_EVERY[lvl + 1]]
		"pull":
			now = "+%d%%" % (lvl * 15); next = "+%d%%" % ((lvl + 1) * 15)
			return ("Радиус сбора: %s" % now) if maxed else "Радиус сбора: %s → %s" % [now, next]
		"luck":
			now = "+%d%%" % (lvl * 10); next = "+%d%%" % ((lvl + 1) * 10)
			return ("Ракушек: %s" % now) if maxed else "Ракушек: %s → %s" % [now, next]
	return ""


func _buy(id: String) -> void:
	if not UiFx.tap_ok(_scroll) or not SaveData.buy(id):
		return
	Sound.play("levelup", -4.0)
	Settings.vibrate(50, 0.6)
	var index := SaveData.PERKS.map(func(p): return p.id).find(id)
	_rebuild_keep_scroll(index)


func _shift(id: String, step: int) -> void:
	if not UiFx.tap_ok(_scroll):
		return
	SaveData.shift_level(id, step)
	Sound.play("levelup" if step > 0 else "shell", -6.0)
	_rebuild_keep_scroll(SaveData.PERKS.map(func(p): return p.id).find(id))


func _choose(id: String) -> void:
	if not UiFx.tap_ok(_scroll):
		return
	var bought: bool = not SaveData.hero_owned(id)
	if not SaveData.choose_hero(id, Heroes.get_hero(id).cost):
		return
	Sound.play("levelup" if bought else "shell", -4.0)
	var index := Heroes.LIST.map(func(h): return h.id).find(id)
	_rebuild_keep_scroll(index)


## Пересобрать вкладку, не сбивая прокрутку, и подсветить изменившуюся плитку.
func _rebuild_keep_scroll(index: int) -> void:
	var pos := _scroll.scroll_vertical
	_rebuild()
	UiFx.bump(_shells, 1.3)
	await get_tree().process_frame
	_scroll.scroll_vertical = pos
	if index >= 0 and index < _content.get_child_count():
		var tile := _content.get_child(index) as Control
		tile.pivot_offset = tile.size / 2.0
		tile.modulate = Color(1.8, 1.6, 1.2)
		tile.scale = Vector2(1.06, 1.06)
		var tw := tile.create_tween().set_ignore_time_scale().set_parallel()
		tw.tween_property(tile, "modulate", Color.WHITE, 0.5)
		tw.tween_property(tile, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

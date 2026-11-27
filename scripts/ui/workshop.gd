class_name Workshop
extends CanvasLayer
## Мастерская: вечные бонусы за ракушки. Строки собираются из SaveData.PERKS.

signal closed

const SHELL := preload("res://art/sprites/seashell.svg")

@onready var _shells: Label = $Card/Box/Shells
@onready var _rows: VBoxContainer = $Card/Box/Scroll/Rows
@onready var _back: Button = $Card/Box/Back


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_back.pressed.connect(_close)


func open() -> void:
	_rebuild()
	show()


func _close() -> void:
	hide()
	closed.emit()


func _rebuild() -> void:
	_shells.text = "Ракушки: %d" % SaveData.shells
	for child in _rows.get_children():
		child.queue_free()
	for p in SaveData.PERKS:
		_rows.add_child(_make_row(p))


## Строка бонуса: значок, название, что даст следующий уровень, точки уровней и кнопка цены.
func _make_row(p: Dictionary) -> Control:
	var lvl := SaveData.level_of(p.id)
	var cost := SaveData.next_cost(p.id)
	var max_lvl: int = p.costs.size()

	var card := PanelContainer.new()
	var style := ($Card.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	style.bg_color = Color(0.05, 0.1, 0.19, 0.95)
	style.border_color = Color(UpgradeIcon.color_of(p.id), 0.5)
	style.set_content_margin_all(16)
	style.shadow_size = 0
	style.set_corner_radius_all(22)
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var icon := UpgradeIcon.new()
	icon.id = p.id
	icon.icon_size = 84.0
	row.add_child(icon)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text)
	text.add_child(_label(p.title, 26, UpgradeIcon.color_of(p.id).lightened(0.3)))
	text.add_child(_label(_change_text(p.id, lvl, lvl >= max_lvl), 21, Color(0.55, 1.0, 0.8)))
	var pips := ""
	for i in max_lvl:
		pips += "●" if i < lvl else "○"
	text.add_child(_label(pips, 20, Color(1, 0.85, 0.4)))

	var buy := Button.new()
	buy.focus_mode = Control.FOCUS_NONE
	buy.custom_minimum_size = Vector2(124, 88)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if cost < 0:
		buy.text = "Макс."
		buy.disabled = true
	else:
		buy.text = str(cost)
		buy.icon = SHELL
		buy.expand_icon = false
		buy.theme_type_variation = &"PrimaryButton"
		buy.disabled = SaveData.shells < cost
	buy.pressed.connect(_buy.bind(p.id))
	row.add_child(buy)
	return card


func _label(t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	if not SaveData.buy(id):
		return
	Sound.play("levelup", -4.0)
	_rebuild()
	UiFx.bump(_shells, 1.3)
	# Купленная строка вспыхивает.
	var index := SaveData.PERKS.map(func(p): return p.id).find(id)
	var rows := _rows.get_children().filter(func(c): return not c.is_queued_for_deletion())
	if index >= 0 and index < rows.size():
		var row := rows[index] as Control
		await get_tree().process_frame
		row.pivot_offset = row.size / 2.0
		row.modulate = Color(1.8, 1.6, 1.2)
		var tw := row.create_tween().set_ignore_time_scale().set_parallel()
		tw.tween_property(row, "modulate", Color.WHITE, 0.5)
		row.scale = Vector2(1.05, 1.05)
		tw.tween_property(row, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Окно появляется с анимацией каждый раз, когда его показывают.
func _on_visibility_changed() -> void:
	if visible:
		UiFx.pop_in($Card, $Dim)
		UiFx.stagger($Card/Box.get_children())
		$Card/Box/Scroll.scroll_vertical = 0

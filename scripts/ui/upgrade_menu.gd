class_name UpgradeMenu
extends CanvasLayer
## Выбор 1 из 3 улучшений. Карточки выезжают по очереди; выбранная вспыхивает, остальные гаснут.

signal chosen(id: String)

@onready var _dim: ColorRect = $Dim
@onready var _title: Label = $Box/Title
@onready var _choices: HBoxContainer = $Box/Choices

var _picking := false


func show_choices(choices: Array, taken := {}, player: Player = null) -> void:
	_picking = false
	for child in _choices.get_children():
		child.queue_free()
	for i in choices.size():
		_choices.add_child(_make_card(choices[i], taken.get(choices[i].id, 0), player))
	show()
	_dim.modulate.a = 0.0
	create_tween().set_ignore_time_scale().tween_property(_dim, "modulate:a", 1.0, 0.2)
	UiFx.bump(_title, 1.15)
	var cards := _choices.get_children().filter(func(b): return not b.is_queued_for_deletion())
	UiFx.stagger([_title] + cards, 0.09, 0.0)


func _make_card(upgrade: Dictionary, level: int, player: Player) -> Button:
	var color := UpgradeIcon.color_of(upgrade.id)
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 550)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_NONE
	card.clip_contents = false
	for state in ["normal", "hover", "pressed"]:
		card.add_theme_stylebox_override(state, _card_style(color, state == "pressed"))

	# Цветная «шапка» карточки: мягкое свечение за значком.
	var halo := TextureRect.new()
	halo.texture = UpgradeIcon.GLOW
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	halo.offset_left = -30
	halo.offset_right = 30
	halo.offset_top = -10
	halo.offset_bottom = 300
	halo.modulate = Color(color, 0.28)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(halo)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 12
	col.offset_right = -12
	col.offset_top = 22
	col.offset_bottom = -22
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)

	var badge := Label.new()
	badge.text = "НОВОЕ" if level == 0 else "УР. %d" % (level + 1)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 20)
	badge.add_theme_color_override("font_color", Color(1, 0.88, 0.45) if level == 0 else Color(1, 1, 1, 0.6))
	col.add_child(badge)

	var icon := UpgradeIcon.new()
	icon.id = upgrade.id
	icon.icon_size = 168.0
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)

	var title := Label.new()
	title.text = upgrade.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(0, 74)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", color.lightened(0.45))
	col.add_child(title)

	# «Урон: 1 → 2» делим на подпись и крупные числа.
	var parts := Upgrades.describe(upgrade.id, level, player).split(": ", true, 1)
	var stat := Label.new()
	stat.text = parts[0]
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	stat.custom_minimum_size = Vector2(0, 56)
	stat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stat.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stat.add_theme_font_size_override("font_size", 21)
	stat.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	col.add_child(stat)

	var value := Label.new()
	value.text = parts[1] if parts.size() > 1 else ""
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.clip_text = false
	# Длинные числа («100% → 160%») уменьшаем, чтобы не вылезали за карточку.
	var font: Font = ThemeDB.get_project_theme().default_font
	if font == null:
		font = ThemeDB.fallback_font
	var fs := 34
	while fs > 20 and font.get_string_size(value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 188.0:
		fs -= 2
	value.add_theme_font_size_override("font_size", fs)
	value.add_theme_color_override("font_color", Color(0.55, 1.0, 0.8))
	value.add_theme_constant_override("outline_size", 6)
	value.add_theme_color_override("font_outline_color", Color(0, 0.1, 0.12, 0.9))
	col.add_child(value)

	var pips := Pips.new()
	pips.level = level + 1
	pips.max_level = Upgrades.MAX_LEVEL
	pips.color = color.lightened(0.2)
	pips.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(pips)

	card.pressed.connect(_pick.bind(upgrade.id, card))
	return card


func _card_style(color: Color, pressed: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	var bg := UiTheme.tile_bg()
	sb.bg_color = Color(bg.lerp(color, 0.2 if pressed else 0.1), 0.97)
	sb.set_corner_radius_all(30)
	sb.corner_detail = 12
	sb.set_border_width_all(3)
	sb.border_width_bottom = 7
	sb.border_color = color.lightened(0.15) if pressed else Color(color, 0.85)
	sb.shadow_color = Color(color, 0.35)
	sb.shadow_size = 18
	sb.anti_aliasing_size = 1.5
	return sb


func _unhandled_input(event: InputEvent) -> void:
	# Клавиши 1-3 на ноутбуке.
	if not visible or not event is InputEventKey or not event.pressed:
		return
	var index: int = (event as InputEventKey).keycode - KEY_1
	var buttons := _choices.get_children().filter(func(b): return not b.is_queued_for_deletion())
	if index >= 0 and index < buttons.size():
		(buttons[index] as Button).pressed.emit()


func _pick(id: String, card: Button) -> void:
	if _picking:
		return
	_picking = true
	var tw := create_tween().set_ignore_time_scale().set_parallel()
	for other in _choices.get_children():
		if other != card:
			tw.tween_property(other, "modulate:a", 0.0, 0.15)
	card.pivot_offset = card.size / 2.0
	tw.tween_property(card, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "modulate", Color(1.6, 1.4, 1.0), 0.12)
	tw.chain().tween_property(_dim, "modulate:a", 0.0, 0.12)
	tw.tween_property(card, "modulate:a", 0.0, 0.12)
	await tw.finished
	hide()
	chosen.emit(id)

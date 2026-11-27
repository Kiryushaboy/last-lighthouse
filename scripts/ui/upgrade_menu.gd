class_name UpgradeMenu
extends CanvasLayer
## Выбор 1 из 3 улучшений. Карточки выезжают по очереди; выбранная вспыхивает, остальные гаснут.

signal chosen(id: String)

@onready var _dim: ColorRect = $Dim
@onready var _title: Label = $Box/Title
@onready var _choices: VBoxContainer = $Box/Choices

var _picking := false


func show_choices(choices: Array, taken := {}) -> void:
	_picking = false
	for child in _choices.get_children():
		child.queue_free()
	for i in choices.size():
		_choices.add_child(_make_card(choices[i], taken.get(choices[i].id, 0), i))
	show()
	_dim.modulate.a = 0.0
	create_tween().set_ignore_time_scale().tween_property(_dim, "modulate:a", 1.0, 0.2)
	UiFx.bump(_title, 1.15)
	var cards := _choices.get_children().filter(func(b): return not b.is_queued_for_deletion())
	UiFx.stagger([_title] + cards, 0.09, 0.0)


func _make_card(upgrade: Dictionary, level: int, index: int) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 170)
	card.focus_mode = Control.FOCUS_NONE
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 20
	row.offset_right = -20
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var icon := UpgradeIcon.new()
	icon.id = upgrade.id
	row.add_child(icon)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)

	var title := Label.new()
	title.text = upgrade.title
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", UpgradeIcon.color_of(upgrade.id).lightened(0.3))
	text.add_child(title)

	var desc := Label.new()
	desc.text = upgrade.desc
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 26)
	desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	text.add_child(desc)

	# Уровень улучшения: закрашенные точки — сколько уже взято, светится новая.
	var pips := Label.new()
	var s := ""
	for i in Upgrades.MAX_LEVEL:
		s += "●" if i <= level else "○"
	pips.text = s + ("  НОВОЕ" if level == 0 else "")
	pips.add_theme_font_size_override("font_size", 22)
	pips.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	text.add_child(pips)

	var key := Label.new()
	key.text = str(index + 1)
	key.add_theme_font_size_override("font_size", 22)
	key.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	key.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(key)

	card.pressed.connect(_pick.bind(upgrade.id, card))
	return card


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

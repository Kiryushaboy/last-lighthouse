class_name UpgradeMenu
extends CanvasLayer
## Выбор 1 из 3 улучшений. Карточки выезжают по очереди; выбранная вспыхивает, остальные гаснут.

signal chosen(id: String)

@onready var _dim: ColorRect = $Dim
@onready var _title: Label = $Box/Title
@onready var _choices: VBoxContainer = $Box/Choices

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
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 200)
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

	# Что делает вообще — и что именно изменится сейчас, в цифрах.
	var what := Label.new()
	what.text = upgrade.what
	what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	what.add_theme_font_size_override("font_size", 23)
	what.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	text.add_child(what)

	var change := Label.new()
	change.text = Upgrades.describe(upgrade.id, level, player)
	change.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	change.add_theme_font_size_override("font_size", 27)
	change.add_theme_color_override("font_color", Color(0.55, 1.0, 0.8))
	text.add_child(change)

	# Уровень улучшения: закрашенные точки — сколько уже взято, светится новая.
	var pips := Label.new()
	var s := ""
	for i in Upgrades.MAX_LEVEL:
		s += "●" if i <= level else "○"
	pips.text = s + ("  НОВОЕ" if level == 0 else "  уровень %d из %d" % [level + 1, Upgrades.MAX_LEVEL])
	pips.add_theme_font_size_override("font_size", 22)
	pips.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	text.add_child(pips)

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

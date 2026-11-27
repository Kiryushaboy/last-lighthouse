class_name HeroesPanel
extends CanvasLayer
## Выбор героя: карточки из Heroes.LIST, покупка за ракушки и выбор того, кем играть.

signal closed

const SHELL := preload("res://art/sprites/seashell.svg")
const HERO_TEXTURE := preload("res://art/sprites/player.svg")
const GLOW := preload("res://art/fx/glow.tres")
const WEAPON_TEXT := {"harpoon": "Оружие: гарпуны", "lightning": "Оружие: цепная молния", "aura": "Оружие: огненный круг"}

@onready var _shells: Label = $Card/Box/Shells
@onready var _rows: VBoxContainer = $Card/Box/Scroll/Rows
@onready var _back: Button = $Card/Box/Back


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_back.pressed.connect(close)


func open() -> void:
	_rebuild()
	show()


func close() -> void:
	hide()
	closed.emit()


func _rebuild() -> void:
	_shells.text = "Ракушки: %d" % SaveData.shells
	for child in _rows.get_children():
		child.queue_free()
	for h in Heroes.LIST:
		_rows.add_child(_make_row(h))
	UiFx.touch_scroll($Card/Box/Scroll)


func _make_row(h: Dictionary) -> Control:
	var owned: bool = h.id in SaveData.heroes
	var chosen: bool = SaveData.hero == h.id
	var neon: Color = h.neon

	var card := PanelContainer.new()
	var style := ($Card.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	style.bg_color = Color(0.05, 0.1, 0.19, 0.95) if not chosen else Color(0.08, 0.14, 0.24, 0.98)
	style.border_color = Color(neon, 0.95 if chosen else 0.4)
	style.set_border_width_all(4 if chosen else 2)
	style.set_content_margin_all(16)
	style.shadow_size = 0
	style.set_corner_radius_all(22)
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	# Портрет: свечение цвета героя и окрашенный спрайт.
	var portrait := Control.new()
	portrait.custom_minimum_size = Vector2(110, 110)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(portrait)
	var glow := TextureRect.new()
	glow.texture = GLOW
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.modulate = Color(neon, 0.45 if owned else 0.15)
	portrait.add_child(glow)
	var sprite := TextureRect.new()
	sprite.texture = HERO_TEXTURE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.offset_left = -14; sprite.offset_top = -14; sprite.offset_right = 14; sprite.offset_bottom = 14
	var tint: Color = h.tint
	sprite.modulate = tint if owned else Color(0.25, 0.28, 0.35)
	portrait.add_child(sprite)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text)
	text.add_child(_label(h.title, 28, neon.lightened(0.35)))
	text.add_child(_label(WEAPON_TEXT.get(h.weapon, ""), 20, Color(0.55, 1.0, 0.8)))
	text.add_child(_label(h.desc, 19, Color(1, 1, 1, 0.75)))
	text.add_child(_label("Сердец: %d" % h.hp, 19, Color(1.0, 0.5, 0.6)))

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(140, 88)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if chosen:
		btn.text = "Выбран"
		btn.disabled = true
	elif owned:
		btn.text = "Выбрать"
		btn.theme_type_variation = &"PrimaryButton"
	else:
		btn.text = str(h.cost)
		btn.icon = SHELL
		btn.expand_icon = false
		btn.theme_type_variation = &"PrimaryButton"
		btn.disabled = SaveData.shells < h.cost
	btn.pressed.connect(_choose.bind(h.id))
	row.add_child(btn)
	return card


func _label(t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _choose(id: String) -> void:
	if not UiFx.tap_ok($Card/Box/Scroll):
		return
	var bought: bool = not id in SaveData.heroes
	if not SaveData.choose_hero(id, Heroes.get_hero(id).cost):
		return
	Sound.play("levelup" if bought else "shell", -4.0)
	_rebuild()
	UiFx.bump(_shells, 1.3)
	var index := Heroes.LIST.map(func(h): return h.id).find(id)
	await get_tree().process_frame
	var rows := _rows.get_children().filter(func(c): return not c.is_queued_for_deletion())
	if index >= 0 and index < rows.size():
		var row := rows[index] as Control
		row.pivot_offset = row.size / 2.0
		row.modulate = Color(1.8, 1.6, 1.2)
		var tw := row.create_tween().set_ignore_time_scale().set_parallel()
		tw.tween_property(row, "modulate", Color.WHITE, 0.5)
		row.scale = Vector2(1.05, 1.05)
		tw.tween_property(row, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_visibility_changed() -> void:
	if visible:
		UiFx.pop_in($Card, $Dim)
		UiFx.stagger($Card/Box.get_children())
		$Card/Box/Scroll.scroll_vertical = 0

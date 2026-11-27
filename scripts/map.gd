extends Control
## Карта «Маяки побережья»: список ночей кампании со звёздами. Нажали на ночь — она начинается.

const GAME_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"

@onready var _list: VBoxContainer = $Margin/Box/Scroll/List
@onready var _scroll: ScrollContainer = $Margin/Box/Scroll
@onready var _total: Label = $Margin/Box/Total


func _ready() -> void:
	get_tree().paused = false
	Sound.play_music("menu")
	$Margin/Box/Back.pressed.connect(_back)
	_total.text = "★ %d из %d     Ракушки: %d" % [SaveData.total_stars(), Nights.count() * 3, SaveData.shells]
	var focus: Control = null
	for i in Nights.count():
		var card := _make_card(i)
		_list.add_child(card)
		if focus == null and Nights.is_unlocked(i) and SaveData.stars_of(i) < 3:
			focus = card
	_list.add_child(_make_endless_card())
	UiFx.stagger(_list.get_children(), 0.04, 0.05)
	if focus:
		await get_tree().process_frame
		await get_tree().process_frame
		_scroll.scroll_vertical = int(maxf(0.0, focus.position.y - 200.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back()


func _back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)


func _make_card(i: int) -> Control:
	var n := Nights.get_night(i)
	var unlocked := Nights.is_unlocked(i)
	var stars := SaveData.stars_of(i)

	# Карточки чуть смещаются влево-вправо — получается тропинка вдоль берега.
	var holder := MarginContainer.new()
	var shift: int = [0, 40, 70, 40, 0, -30][i % 6] + 30
	holder.add_theme_constant_override("margin_left", shift)
	holder.add_theme_constant_override("margin_right", 100 - shift)

	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 150)
	card.focus_mode = Control.FOCUS_NONE
	card.disabled = not unlocked
	holder.add_child(card)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_right = -18
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var badge := NightBadge.new()
	badge.number = i + 1
	badge.unlocked = unlocked
	badge.boss = n.has("boss_at")
	badge.done = stars > 0
	row.add_child(badge)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text)
	text.add_child(_label(n.title, 30, Color(1, 0.88, 0.55) if unlocked else Color(1, 1, 1, 0.35)))
	if unlocked:
		var sub := []
		if n.has("boss_at"):
			sub.append("Спрут!")
		var mod: String = n.get("modifier", "")
		if mod != "":
			sub.append(Nights.MODIFIER_TEXT[mod].split(":")[0])
		sub.append("%d:%02d" % [int(n.time) / 60, int(n.time) % 60])
		text.add_child(_label(" · ".join(sub), 22, Color(0.6, 0.9, 1)))
		text.add_child(_label("★★★: " + Nights.task_text(n.task), 20, Color(1, 1, 1, 0.6)))
	else:
		text.add_child(_label("Откроется после ночи %d" % i, 22, Color(1, 1, 1, 0.35)))

	if unlocked:
		var sv := StarsView.new()
		sv.star_size = 13.0
		sv.set_stars([stars >= 1, stars >= 2, stars >= 3])
		sv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sv)
	card.pressed.connect(_start.bind(i))
	return holder


## Бесконечная ночь в конце карты: награда за кампанию, показывает рекорд.
func _make_endless_card() -> Control:
	var unlocked := Nights.endless_unlocked()
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 160)
	card.focus_mode = Control.FOCUS_NONE
	card.disabled = not unlocked
	if unlocked:
		card.theme_type_variation = &"PrimaryButton"
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var dark := Color(0.2, 0.1, 0.02)
	var t := _label("∞  Бесконечная ночь", 34, dark if unlocked else Color(1, 1, 1, 0.35))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var sub := ""
	if unlocked:
		var b := int(SaveData.best_time)
		sub = "Рекорд: %d:%02d · врагов %d" % [b / 60, b % 60, SaveData.best_kills] if b > 0 else "Сколько продержитесь?"
	else:
		sub = "Откроется после 12-й ночи"
	var s := _label(sub, 22, dark if unlocked else Color(1, 1, 1, 0.35))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(s)
	card.pressed.connect(_start.bind(Nights.ENDLESS))
	return card


func _label(t: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _start(i: int) -> void:
	SaveData.current_night = i
	get_tree().change_scene_to_file(GAME_SCENE)

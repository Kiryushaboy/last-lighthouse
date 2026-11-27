class_name MapPath
extends Control
## Рисунок главы на карте: тропа из шести островков-маяков, наверху логово босса,
## вокруг плавают обитатели этой главы. Нажатие на островок — выбор ночи.

signal night_selected(index: int)

const LIGHTHOUSE := preload("res://art/sprites/lighthouse.svg")
const GLOW := preload("res://art/fx/glow.tres")
## Где стоят островки: доли ширины и высоты области (снизу вверх).
const SPOTS := [Vector2(0.24, 0.9), Vector2(0.7, 0.78), Vector2(0.3, 0.62), Vector2(0.74, 0.48), Vector2(0.3, 0.33), Vector2(0.56, 0.14)]
const NODE_R := 46.0

var chapter := 0
var selected := -1  ## номер ночи в кампании или -1
var _t := 0.0
var _boss_tex: Texture2D
var _critters: Array = []  ## [текстура, доля x, доля y, размер, фаза]


func set_chapter(c: int) -> void:
	chapter = c
	var ch: Dictionary = Nights.CHAPTERS[c]
	_boss_tex = load(Boss.KINDS[ch.boss].texture)
	# Кто живёт в главе: берём врагов из её ночей и расставляем по краям тропы.
	var names := {}
	for i in Nights.NIGHTS_PER_CHAPTER:
		for e in Nights.get_night(c * Nights.NIGHTS_PER_CHAPTER + i).enemies:
			names[e[0]] = true
	_critters.clear()
	var places := [Vector2(0.86, 0.92), Vector2(0.1, 0.74), Vector2(0.9, 0.62), Vector2(0.08, 0.48), Vector2(0.9, 0.34), Vector2(0.12, 0.2), Vector2(0.5, 0.7), Vector2(0.52, 0.4)]
	var k := 0
	for n in names:
		if k >= places.size():
			break
		_critters.append([load("res://art/sprites/%s.svg" % n), places[k].x, places[k].y, 62.0 + (k % 3) * 10.0, k * 1.7])
		k += 1
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func spot(i: int) -> Vector2:
	return Vector2(SPOTS[i].x * size.x, SPOTS[i].y * size.y)


func _gui_input(event: InputEvent) -> void:
	var pos := Vector2.INF
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	if pos == Vector2.INF:
		return
	for i in SPOTS.size():
		var r := NODE_R * (1.5 if i == 5 else 1.25)
		if pos.distance_to(spot(i)) <= r:
			night_selected.emit(chapter * Nights.NIGHTS_PER_CHAPTER + i)
			accept_event()
			return


func _draw() -> void:
	var th: Dictionary = Nights.CHAPTERS[chapter].theme
	var rim: Color = th.rim
	# Обитатели главы покачиваются на волнах.
	for c in _critters:
		var s: float = c[3]
		var at := Vector2(c[1] * size.x, c[2] * size.y) + Vector2(sin(_t * 0.7 + c[4]) * 8.0, cos(_t * 0.9 + c[4]) * 6.0)
		draw_texture_rect(GLOW, Rect2(at - Vector2(s, s), Vector2(s, s) * 2.0), false, Color(rim, 0.12))
		draw_texture_rect(c[0], Rect2(at - Vector2(s, s) / 2.0, Vector2(s, s)), false, Color(1, 1, 1, 0.75))
	# Тропа: пунктир между островками, пройденная часть светится.
	for i in SPOTS.size() - 1:
		var a := spot(i)
		var b := spot(i + 1)
		var night := chapter * Nights.NIGHTS_PER_CHAPTER + i
		var open := SaveData.stars_of(night) > 0
		var steps := int(a.distance_to(b) / 26.0)
		for j in range(1, steps):
			var p := a.lerp(b, float(j) / steps)
			p += (b - a).orthogonal().normalized() * sin(float(j) / steps * PI) * 18.0
			var pulse := 0.6 + 0.4 * sin(_t * 3.0 - j * 0.5) if open else 0.5
			draw_circle(p, 5.0, Color(1.0, 0.85, 0.45, 0.85 * pulse) if open else Color(1, 1, 1, 0.14))
	for i in SPOTS.size():
		_draw_node(i, th)


func _draw_node(i: int, th: Dictionary) -> void:
	var night := chapter * Nights.NIGHTS_PER_CHAPTER + i
	var at := spot(i)
	var unlocked := Nights.is_unlocked(night)
	var stars := SaveData.stars_of(night)
	var is_boss := i == 5
	var r := NODE_R * (1.35 if is_boss else 1.0)
	var rim: Color = th.rim
	var current := unlocked and stars == 0
	if night == selected:
		draw_arc(at, r + 14.0 + sin(_t * 5.0) * 2.0, 0.0, TAU, 48, Color(1, 0.9, 0.5), 5.0)
	if current:
		var p := 0.5 + 0.5 * sin(_t * 3.0)
		draw_texture_rect(GLOW, Rect2(at - Vector2(r, r) * 2.2, Vector2(r, r) * 4.4), false, Color(1, 0.8, 0.4, 0.25 + 0.3 * p))
	# Островок.
	draw_circle(at + Vector2(0, 5), r + 3.0, Color(0, 0, 0, 0.35))
	draw_circle(at, r, (th.island as Color) if unlocked else (th.island as Color).darkened(0.4))
	draw_circle(at + Vector2(0, -4), r - 10.0, (th.island_top as Color) if unlocked else (th.island_top as Color).darkened(0.4))
	draw_arc(at, r, 0.0, TAU, 48, Color(rim, 0.9 if unlocked else 0.2), 4.0)
	if is_boss:
		# Логово босса: сам босс на островке, красная кромка.
		var s := r * 2.3
		var bob := sin(_t * 2.0) * 4.0
		draw_arc(at, r + 6.0, 0.0, TAU, 48, Color(1, 0.35, 0.35, 0.9 if unlocked else 0.25), 4.0)
		draw_texture_rect(_boss_tex, Rect2(at - Vector2(s, s) / 2.0 + Vector2(0, bob - 6.0), Vector2(s, s)), false,
				Color.WHITE if unlocked else Color(0.12, 0.12, 0.18, 0.9))
	else:
		var s := r * 1.5
		draw_texture_rect(LIGHTHOUSE, Rect2(at - Vector2(s, s) / 2.0 + Vector2(0, -8), Vector2(s, s)), false,
				Color.WHITE if unlocked else Color(0.2, 0.22, 0.3))
		if unlocked:
			draw_texture_rect(GLOW, Rect2(at - Vector2(34, 54), Vector2(68, 68)), false, Color(1, 0.85, 0.45, 0.5 + 0.2 * sin(_t * 2.0 + i)))
	# Номер ночи в кружке слева сверху.
	var font := get_theme_font("font", "Label")
	var num := str(night + 1)
	var badge := at + Vector2(-r * 0.8, -r * 0.8)
	draw_circle(badge, 19.0, Color(0.03, 0.06, 0.12))
	draw_arc(badge, 19.0, 0.0, TAU, 24, Color(1, 0.8, 0.4, 1.0 if unlocked else 0.3), 3.0)
	var w := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(font, badge + Vector2(-w / 2.0, 8), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.88, 0.55, 1.0 if unlocked else 0.4))
	if not unlocked:
		# Замочек.
		var l := at + Vector2(r * 0.55, r * 0.5)
		draw_rect(Rect2(l - Vector2(13, 4), Vector2(26, 20)), Color(0.65, 0.7, 0.8))
		draw_arc(l - Vector2(0, 4), 8.0, PI, TAU, 10, Color(0.65, 0.7, 0.8), 4.0)
		return
	# Звёзды под островком.
	for k in 3:
		var sp := at + Vector2((k - 1) * 26.0, r + 20.0 - (4.0 if k == 1 else 0.0))
		draw_colored_polygon(StarsView._star(sp, 12.0), Color(1, 0.82, 0.3) if stars > k else Color(0, 0, 0, 0.45))

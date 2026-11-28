extends Control
## Заставка при запуске: ночное море, маяк с вращающимися лучами, звёзды и название.
## Всё рисуется кодом и подстраивается под любой экран. Плавно проявляется и гаснет, затем меню.

const NEXT_SCENE := "res://scenes/menu.tscn"
const FADE_IN := 0.7
const HOLD := 3.0
const FADE_OUT := 0.7
const TITLE_FONT := preload("res://ui/fonts/RussoOne-Regular.ttf")
const GLOW := preload("res://art/fx/glow.tres")

const SKY_TOP := Color(0.01, 0.02, 0.07)
const SKY_MID := Color(0.05, 0.08, 0.24)
const SKY_LOW := Color(0.32, 0.16, 0.42)
const SEA_TOP := Color(0.05, 0.16, 0.3)
const SEA_LOW := Color(0.0, 0.02, 0.06)
const GOLD := Color(1.0, 0.86, 0.45)

var _t := 0.0
var _stars: Array[Vector3] = []  ## x, y (доли экрана), фаза мерцания
var _sparks: Array[Vector3] = []
var _title_k := 0.0  ## 0..1, появление названия
var _sub_k := 0.0
var _shine := -0.3  ## блик, пробегающий по названию


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 110:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.56, rng.randf() * TAU))
	for i in 26:
		_sparks.append(Vector3(rng.randf(), rng.randf(), rng.randf() * TAU))
	RenderingServer.set_default_clear_color(Color.BLACK)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, FADE_IN).set_trans(Tween.TRANS_SINE)
	# Меню грузим в фоне, когда картинка уже проявилась: загрузка не дёргает появление.
	tw.tween_callback(func(): ResourceLoader.load_threaded_request(NEXT_SCENE))
	tw.tween_interval(HOLD)
	tw.tween_property(self, "modulate:a", 0.0, FADE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_go)
	var tt := create_tween()
	tt.tween_interval(0.45)
	tt.tween_property(self, "_title_k", 1.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tt.parallel().tween_property(self, "_sub_k", 1.0, 0.8).set_delay(0.5)
	tt.tween_property(self, "_shine", 1.3, 1.1).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _go() -> void:
	var scene := ResourceLoader.load_threaded_get(NEXT_SCENE) as PackedScene
	get_tree().change_scene_to_packed(scene)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var horizon := h * 0.62
	var u := minf(w / 720.0, h / 1280.0)  # масштаб рисунка
	var base := Vector2(w * 0.5, horizon + 6.0 * u)  # подножие маяка
	var lamp := base + Vector2(0, -372.0 * u)

	# Небо: три полосы градиента, у горизонта сиреневое зарево.
	_gradient(Rect2(0, 0, w, horizon * 0.55), SKY_TOP, SKY_MID)
	_gradient(Rect2(0, horizon * 0.55, w, horizon * 0.45 + 1.0), SKY_MID, SKY_LOW)
	for s in _stars:
		var tw := 0.45 + 0.55 * sin(_t * 2.0 + s.z)
		var r := (1.0 + 1.6 * fposmod(s.z, 1.0)) * u
		draw_circle(Vector2(s.x * w, s.y * h), r, Color(1, 1, 1, 0.25 + 0.6 * tw), true, -1.0, true)
	# Луна за маяком.
	var moon := Vector2(w * 0.76, h * 0.17)
	_glow(moon, 210.0 * u, Color(0.7, 0.8, 1.0, 0.35))
	draw_circle(moon, 46.0 * u, Color(0.95, 0.97, 1.0), true, -1.0, true)
	draw_circle(moon + Vector2(-14, -8) * u, 9.0 * u, Color(0.8, 0.85, 0.95), true, -1.0, true)
	draw_circle(moon + Vector2(12, 14) * u, 6.0 * u, Color(0.8, 0.85, 0.95), true, -1.0, true)

	# Лучи маяка: два широких луча медленно вращаются, за ними идёт мягкий ореол.
	var a := _t * 0.55 - 0.5
	var squash := Vector2(1.0, 0.42)  # вращение «в глубину»
	for i in 2:
		var ang := a + PI * i
		var d1 := Vector2.RIGHT.rotated(ang - 0.16) * squash
		var d2 := Vector2.RIGHT.rotated(ang + 0.16) * squash
		var far := maxf(w, h) * 1.3
		var front := 0.55 + 0.45 * sin(ang)  # ближний к зрителю луч ярче
		draw_polygon(PackedVector2Array([lamp, lamp + d1 * far, lamp + d2 * far]),
				PackedColorArray([Color(1.0, 0.93, 0.6, 0.75 * front + 0.1), Color(1.0, 0.9, 0.55, 0.0), Color(1.0, 0.9, 0.55, 0.0)]))
	_glow(lamp, 330.0 * u, Color(1.0, 0.85, 0.45, 0.55))

	# Море с бегущими волнами и лунной дорожкой.
	_gradient(Rect2(0, horizon, w, h - horizon), SEA_TOP, SEA_LOW)
	_glow(Vector2(w * 0.5, horizon), 420.0 * u, Color(1.0, 0.6, 0.75, 0.22))
	for i in 9:
		var k := i / 8.0
		var y := horizon + (h - horizon) * (0.04 + 0.9 * k * k)
		var amp := (3.0 + 12.0 * k) * u
		var pts := PackedVector2Array()
		var n := 28
		for j in n + 1:
			var x := w * j / n
			pts.append(Vector2(x, y + sin(x * 0.012 / u * (1.6 - k) + _t * (1.4 - 0.6 * k) + i * 1.7) * amp))
		draw_polyline(pts, Color(0.45, 0.85, 1.0, 0.1 + 0.22 * k), (2.0 + 4.0 * k) * u, true)
		# Отблеск фонаря на воде.
		var gl := 0.5 + 0.5 * sin(_t * 3.0 + i * 2.3)
		var gw := (26.0 + 110.0 * k) * u
		draw_line(Vector2(w * 0.5 - gw, y), Vector2(w * 0.5 + gw, y), Color(1.0, 0.88, 0.5, (0.5 - 0.3 * k) * (0.5 + 0.5 * gl)), (3.0 + 4.0 * k) * u, true)

	_draw_lighthouse(base, u)

	# Светлячки-искры плывут вверх.
	for s in _sparks:
		var yy := fposmod(s.y - _t * 0.03 * (0.5 + fposmod(s.z, 1.0)), 1.0)
		var pos := Vector2(s.x * w + sin(_t + s.z) * 14.0 * u, yy * h)
		draw_circle(pos, 2.4 * u, Color(1.0, 0.9, 0.6, 0.35 + 0.35 * sin(_t * 2.0 + s.z)), true, -1.0, true)

	_draw_title(Vector2(w * 0.5, horizon + (h - horizon) * 0.42), u)
	# Мягкое затемнение по краям.
	_gradient(Rect2(0, 0, w, h * 0.12), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0.0))
	_gradient(Rect2(0, h * 0.86, w, h * 0.14), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.6))


func _draw_lighthouse(base: Vector2, u: float) -> void:
	# Скала.
	var rock := PackedVector2Array()
	for p in [Vector2(-190, 14), Vector2(-150, -18), Vector2(-96, -30), Vector2(-60, -52), Vector2(60, -52), Vector2(104, -28), Vector2(160, -16), Vector2(200, 14)]:
		rock.append(base + p * u)
	draw_colored_polygon(rock, Color(0.04, 0.05, 0.1))
	draw_polyline(rock, Color(0.4, 0.85, 1.0, 0.55), 3.0 * u, true)
	# Башня: белые и красные полосы, сужается кверху.
	var bottom := -50.0
	var top := -340.0
	var bands := 5
	for i in bands:
		var y0 := lerpf(bottom, top, float(i) / bands)
		var y1 := lerpf(bottom, top, float(i + 1) / bands)
		var w0 := lerpf(58.0, 36.0, float(i) / bands)
		var w1 := lerpf(58.0, 36.0, float(i + 1) / bands)
		var col := Color(0.95, 0.96, 1.0) if i % 2 == 0 else Color(0.95, 0.3, 0.36)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-w0, y0) * u, base + Vector2(w0, y0) * u,
				base + Vector2(w1, y1) * u, base + Vector2(-w1, y1) * u]), col)
		# Тень справа придаёт объём.
		draw_colored_polygon(PackedVector2Array([base + Vector2(w0 * 0.35, y0) * u, base + Vector2(w0, y0) * u,
				base + Vector2(w1, y1) * u, base + Vector2(w1 * 0.35, y1) * u]), Color(0.05, 0.05, 0.25, 0.28))
	draw_polyline(PackedVector2Array([base + Vector2(-58, bottom) * u, base + Vector2(-36, top) * u,
			base + Vector2(36, top) * u, base + Vector2(58, bottom) * u]), Color(0.45, 0.9, 1.0), 3.5 * u, true)
	# Дверь и окно.
	draw_rect(Rect2(base + Vector2(-13, bottom - 44) * u, Vector2(26, 44) * u), Color(0.12, 0.14, 0.26))
	draw_circle(base + Vector2(0, -200) * u, 10.0 * u, Color(1.0, 0.85, 0.45), true, -1.0, true)
	# Балкон, фонарь и крыша.
	draw_rect(Rect2(base + Vector2(-50, top - 10) * u, Vector2(100, 12) * u), Color(0.1, 0.12, 0.24))
	draw_rect(Rect2(base + Vector2(-28, top - 62) * u, Vector2(56, 54) * u), Color(0.1, 0.12, 0.24))
	var pulse := 0.85 + 0.15 * sin(_t * 5.0)
	draw_rect(Rect2(base + Vector2(-20, top - 56) * u, Vector2(40, 42) * u), Color(1.0, 0.95, 0.7) * Color(pulse, pulse, pulse, 1.0))
	draw_rect(Rect2(base + Vector2(-28, top - 62) * u, Vector2(56, 54) * u), GOLD, false, 3.0 * u)
	draw_colored_polygon(PackedVector2Array([base + Vector2(-38, top - 62) * u, base + Vector2(38, top - 62) * u,
			base + Vector2(0, top - 104) * u]), Color(0.95, 0.3, 0.36))
	draw_circle(base + Vector2(0, top - 108) * u, 5.0 * u, GOLD, true, -1.0, true)
	_glow(base + Vector2(0, top - 34) * u, 90.0 * u, Color(1.0, 0.95, 0.7, 0.9))


func _draw_title(center: Vector2, u: float) -> void:
	if _title_k <= 0.0:
		return
	var k := _title_k
	var lines := ["ПОСЛЕДНИЙ", "МАЯК"]
	var sizes := [int(92 * u), int(132 * u)]
	var y := center.y - 70.0 * u
	_glow(center, 380.0 * u * k, Color(1.0, 0.7, 0.3, 0.3 * k))
	for i in 2:
		var fs: int = maxi(8, int(sizes[i] * (0.6 + 0.4 * k)))
		var text: String = lines[i]
		var tw := TITLE_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(center.x - tw / 2.0, y + (1.0 - k) * 40.0 * u)
		var alpha := clampf(k, 0.0, 1.0)
		draw_string_outline(TITLE_FONT, pos + Vector2(0, 6) * u, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(22 * u), Color(0.9, 0.45, 0.1, 0.35 * alpha))
		draw_string_outline(TITLE_FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(12 * u), Color(0.02, 0.03, 0.1, alpha))
		draw_string(TITLE_FONT, pos + Vector2(0, 5) * u, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.85, 0.5, 0.15, alpha))
		draw_string(TITLE_FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(GOLD, alpha))
		# Блик пробегает по буквам слева направо.
		var sx := pos.x + tw * _shine
		if _shine > 0.0 and _shine < 1.0:
			_glow(Vector2(sx, pos.y - fs * 0.35), fs * 0.9, Color(1, 1, 1, 0.55))
		y += 124.0 * u
	if _sub_k > 0.0:
		var sub := "Продержитесь до рассвета"
		var font := ThemeDB.get_project_theme().default_font
		var fs2 := int(34 * u)
		var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		var p := Vector2(center.x - sw / 2.0, y - 10.0 * u)
		draw_string_outline(font, p, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, int(8 * u), Color(0.02, 0.03, 0.1, _sub_k))
		draw_string(font, p, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(0.8, 0.92, 1.0, _sub_k))


func _gradient(r: Rect2, top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
			PackedColorArray([top, top, bottom, bottom]))


func _glow(at: Vector2, radius: float, c: Color) -> void:
	draw_texture_rect(GLOW, Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, c)

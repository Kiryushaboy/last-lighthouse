extends Node2D
## Арена: ночное море (шейдер), песчаный остров, маяк со светящимся фонарём, граница в тумане.

const RECT := Rect2(-900, -900, 1800, 1800)
const ISLAND_RADIUS := 300.0
const GLOW := preload("res://art/fx/glow.tres")
const WATER_SHADER := preload("res://shaders/water.gdshader")

var _rocks: Array[Vector3] = []  ## x, y, радиус
var theme: Dictionary  ## цвета главы (Nights.CHAPTERS[].theme)


func _ready() -> void:
	theme = Nights.theme_of(SaveData.current_night)
	RenderingServer.set_default_clear_color(theme.bg)
	# Море — отдельный прямоугольник под всем остальным, рисуется шейдером.
	var water := Polygon2D.new()
	water.polygon = PackedVector2Array([RECT.position, Vector2(RECT.end.x, RECT.position.y),
			RECT.end, Vector2(RECT.position.x, RECT.end.y)])
	water.show_behind_parent = true
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("arena_half", RECT.size / 2.0)
	mat.set_shader_parameter("island_radius", ISLAND_RADIUS)
	mat.set_shader_parameter("deep", theme.deep)
	mat.set_shader_parameter("shallow", theme.shallow)
	mat.set_shader_parameter("foam", theme.foam)
	water.material = mat
	add_child(water)
	# Камни на острове: одни и те же каждую ночь.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 14:
		var a := rng.randf() * TAU
		var dist := rng.randf_range(ISLAND_RADIUS * 0.45, ISLAND_RADIUS * 0.9)
		_rocks.append(Vector3(cos(a) * dist, sin(a) * dist, rng.randf_range(8.0, 22.0)))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# Мокрый песок, сухой песок, лёгкая тень по краю.
	# Ночной остров: тёмный камень с бирюзовой светящейся кромкой.
	draw_circle(Vector2.ZERO, ISLAND_RADIUS, theme.island)
	draw_circle(Vector2(0, -8), ISLAND_RADIUS - 24.0, theme.island_top)
	var rim := 0.75 + 0.25 * sin(t * 1.5)
	draw_arc(Vector2.ZERO, ISLAND_RADIUS, 0.0, TAU, 96, Color(theme.rim, 0.85 * rim), 4.0)
	draw_arc(Vector2.ZERO, ISLAND_RADIUS + 6.0, 0.0, TAU, 96, Color(theme.rim, 0.2 * rim), 10.0)
	# Тёплый свет маяка на камнях вокруг башни.
	draw_texture_rect(GLOW, Rect2(-ISLAND_RADIUS, -ISLAND_RADIUS, ISLAND_RADIUS * 2, ISLAND_RADIUS * 2), false, Color(1.0, 0.75, 0.4, 0.12))
	for r in _rocks:
		draw_circle(Vector2(r.x, r.y), r.z, theme.rock)
		draw_arc(Vector2(r.x, r.y), r.z, PI * 1.0, PI * 1.6, 10, Color(theme.rim, 0.35), 2.0)
	# Тень маяка и сам маяк.
	# Маяк сверху: тёмная башня, золотые неоновые кольца, яркий фонарь.
	var pulse := 0.8 + 0.2 * sin(t * 2.0)
	draw_circle(Vector2.ZERO, 54.0, Color(0.06, 0.07, 0.11))
	draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 48, Color(1.0, 0.78, 0.4, 0.9), 4.0)
	draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 48, Color(1.0, 0.78, 0.4, 0.35), 2.0)
	for i in 8:
		var a := TAU * i / 8.0 + t * 0.2
		draw_line(Vector2.RIGHT.rotated(a) * 40.0, Vector2.RIGHT.rotated(a) * 54.0, Color(1.0, 0.78, 0.4, 0.5), 2.0)
	draw_circle(Vector2.ZERO, 22.0 * pulse, Color(1.0, 0.92, 0.7))
	var g := 160.0 * pulse
	draw_texture_rect(GLOW, Rect2(-g, -g, g * 2.0, g * 2.0), false, Color(1.0, 0.85, 0.45, 0.35 * pulse))
	# Граница арены: светящиеся буйки вместо линии.
	for i in 36:
		var k := i / 36.0
		var p := _perimeter_point(k)
		var blink := 0.5 + 0.5 * sin(t * 3.0 + i * 1.7)
		draw_texture_rect(GLOW, Rect2(p - Vector2(22, 22), Vector2(44, 44)), false, Color(1.0, 0.35, 0.3, 0.25 + 0.35 * blink))
		draw_circle(p, 6.0, Color(1.0, 0.45, 0.35, 0.6 + 0.4 * blink))


func _perimeter_point(k: float) -> Vector2:
	var per := k * 4.0
	var side := int(per)
	var f := per - side
	var a := RECT.position
	var b := RECT.end
	match side:
		0: return Vector2(lerpf(a.x, b.x, f), a.y)
		1: return Vector2(b.x, lerpf(a.y, b.y, f))
		2: return Vector2(lerpf(b.x, a.x, f), b.y)
		_: return Vector2(a.x, lerpf(b.y, a.y, f))

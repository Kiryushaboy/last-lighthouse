extends Node2D
## Арена: ночное море (шейдер), песчаный остров, маяк со светящимся фонарём, граница в тумане.

const RECT := Rect2(-900, -900, 1800, 1800)
const ISLAND_RADIUS := 300.0
const LIGHTHOUSE := preload("res://art/sprites/lighthouse.svg")
const GLOW := preload("res://art/fx/glow.tres")
const WATER_SHADER := preload("res://shaders/water.gdshader")

var _rocks: Array[Vector3] = []  ## x, y, радиус


func _ready() -> void:
	# Море — отдельный прямоугольник под всем остальным, рисуется шейдером.
	var water := Polygon2D.new()
	water.polygon = PackedVector2Array([RECT.position, Vector2(RECT.end.x, RECT.position.y),
			RECT.end, Vector2(RECT.position.x, RECT.end.y)])
	water.show_behind_parent = true
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("arena_half", RECT.size / 2.0)
	mat.set_shader_parameter("island_radius", ISLAND_RADIUS)
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
	draw_circle(Vector2.ZERO, ISLAND_RADIUS, Color(0.55, 0.47, 0.34))
	draw_circle(Vector2.ZERO, ISLAND_RADIUS - 14.0, Color(0.78, 0.67, 0.47))
	draw_circle(Vector2(0, -10), ISLAND_RADIUS - 40.0, Color(0.85, 0.75, 0.54))
	for r in _rocks:
		draw_circle(Vector2(r.x + 4, r.y + 6), r.z, Color(0, 0, 0, 0.18))
		draw_circle(Vector2(r.x, r.y), r.z, Color(0.42, 0.42, 0.46))
		draw_circle(Vector2(r.x - r.z * 0.3, r.y - r.z * 0.3), r.z * 0.45, Color(0.55, 0.55, 0.6))
	# Тень маяка и сам маяк.
	var size := LIGHTHOUSE.get_size() * 0.5
	draw_circle(Vector2(10, 14), size.x * 0.48, Color(0, 0, 0, 0.25))
	draw_texture_rect(LIGHTHOUSE, Rect2(-size / 2.0, size), false)
	# Фонарь маяка мягко пульсирует.
	var pulse := 0.8 + 0.2 * sin(t * 2.0)
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

extends Node2D
## Рисует арену: море, волны, песчаный остров и маяк в центре.

const RECT := Rect2(-900, -900, 1800, 1800)
const ISLAND_RADIUS := 300.0
const LIGHTHOUSE := preload("res://art/sprites/lighthouse.svg")

var _waves: Array[Vector2] = []


func _ready() -> void:
	# Расставляем волны один раз, со своим зерном — каждую ночь одинаково.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 140:
		var p := Vector2(rng.randf_range(RECT.position.x, RECT.end.x), rng.randf_range(RECT.position.y, RECT.end.y))
		if p.length() > ISLAND_RADIUS + 40.0:
			_waves.append(p)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(RECT, Color(0.07, 0.17, 0.26))
	var t := Time.get_ticks_msec() / 1000.0
	for i in _waves.size():
		var p := _waves[i] + Vector2(sin(t * 0.6 + i) * 10.0, 0)
		draw_arc(p, 18.0, PI * 1.15, PI * 1.85, 8, Color(0.6, 0.85, 1.0, 0.12), 3.0)
	# Отмель и песок.
	draw_circle(Vector2.ZERO, ISLAND_RADIUS + 40.0, Color(0.12, 0.3, 0.38))
	draw_circle(Vector2.ZERO, ISLAND_RADIUS, Color(0.82, 0.72, 0.5))
	draw_circle(Vector2.ZERO, ISLAND_RADIUS - 30.0, Color(0.88, 0.79, 0.57))
	draw_rect(RECT, Color(0.5, 0.7, 0.9, 0.5), false, 6.0)
	var size := LIGHTHOUSE.get_size() * 0.5
	draw_texture_rect(LIGHTHOUSE, Rect2(-size / 2.0, size), false)

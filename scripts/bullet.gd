class_name Bullet
extends Area2D
## Снаряд: летит прямо, бьёт первого врага (или нескольких, если есть пробивание).

var direction := Vector2.RIGHT
var speed := 720.0
var damage := 1
var pierce := 0
var lifetime := 1.0

const TEXTURE := preload("res://art/sprites/harpoon.svg")
const GLOW := preload("res://art/fx/glow.tres")

var _spent := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent or not area is Enemy:
		return
	(area as Enemy).hit(damage)
	Fx.burst(global_position, Color(1.0, 0.9, 0.6), 4, 200.0, 3.0)
	if pierce > 0:
		pierce -= 1
	else:
		_spent = true
		queue_free()


func _draw() -> void:
	# След: светлая полоса позади гарпуна (узел повёрнут по направлению полёта).
	var trail := PackedVector2Array([Vector2(-70, 0), Vector2(-6, -3.5), Vector2(-6, 3.5)])
	draw_colored_polygon(trail, Color(1.0, 0.9, 0.6, 0.35))
	draw_texture_rect(GLOW, Rect2(-22, -22, 44, 44), false, Color(1.0, 0.85, 0.5, 0.5))
	var size := TEXTURE.get_size() / Enemy.SVG_SCALE * 0.5
	draw_texture_rect(TEXTURE, Rect2(-size / 2.0, size), false)

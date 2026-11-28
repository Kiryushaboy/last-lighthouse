class_name Ink
extends Area2D
## Клякса чернил кальмара. Ранит игрока при попадании.

const TEXTURE := preload("res://art/sprites/ink.svg")
const GLOW := preload("res://art/fx/glow.tres")

var direction := Vector2.RIGHT
var speed := 280.0
var lifetime := 3.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage(1)
		Fx.burst(global_position, Color(0.5, 0.25, 0.8), 10, 220.0, 6.0)
		queue_free()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 90.0
	var wob := Vector2(1.0 + sin(t) * 0.12, 1.0 - sin(t) * 0.12)
	draw_texture_rect(GLOW, Rect2(-34, -34, 68, 68), false, Color(0.6, 0.3, 0.9, 0.45))
	draw_set_transform(Vector2.ZERO, direction.angle(), wob)
	var size := TEXTURE.get_size() / Enemy.SVG_SCALE * 0.6
	draw_texture_rect(TEXTURE, Rect2(-size / 2.0, size), false)

class_name Ink
extends Area2D
## Клякса чернил кальмара. Ранит игрока при попадании.

const TEXTURE := preload("res://art/sprites/ink.svg")

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
		queue_free()


func _draw() -> void:
	var size := TEXTURE.get_size() * 0.6
	draw_texture_rect(TEXTURE, Rect2(-size / 2.0, size), false)

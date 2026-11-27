class_name XpGem
extends Node2D
## Подбираемый предмет: кристалл опыта или ракушка.
## Лежит, пока игрок не подойдёт, потом летит к нему.

signal collected(value: int)

var value := 1
var is_shell := false  ## ракушка для мастерской вместо опыта
var player: Player

var _magnet := false


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist < player.pickup_radius:
		_magnet = true
	if _magnet:
		global_position = global_position.move_toward(player.global_position, 650.0 * delta)
		if dist < 22.0:
			collected.emit(value)
			queue_free()


func _draw() -> void:
	if is_shell:
		draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.75, 0.8))
		draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 16, Color(0.8, 0.45, 0.55), 2.0)
		return
	draw_colored_polygon(
		PackedVector2Array([Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)]),
		Color(0.4, 1.0, 0.6)
	)

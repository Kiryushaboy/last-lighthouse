class_name XpGem
extends Node2D
## Кристалл опыта. Лежит, пока игрок не подойдёт, потом летит к нему.

signal collected(value: int)

var value := 1
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
	draw_colored_polygon(
		PackedVector2Array([Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)]),
		Color(0.4, 1.0, 0.6)
	)

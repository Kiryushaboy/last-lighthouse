class_name Leech
extends Enemy
## Пиявка: маленькая и быстрая, извивается на ходу.

var _wave := randf() * TAU


func _move(delta: float, current_speed: float) -> void:
	_wave += delta * 9.0
	var dir := global_position.direction_to(target.global_position)
	global_position += (dir + dir.orthogonal() * sin(_wave) * 0.5).normalized() * current_speed * delta
	_body.rotation = dir.angle() + PI / 2.0 + sin(_wave) * 0.3

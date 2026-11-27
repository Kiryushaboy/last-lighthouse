class_name Eel
extends Enemy
## Электрический угорь: быстрый, плывёт зигзагом — попасть по нему труднее.

var _wave := randf() * TAU


func _move(delta: float, current_speed: float) -> void:
	_wave += delta * 5.0
	var dir := global_position.direction_to(target.global_position)
	var side := dir.orthogonal() * sin(_wave) * 0.9
	global_position += (dir + side).normalized() * current_speed * delta
	_body.rotation = (dir + side).angle() + PI / 2.0

class_name Wisp
extends Enemy
## Штормовой огонёк: не летит прямо, а закручивается вокруг героя по спирали.

var _side := 1.0 if randf() < 0.5 else -1.0


func _move(delta: float, current_speed: float) -> void:
	var dir := global_position.direction_to(target.global_position)
	var dist := global_position.distance_to(target.global_position)
	# Далеко — летит почти прямо, вблизи — кружит и сжимает кольцо.
	var swirl := clampf(1.6 - dist / 500.0, 0.3, 1.4)
	global_position += (dir + dir.orthogonal() * _side * swirl).normalized() * current_speed * delta
	_body.rotation += delta * 6.0 * _side

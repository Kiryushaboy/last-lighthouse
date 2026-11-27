class_name Angler
extends Enemy
## Удильщик: в темноте почти невидим, виден только огонёк. Проявляется рядом с игроком и в луче маяка.

const SEE_DISTANCE := 230.0

var _alpha := 0.15


func _move(delta: float, current_speed: float) -> void:
	super._move(delta, current_speed)
	var visible_now := in_beam() or global_position.distance_to(target.global_position) < SEE_DISTANCE or _flash > 0.0
	_alpha = move_toward(_alpha, 1.0 if visible_now else 0.15, delta * 3.0)
	_body.modulate.a = _alpha

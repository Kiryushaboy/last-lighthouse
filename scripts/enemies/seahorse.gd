class_name Seahorse
extends Enemy
## Морской конёк: плывёт рывками. Замирает, потом резко бросается вперёд.

const DASH := 0.45
const REST := 0.55

var _phase := randf() * (DASH + REST)


func _move(delta: float, current_speed: float) -> void:
	_phase = fmod(_phase + delta, DASH + REST)
	var dir := global_position.direction_to(target.global_position)
	var k := 2.4 if _phase < DASH else 0.15
	global_position += dir * current_speed * k * delta
	_body.rotation = dir.x * 0.25

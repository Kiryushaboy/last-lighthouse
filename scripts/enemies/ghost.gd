class_name Ghost
extends Enemy
## Призрак моряка: раз в несколько секунд исчезает и появляется ближе, с другой стороны.

const BLINK_EVERY := 3.2

var _blink := randf_range(1.5, BLINK_EVERY)


func _move(delta: float, current_speed: float) -> void:
	super._move(delta, current_speed)
	_body.modulate.a = 0.75 + 0.2 * sin(_age * 5.0)
	_blink -= delta
	# В луче маяка призрак «прибит» светом и прыгать не может.
	if _blink > 0.0 or in_beam():
		return
	_blink = BLINK_EVERY
	var dist := global_position.distance_to(target.global_position)
	if dist < 170.0:
		return
	Fx.ring(global_position, Color(color, 0.7), radius * 2.0, 0.3, 4.0)
	global_position = target.global_position + Vector2.RIGHT.rotated(randf() * TAU) * maxf(dist * 0.6, 170.0)
	_age = 0.0
	Fx.ring(global_position, Color(color, 0.7), radius * 2.4, 0.4, 4.0)

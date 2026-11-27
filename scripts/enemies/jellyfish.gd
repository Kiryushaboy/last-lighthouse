class_name Jellyfish
extends Enemy
## Медуза: быстрая и хрупкая, плывёт рывками — рывок, пауза, рывок.

const DASH_TIME := 0.6
const REST_TIME := 0.5

var _phase := 0.0


func _move(delta: float, current_speed: float) -> void:
	_phase = fmod(_phase + delta, DASH_TIME + REST_TIME)
	if _phase < DASH_TIME:
		super._move(delta, current_speed)


func _draw_body(c: Color) -> void:
	# Купол и щупальца.
	draw_circle(Vector2(0, -3), radius, c)
	for x in [-8.0, 0.0, 8.0]:
		draw_line(Vector2(x, 6), Vector2(x, 18), c, 3.0)

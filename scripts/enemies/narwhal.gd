class_name Narwhal
extends Enemy
## Нарвал: подплывает, замирает и целится (красная линия), потом таранит по прямой.

const AIM_TIME := 0.9
const DASH_TIME := 0.7
const DASH_SPEED := 620.0
const TRIGGER_DISTANCE := 380.0

var _state := 0  ## 0 — плывёт, 1 — целится, 2 — рывок
var _timer := 0.0
var _dash_dir := Vector2.RIGHT


func _move(delta: float, current_speed: float) -> void:
	var to_player := target.global_position - global_position
	match _state:
		0:
			global_position += to_player.normalized() * current_speed * delta
			_body.rotation = to_player.angle()
			if to_player.length() < TRIGGER_DISTANCE:
				_state = 1
				_timer = AIM_TIME
		1:
			_timer -= delta
			_dash_dir = to_player.normalized()
			_body.rotation = _dash_dir.angle()
			if _timer <= 0.0:
				_state = 2
				_timer = DASH_TIME
		2:
			_timer -= delta
			# В луче маяка рывок тоже замедляется.
			global_position += _dash_dir * DASH_SPEED * (current_speed / speed) * delta
			if _timer <= 0.0:
				_state = 0


func _draw() -> void:
	super._draw()
	if _state == 1:
		var k := 1.0 - _timer / AIM_TIME
		draw_line(Vector2.ZERO, _dash_dir * DASH_SPEED * DASH_TIME, Color(1, 0.3, 0.3, 0.25 + 0.5 * k), 3.0 + 3.0 * k)

class_name TouchJoystick
extends Control
## Плавающий джойстик: касание в нижней части экрана ставит центр,
## движение пальца задаёт направление. Мышь на ноутбуке работает так же,
## потому что в настройках включено «эмулировать касание мышью».

@export var base_radius := 110.0  ## радиус при чувствительности 1.0
@export var active_from := 0.3  ## доля высоты экрана, ниже которой ловим касания

var vector := Vector2.ZERO  ## от (-1,-1) до (1,1), читает Main

var _touch_index := -1
var _base := Vector2.ZERO
var _knob := Vector2.ZERO


## Чем выше чувствительность, тем меньше нужно отвести палец до полной скорости.
func radius() -> float:
	return base_radius / Settings.sensitivity


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1 and touch.position.y > size.y * active_from:
			_touch_index = touch.index
			_base = touch.position
			_knob = _base
		elif not touch.pressed and touch.index == _touch_index:
			reset()
		queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			var r := radius()
			var offset := (drag.position - _base).limit_length(r)
			_knob = _base + offset
			vector = offset / r
			queue_redraw()


func reset() -> void:
	_touch_index = -1
	vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if _touch_index == -1:
		return
	var r := radius()
	draw_circle(_base, r, Color(1, 1, 1, 0.08))
	draw_arc(_base, r, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 3.0)
	draw_circle(_knob, minf(44.0, r * 0.4), Color(1, 1, 1, 0.35))

class_name TouchJoystick
extends Control
## Плавающий джойстик: касание в нижней части экрана ставит центр,
## движение пальца задаёт направление. Мышь на ноутбуке работает так же,
## потому что в настройках включено «эмулировать касание мышью».

@export var radius := 80.0  ## на сколько пикселей отвести палец для полной скорости
@export var dead_zone := 0.08  ## мелкое дрожание пальца не двигает героя
@export var full_speed_at := 0.6  ## при 60% отклонения уже полная скорость
@export var active_from := 0.3  ## доля высоты экрана, ниже которой ловим касания

var vector := Vector2.ZERO  ## от (-1,-1) до (1,1), читает Main

var _touch_index := -1
var _base := Vector2.ZERO
var _knob := Vector2.ZERO


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
			var offset := drag.position - _base
			# Палец ушёл дальше радиуса: центр едет следом, чтобы
			# смена направления не требовала тянуть палец назад.
			if offset.length() > radius:
				_base = drag.position - offset.normalized() * radius
				offset = drag.position - _base
			_knob = _base + offset
			vector = _shape(offset / radius)
			queue_redraw()


## Кривая отклика: мёртвая зона в центре, полная скорость уже к full_speed_at.
func _shape(raw: Vector2) -> Vector2:
	var amount := raw.length()
	if amount < dead_zone:
		return Vector2.ZERO
	var t := clampf((amount - dead_zone) / (full_speed_at - dead_zone), 0.0, 1.0)
	return raw.normalized() * t


func reset() -> void:
	_touch_index = -1
	vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if _touch_index == -1:
		return
	draw_circle(_base, radius, Color(1, 1, 1, 0.08))
	draw_arc(_base, radius, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 3.0)
	draw_circle(_knob, 36.0, Color(1, 1, 1, 0.35))

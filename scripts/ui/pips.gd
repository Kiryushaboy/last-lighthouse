class_name Pips
extends Control
## Уровень в виде ряда огоньков: горящие — купленные уровни.

var level := 0
var max_level := 3
var color := Color(1, 0.85, 0.4)
var dot := 9.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(max_level * dot * 2.8, dot * 2.6)


func _draw() -> void:
	var step := dot * 2.8
	var x0 := size.x / 2.0 - step * (max_level - 1) / 2.0
	for i in max_level:
		var at := Vector2(x0 + i * step, size.y / 2.0)
		if i < level:
			draw_circle(at, dot + 3.0, Color(color, 0.25), true, -1.0, true)
			draw_circle(at, dot, color, true, -1.0, true)
			draw_circle(at + Vector2(-dot * 0.3, -dot * 0.3), dot * 0.3, Color(1, 1, 1, 0.7), true, -1.0, true)
		else:
			draw_circle(at, dot, Color(0, 0, 0, 0.45), true, -1.0, true)
			draw_circle(at, dot, Color(1, 1, 1, 0.25), false, 2.0, true)

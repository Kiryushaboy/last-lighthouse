extends Node2D
## Рисует пол арены: сетку, границу и маяк в центре.

const RECT := Rect2(-900, -900, 1800, 1800)
const CELL := 100.0


func _draw() -> void:
	draw_rect(RECT, Color(0.1, 0.13, 0.18))
	var line := Color(1, 1, 1, 0.05)
	var x := RECT.position.x
	while x <= RECT.end.x:
		draw_line(Vector2(x, RECT.position.y), Vector2(x, RECT.end.y), line, 2.0)
		x += CELL
	var y := RECT.position.y
	while y <= RECT.end.y:
		draw_line(Vector2(RECT.position.x, y), Vector2(RECT.end.x, y), line, 2.0)
		y += CELL
	draw_rect(RECT, Color(0.5, 0.7, 0.9, 0.5), false, 6.0)
	# Маяк в центре. Луч рисует Beam.
	draw_circle(Vector2.ZERO, 40.0, Color(0.85, 0.85, 0.8))
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.9, 0.5))

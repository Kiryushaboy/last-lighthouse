class_name Shell
extends Enemy
## Раковина: медленная, бронированная, перекрывает проходы. Каждое попадание слабее на armor.


func _draw_body(c: Color) -> void:
	draw_circle(Vector2.ZERO, radius, c)
	draw_arc(Vector2.ZERO, radius * 0.65, 0.0, TAU, 24, Color(0, 0, 0, 0.35), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.3, 0.0, TAU, 16, Color(0, 0, 0, 0.35), 3.0)

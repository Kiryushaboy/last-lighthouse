class_name Hearts
extends Control
## Жизни: сердце и число. При ударе сердце вздрагивает, при малом запасе колотится.

var hp := 5
var max_hp := 5
var _hit_t := 1.0  ## секунды с последнего урона
var _lost_index := -1
var _t := 0.0


func set_values(new_hp: int, new_max: int) -> void:
	if new_hp < hp:
		_hit_t = 0.0
		_lost_index = new_hp
	hp = maxi(new_hp, 0)
	max_hp = new_max


func _process(delta: float) -> void:
	_t += delta
	_hit_t += delta
	queue_redraw()


func _draw() -> void:
	# Одно сердце и рядом число оставшихся жизней.
	var at := Vector2(24, 22)
	var r := 20.0
	var s := 1.0
	if hp <= 2 and hp > 0:
		s = 1.0 + 0.14 * maxf(0.0, sin(_t * 8.0))  # сердце колотится, когда жизней мало
	if _hit_t < 0.35:
		s *= 1.0 + 0.5 * (1.0 - _hit_t / 0.35)  # вздрагивает от удара
	var col := Color(1, 0.3, 0.38) if hp > 0 else Color(1, 1, 1, 0.2)
	if _hit_t < 0.2:
		col = Color(1, 1, 1)
	_heart(at + Vector2(2, 3), r * s, Color(0, 0, 0, 0.4))
	_heart(at, r * s, col)
	_heart(at + Vector2(-r * 0.3, -r * 0.3), r * 0.3 * s, Color(1, 1, 1, 0.5))
	var font := get_theme_font("font", "Label")
	var text := str(hp)
	var fs := 38
	var pos := Vector2(52, 36)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(0, 0, 0, 0.6))
	var num_col := Color(1, 1, 1) if hp > 2 else Color(1, 0.45, 0.45)
	if _hit_t < 0.35:
		num_col = num_col.lerp(Color(1, 0.3, 0.35), 1.0 - _hit_t / 0.35)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, num_col)


func _heart(at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for j in 24:
		var t := TAU * j / 24.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(at + Vector2(x, y) * r / 16.0)
	draw_colored_polygon(pts, col)

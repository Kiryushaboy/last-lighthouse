class_name Hearts
extends Control
## Жизни сердечками. Потерянное сердце лопается, оставшиеся бьются, когда жизней мало.

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
	var r := 15.0
	var step := 40.0
	for i in max_hp:
		var at := Vector2(r + 4 + (i % 6) * step, r + 6 + (i / 6) * step)
		var full := i < hp
		var s := 1.0
		if full and hp <= 2:
			s = 1.0 + 0.12 * maxf(0.0, sin(_t * 8.0))  # сердце колотится
		if i == _lost_index and _hit_t < 0.35:
			var k := _hit_t / 0.35
			s = 1.0 + k * 0.8
			_heart(at, r * s, Color(1, 0.3, 0.35, 1.0 - k))
			continue
		_heart(at + Vector2(2, 3), r * s, Color(0, 0, 0, 0.4))
		_heart(at, r * s, Color(1, 0.3, 0.38) if full else Color(1, 1, 1, 0.15))
		if full:
			_heart(at + Vector2(-r * 0.3, -r * 0.3), r * 0.3 * s, Color(1, 1, 1, 0.5))


func _heart(at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for j in 24:
		var t := TAU * j / 24.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(at + Vector2(x, y) * r / 16.0)
	draw_colored_polygon(pts, col)

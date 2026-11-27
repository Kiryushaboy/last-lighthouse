class_name StarsView
extends Control
## Три звезды ночи. Полученные загораются по очереди с «бумом».

var filled: Array = [false, false, false]
var star_size := 34.0
var _pop := [1.0, 1.0, 1.0]


func _ready() -> void:
	custom_minimum_size = Vector2(star_size * 7.0, star_size * 2.4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_stars(flags: Array, animate := false) -> void:
	filled = [false, false, false]
	queue_redraw()
	if not animate:
		filled = flags.duplicate()
		return
	var tw := create_tween().set_ignore_time_scale()
	tw.tween_interval(0.35)
	for i in 3:
		if flags[i]:
			tw.tween_callback(_light.bind(i))
			tw.tween_method(_set_pop.bind(i), 1.6, 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.12)


func _set_pop(v: float, i: int) -> void:
	_pop[i] = v
	queue_redraw()


func _light(i: int) -> void:
	filled[i] = true
	Sound.play("xp", -2.0)


func _draw() -> void:
	var c := size / 2.0
	for i in 3:
		var at := c + Vector2((i - 1) * star_size * 2.2, -star_size * 0.25 if i == 1 else star_size * 0.1)
		var r: float = star_size * (1.15 if i == 1 else 1.0) * _pop[i]
		var col := Color(1, 0.82, 0.3) if filled[i] else Color(1, 1, 1, 0.12)
		if filled[i]:
			draw_texture_rect(preload("res://art/fx/glow.tres"), Rect2(at - Vector2(r, r) * 2.0, Vector2(r, r) * 4.0), false, Color(1, 0.8, 0.3, 0.45))
		draw_colored_polygon(_star(at, r), col)
		draw_polyline(_star(at, r) + PackedVector2Array([_star(at, r)[0]]), Color(col, 0.9) if filled[i] else Color(1, 1, 1, 0.25), 2.0)


static func _star(at: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var rr := r if k % 2 == 0 else r * 0.45
		pts.append(at + Vector2.UP.rotated(TAU * k / 10.0) * rr)
	return pts

class_name Beam
extends Node2D
## Луч маяка. Медленно вращается вокруг центра арены.
## Враги в луче замедляются и получают двойной урон — держитесь света.

@export var length := 1400.0
@export var half_width_deg := 15.0  ## половина ширины луча в градусах
@export var turn_speed_deg := 25.0  ## градусов в секунду, полный оборот ~14 с

const SLOW_FACTOR := 0.6
const DAMAGE_FACTOR := 2


func _ready() -> void:
	add_to_group("beam")


func _process(delta: float) -> void:
	rotation = wrapf(rotation + deg_to_rad(turn_speed_deg) * delta, -PI, PI)
	queue_redraw()


## Попадает ли точка (в мировых координатах) в луч.
func contains(world_point: Vector2) -> bool:
	var local := world_point - global_position
	if local.length() > length:
		return false
	return absf(angle_difference(rotation, local.angle())) <= deg_to_rad(half_width_deg)


func _draw() -> void:
	var half := deg_to_rad(half_width_deg)
	var points := PackedVector2Array([Vector2.ZERO])
	for i in 17:
		points.append(Vector2.RIGHT.rotated(lerpf(-half, half, i / 16.0)) * length)
	draw_colored_polygon(points, Color(1.0, 0.9, 0.5, 0.10))
	# Яркая середина луча.
	var core := PackedVector2Array([Vector2.ZERO])
	for i in 9:
		core.append(Vector2.RIGHT.rotated(lerpf(-half * 0.4, half * 0.4, i / 8.0)) * length)
	draw_colored_polygon(core, Color(1.0, 0.9, 0.5, 0.08))

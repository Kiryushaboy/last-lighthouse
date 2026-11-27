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
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


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
	# Свет складывается с тем, что под ним (материал ADD), поэтому выглядит как настоящий луч.
	var half := deg_to_rad(half_width_deg)
	_draw_cone(half, Color(1.0, 0.85, 0.5), 0.16)
	_draw_cone(half * 0.45, Color(1.0, 0.95, 0.75), 0.14)
	# Пылинки, медленно плывущие в свете.
	var t := Time.get_ticks_msec() / 1000.0
	for i in 40:
		var along := fmod(i * 97.0 + t * (20.0 + i % 7 * 6.0), length * 0.9) + 60.0
		var side := sin(i * 12.9898) * 0.8
		var p := Vector2.RIGHT.rotated(side * half) * along
		var a := 0.25 + 0.25 * sin(t * 2.0 + i)
		draw_circle(p, 2.0 + (i % 3), Color(1.0, 0.95, 0.8, a * (1.0 - along / length)))


## Конус от фонаря: яркий у основания, растворяется к концу, мягкие края.
func _draw_cone(half: float, c: Color, strength: float) -> void:
	const STEPS := 12
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	pts.append(Vector2.ZERO)
	cols.append(Color(c, strength * 2.0))
	for i in STEPS + 1:
		var k := float(i) / STEPS
		var edge := 1.0 - absf(k * 2.0 - 1.0)  # 0 на краях, 1 в середине
		pts.append(Vector2.RIGHT.rotated(lerpf(-half, half, k)) * length)
		cols.append(Color(c, strength * 0.15 * edge))
	# Середина длины — отдельное кольцо, чтобы свет гас плавно, а не линейно по треугольнику.
	var mid := PackedVector2Array()
	var mid_c := PackedColorArray()
	for i in STEPS + 1:
		var k := float(i) / STEPS
		var edge := 1.0 - absf(k * 2.0 - 1.0)
		mid.append(Vector2.RIGHT.rotated(lerpf(-half, half, k)) * length * 0.45)
		mid_c.append(Color(c, strength * edge * edge))
	# Ближняя часть: от фонаря до середины.
	for i in STEPS:
		draw_polygon(PackedVector2Array([pts[0], mid[i], mid[i + 1]]),
				PackedColorArray([cols[0], mid_c[i], mid_c[i + 1]]))
	# Дальняя часть: от середины до конца.
	for i in STEPS:
		draw_polygon(PackedVector2Array([mid[i], pts[i + 1], pts[i + 2], mid[i + 1]]),
				PackedColorArray([mid_c[i], cols[i + 1], cols[i + 2], mid_c[i + 1]]))

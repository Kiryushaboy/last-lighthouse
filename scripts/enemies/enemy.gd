class_name Enemy
extends Area2D
## Общая основа всех врагов: здоровье, урон при касании, луч маяка, смерть.
## Конкретный враг наследует этот скрипт и переопределяет _move() и _draw_body().

signal killed(at: Vector2, xp_value: int)

@export var speed := 90.0
@export var max_hp := 2
@export var contact_damage := 1
@export var xp_value := 1
@export var shell_chance := 0.05  ## шанс уронить ракушку
@export var armor := 0  ## вычитается из каждого попадания, но урон не меньше 1
@export var color := Color(0.9, 0.35, 0.3)
@export var radius := 16.0
@export var texture: Texture2D  ## картинка врага; без неё рисуется круг
@export var texture_scale := 1.0

var target: Node2D
var beam: Beam
var hp := 0

var _flash := 0.0
var _dead := false


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	_move(delta, speed * (Beam.SLOW_FACTOR if in_beam() else 1.0))

	for body in get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(contact_damage)

	if _flash > 0.0:
		_flash -= delta
	queue_redraw()


## По умолчанию идёт прямо на игрока.
func _move(delta: float, current_speed: float) -> void:
	global_position += global_position.direction_to(target.global_position) * current_speed * delta


func in_beam() -> bool:
	return is_instance_valid(beam) and beam.contains(global_position)


func hit(amount: int) -> void:
	if _dead:
		return
	var dmg := maxi(amount - armor, 1)
	if in_beam():
		dmg *= Beam.DAMAGE_FACTOR
	hp -= dmg
	_flash = 0.08
	if hp <= 0:
		_dead = true
		killed.emit(global_position, xp_value)
		queue_free()


func _draw() -> void:
	if texture:
		_draw_texture()
	else:
		_draw_body(Color.WHITE if _flash > 0.0 else color)
	if in_beam():
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 24, Color(1, 0.9, 0.5, 0.8), 2.0)


func _draw_body(c: Color) -> void:
	draw_circle(Vector2.ZERO, radius, c)


## Картинка по центру; при попадании поверх неё короткая белая вспышка.
func _draw_texture() -> void:
	var size := texture.get_size() * 0.5 * texture_scale
	draw_texture_rect(texture, Rect2(-size / 2.0, size), false)
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.6))

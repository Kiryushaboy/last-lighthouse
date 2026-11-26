class_name Crab
extends Area2D
## Краб: медленно идёт на игрока и бьёт при касании.

signal killed(at: Vector2, xp_value: int)

@export var speed := 90.0
@export var max_hp := 2
@export var contact_damage := 1
@export var xp_value := 1

var target: Node2D
var hp := 0

var _flash := 0.0  ## белая вспышка при попадании
var _dead := false


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	global_position += global_position.direction_to(target.global_position) * speed * delta

	# Касание игрока. Повторные удары гасит неуязвимость игрока.
	for body in get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(contact_damage)

	if _flash > 0.0:
		_flash -= delta
		queue_redraw()


func hit(amount: int) -> void:
	if _dead:
		return
	hp -= amount
	_flash = 0.08
	queue_redraw()
	if hp <= 0:
		_dead = true
		killed.emit(global_position, xp_value)
		queue_free()


func _draw() -> void:
	var color := Color.WHITE if _flash > 0.0 else Color(0.9, 0.35, 0.3)
	draw_circle(Vector2.ZERO, 16.0, color)

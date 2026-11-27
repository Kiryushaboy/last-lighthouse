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
var _squash := 0.0  ## 0..1, сплющивание после попадания
var _age := 0.0  ## для появления из воды
var _knock := Vector2.ZERO  ## отбрасывание от попадания


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	Fx.ring.call_deferred(global_position, Color(0.7, 0.9, 1.0, 0.7), radius * 2.2, 0.5, 4.0)  # всплеск


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	_age += delta
	_move(delta, speed * (Beam.SLOW_FACTOR if in_beam() else 1.0))
	global_position += _knock * delta
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
	_squash = maxf(_squash - delta * 6.0, 0.0)

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
	Sound.play("hit", -10.0)
	_flash = 0.08
	_squash = 1.0
	if is_instance_valid(target):
		_knock = target.global_position.direction_to(global_position) * 160.0 / sqrt(maxf(radius / 16.0, 1.0))
	Fx.text(global_position, str(dmg), Color(1, 0.85, 0.3) if dmg > amount else Color.WHITE, dmg > amount)
	Fx.burst(global_position, color, 3, 180.0, 4.0)
	if hp <= 0:
		_dead = true
		Sound.play("death", -6.0)
		_on_death_fx()
		killed.emit(global_position, xp_value)
		queue_free()


## Эффект гибели: брызги цвета врага и расходящееся кольцо. Босс переопределяет.
func _on_death_fx() -> void:
	Fx.burst(global_position, color, 14, 320.0, 6.0)
	Fx.ring(global_position, color.lightened(0.3), radius * 3.0, 0.4, 6.0)
	Fx.shake(0.08)


func _draw() -> void:
	# Появление: вырастает из воды за 0.25 с с лёгким перехлёстом.
	var grow := clampf(_age / 0.25, 0.0, 1.0)
	var pop := 1.0 + sin(grow * PI) * 0.15
	var sq := 1.0 + _squash * 0.25
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sq, 1.0 / sq) * grow * pop)
	# Тень под врагом даёт объём.
	draw_set_transform(Vector2(radius * 0.25, radius * 0.4), 0.0, Vector2(1.0, 0.6) * grow)
	draw_circle(Vector2.ZERO, radius * 0.95, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(sq, 1.0 / sq) * grow * pop)
	if texture:
		_draw_texture()
	else:
		_draw_body(Color.WHITE if _flash > 0.0 else color)
	draw_set_transform(Vector2.ZERO)
	if in_beam():
		var t := Time.get_ticks_msec() / 200.0
		draw_arc(Vector2.ZERO, radius + 5.0 + sin(t) * 1.5, 0.0, TAU, 28, Color(1, 0.9, 0.5, 0.7), 2.5)


func _draw_body(c: Color) -> void:
	draw_circle(Vector2.ZERO, radius, c)


## Картинка по центру; при попадании картинка на миг вспыхивает белым.
func _draw_texture() -> void:
	var size := texture.get_size() * 0.5 * texture_scale
	var mod := Color(4, 4, 4) if _flash > 0.0 else Color.WHITE
	draw_texture_rect(texture, Rect2(-size / 2.0, size), false, mod)

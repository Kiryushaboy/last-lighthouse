class_name Player
extends CharacterBody2D
## Смотритель маяка. Двигается по джойстику или клавиатуре
## и сам стреляет в ближайшего врага.

signal died
signal health_changed(hp: int, max_hp: int)

const GLOW := preload("res://art/fx/glow.tres")
const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const TEXTURE := preload("res://art/sprites/player.svg")

# Характеристики. Улучшения меняют их во время забега.
@export var speed := 260.0
@export var max_hp := 5
@export var fire_interval := 0.45 ## секунд между выстрелами
@export var damage := 1
@export var projectiles := 1  ## сколько снарядов за выстрел
@export var pierce := 0  ## сколько врагов снаряд пробивает насквозь
@export var pickup_radius := 90.0  ## с какого расстояния притягивается опыт
@export var shoot_range := 520.0
@export var crit_chance := 0.0  ## шанс двойного урона, из мастерской

var hp := 0
var joystick_vector := Vector2.ZERO  ## задаёт Main из виртуального джойстика
var arena_rect := Rect2(-900, -900, 1800, 1800)
var bullet_container: Node  ## куда добавлять снаряды, задаёт Main

var _recoil := 0.0
var _body: Node2D
var _facing := 0.0  ## куда смотрит: на цель при выстреле, иначе по ходу движения
var _aim_hold := 0.0
var _walk := 0.0
var _fire_cooldown := 0.0
var _invulnerable := 0.0  ## после удара пару мгновений неуязвим
var _shield_recharge := 0.0  ## 0 — щита нет; иначе секунд до восстановления
var _shield_timer := 0.0
var _shield_up := false


func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	_body = Node2D.new()
	_body.material = Enemy.neon_material(Color(1.0, 0.75, 0.3), 5.0)
	_body.draw.connect(_draw_sprite)
	add_child(_body)


func _physics_process(delta: float) -> void:
	# 1. Движение: джойстик важнее клавиатуры.
	var dir := joystick_vector
	if dir == Vector2.ZERO:
		dir = _keyboard_vector()
	velocity = dir.limit_length(1.0) * speed
	move_and_slide()
	position = position.clamp(arena_rect.position, arena_rect.end)

	# 2. Таймеры.
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_recoil = maxf(_recoil - delta * 8.0, 0.0)
	if _shield_recharge > 0.0 and not _shield_up:
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_shield_up = true
			Fx.ring(global_position, Color(0.4, 0.9, 1.0), 50.0, 0.3, 4.0)
	_walk += velocity.length() * delta * 0.05
	# Поворот: после выстрела полсекунды смотрит на цель, потом — куда идёт.
	_aim_hold -= delta
	if _aim_hold <= 0.0 and velocity.length() > 10.0:
		_facing = lerp_angle(_facing, velocity.angle(), minf(1.0, delta * 10.0))
	_fire_cooldown -= delta

	# 3. Автострельба.
	if _fire_cooldown <= 0.0:
		var target := _nearest_enemy()
		if target:
			_shoot_at(target)
			_fire_cooldown = fire_interval

	queue_redraw()


## Щит из улучшения: гасит один удар, потом восстанавливается за recharge секунд.
func set_shield(recharge: float) -> void:
	var first := _shield_recharge == 0.0
	_shield_recharge = recharge
	if first:
		_shield_up = true


func take_damage(amount: int) -> void:
	if _invulnerable > 0.0 or hp <= 0:
		return
	if _shield_up:
		_shield_up = false
		_shield_timer = _shield_recharge
		_invulnerable = 0.5
		Sound.play("slam", -8.0)
		Fx.ring(global_position, Color(0.4, 0.9, 1.0), 90.0, 0.35, 8.0)
		Fx.burst(global_position, Color(0.4, 0.9, 1.0), 16, 300.0, 5.0)
		Fx.shake(0.15)
		return
	hp -= amount
	_invulnerable = 0.7
	Sound.play("hurt")
	Fx.flash(Color(1, 0.1, 0.15, 0.45), 0.45)
	Fx.shake(0.4)
	Fx.hitstop(0.07)
	Fx.burst(global_position, Color(1, 0.35, 0.3), 12, 260.0, 5.0)
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


func _keyboard_vector() -> Vector2:
	var v := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	return v.limit_length(1.0)


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_dist := shoot_range * shoot_range
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_squared_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best


func _shoot_at(target: Node2D) -> void:
	Sound.play("shoot", -10.0)
	_recoil = 1.0
	var base_dir := global_position.direction_to(target.global_position)
	_facing = base_dir.angle()
	_aim_hold = 0.5
	var spread := deg_to_rad(12.0)
	for i in projectiles:
		# Несколько снарядов расходятся веером вокруг направления на цель.
		var offset := (i - (projectiles - 1) / 2.0) * spread
		var bullet := BULLET_SCENE.instantiate() as Bullet
		bullet.direction = base_dir.rotated(offset)
		bullet.damage = damage * (2 if randf() < crit_chance else 1)
		bullet.pierce = pierce
		bullet_container.add_child(bullet)
		bullet.global_position = global_position + base_dir * 28.0  # из ствола ружья


func _draw() -> void:
	# Фонарь смотрителя: тёплый круг света под ногами.
	draw_texture_rect(GLOW, Rect2(-120, -120, 240, 240), false, Color(1.0, 0.8, 0.45, 0.28))
	draw_arc(Vector2.ZERO, pickup_radius, 0.0, TAU, 48, Color(0.5, 1, 0.8, 0.06), 2.0)
	if _shield_up:
		var t := Time.get_ticks_msec() / 1000.0
		draw_circle(Vector2.ZERO, 40.0, Color(0.4, 0.9, 1.0, 0.1))
		draw_arc(Vector2.ZERO, 40.0 + sin(t * 4.0) * 1.5, 0.0, TAU, 40, Color(0.5, 0.95, 1.0, 0.8), 3.0)
	elif _shield_recharge > 0.0:
		# Щит заряжается: тонкая дуга показывает прогресс.
		var k := 1.0 - _shield_timer / _shield_recharge
		draw_arc(Vector2.ZERO, 40.0, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Color(0.5, 0.95, 1.0, 0.3), 2.0)
	var moving := velocity.length() > 10.0
	var bob := absf(sin(_walk)) * 4.0 if moving else 0.0
	var sq := 1.0 + _recoil * 0.08
	_body.position = Vector2(0, -bob)
	_body.rotation = _facing + (sin(_walk) * 0.08 if moving else 0.0)
	_body.scale = Vector2(sq, 1.0 / sq)
	_body.queue_redraw()


## Сам смотритель — на дочернем узле с золотым неоновым контуром. Мигает, пока неуязвим.
func _draw_sprite() -> void:
	var blink := _invulnerable > 0.0 and int(_invulnerable * 20.0) % 2 == 0
	var size := TEXTURE.get_size() * 0.6
	_body.draw_texture_rect(TEXTURE, Rect2(-size / 2.0, size), false, Color(1, 1, 1, 0.35 if blink else 1.0))

class_name Boss
extends Enemy
## Спрут из тумана. Приходит на 4:30, победа над ним — рассвет.
## Две атаки, обе с предупреждением, чтобы их можно было избежать:
## 1. Залп чернил по кругу (сначала спрут сжимается и мигает).
## 2. Удар щупальцем: красный круг под игроком, через 1,2 с — удар по кругу.

signal health_changed(hp: int, max_hp: int)

const INK_SCENE := preload("res://scenes/enemies/ink.tscn")

const BARRAGE_EVERY := 6.0
const BARRAGE_WARN := 0.8
const BARRAGE_COUNT := 14
const SLAM_EVERY := 4.5
const SLAM_WARN := 1.2
const SLAM_RADIUS := 110.0
const SLAM_DAMAGE := 2

var projectile_container: Node

var _barrage_timer := 3.0
var _barrage_warning := -1.0
var _slam_timer := 2.0
var _slam_warning := -1.0
var _slam_pos := Vector2.ZERO


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	health_changed.emit(hp, max_hp)


func _move(delta: float, current_speed: float) -> void:
	super._move(delta, current_speed)
	_update_barrage(delta)
	_update_slam(delta)


func hit(amount: int) -> void:
	super.hit(amount)
	health_changed.emit(maxi(hp, 0), max_hp)


func _update_barrage(delta: float) -> void:
	if _barrage_warning >= 0.0:
		_barrage_warning += delta
		if _barrage_warning >= BARRAGE_WARN:
			_barrage_warning = -1.0
			_fire_barrage()
		return
	_barrage_timer -= delta
	if _barrage_timer <= 0.0:
		_barrage_timer = BARRAGE_EVERY
		_barrage_warning = 0.0


func _fire_barrage() -> void:
	if not projectile_container:
		return
	var offset := randf() * TAU
	for i in BARRAGE_COUNT:
		var ink := INK_SCENE.instantiate() as Ink
		ink.direction = Vector2.RIGHT.rotated(offset + TAU * i / BARRAGE_COUNT)
		ink.speed = 220.0
		projectile_container.add_child(ink)
		ink.global_position = global_position


func _update_slam(delta: float) -> void:
	if _slam_warning >= 0.0:
		_slam_warning += delta
		if _slam_warning >= SLAM_WARN:
			_slam_warning = -1.0
			if target.global_position.distance_to(_slam_pos) <= SLAM_RADIUS:
				(target as Player).take_damage(SLAM_DAMAGE)
		return
	_slam_timer -= delta
	if _slam_timer <= 0.0:
		_slam_timer = SLAM_EVERY
		_slam_warning = 0.0
		_slam_pos = target.global_position


func _draw_texture() -> void:
	var k := 1.0
	if _barrage_warning >= 0.0:
		k = 0.85 + 0.15 * sin(_barrage_warning * 30.0)
	var size := texture.get_size() * 0.5 * texture_scale * k
	var tint := Color(0.8, 0.6, 1.0) if _barrage_warning >= 0.0 else Color.WHITE
	draw_texture_rect(texture, Rect2(-size / 2.0, size), false, tint)
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.4))
	_draw_slam_warning()


func _draw_body(c: Color) -> void:
	# Во время подготовки залпа спрут сжимается и мигает.
	var r := radius
	if _barrage_warning >= 0.0:
		r *= 0.85 + 0.15 * sin(_barrage_warning * 30.0)
		c = c.lerp(Color(0.55, 0.3, 0.75), 0.6)
	draw_circle(Vector2.ZERO, r, c)
	for i in 8:
		var a := TAU * i / 8.0 + sin(Time.get_ticks_msec() / 300.0 + i) * 0.2
		draw_line(Vector2.RIGHT.rotated(a) * r * 0.8, Vector2.RIGHT.rotated(a) * r * 1.6, c, 10.0)
	draw_circle(Vector2(-18, -10), 8.0, Color.BLACK)
	draw_circle(Vector2(18, -10), 8.0, Color.BLACK)

	_draw_slam_warning()


## Предупреждение об ударе щупальцем рисуем в точке на полу.
func _draw_slam_warning() -> void:
	if _slam_warning >= 0.0:
		var local := to_local(_slam_pos)
		var k := _slam_warning / SLAM_WARN
		draw_circle(local, SLAM_RADIUS, Color(1, 0.2, 0.2, 0.12 + 0.2 * k))
		draw_arc(local, SLAM_RADIUS * k, 0.0, TAU, 48, Color(1, 0.3, 0.3, 0.9), 4.0)
		draw_arc(local, SLAM_RADIUS, 0.0, TAU, 48, Color(1, 0.3, 0.3, 0.9), 3.0)

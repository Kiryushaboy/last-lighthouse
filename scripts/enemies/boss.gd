class_name Boss
extends Enemy
## Босс главы. Приходит на 4:30 последней ночи главы, победа над ним — рассвет.
## Атаки, все с предупреждением, чтобы их можно было избежать:
## 1. Залп чернил по кругу (сначала босс сжимается и мигает).
## 2. Удар: красный круг под игроком, через 1,2 с — удар по кругу.
## 3. У некоторых — призыв подмоги (сигнал summon, врагов создаёт main.gd).

signal health_changed(hp: int, max_hp: int)
signal summon(enemy_type: String, count: int)

const INK_SCENE := preload("res://scenes/enemies/ink.tscn")

## Боссы по главам. hp — базовое, дальше умножается на сложность ночи.
const KINDS := {
	"crab_king": {"title": "Краб-король", "subtitle": "Хозяин старого причала", "texture": "res://art/sprites/boss_crab.svg",
		"color": Color(0.95, 0.35, 0.25), "hp": 260, "speed": 62.0, "barrage_count": 10, "barrage_every": 7.0,
		"slam_every": 4.0, "slam_radius": 120.0, "summon": "crab", "summon_count": 5, "summon_every": 9.0},
	"octopus": {"title": "Спрут из тумана", "subtitle": "Поднимается из глубин", "texture": "res://art/sprites/boss.svg",
		"color": Color(0.8, 0.25, 0.45), "hp": 300, "speed": 55.0, "barrage_count": 14, "barrage_every": 6.0,
		"slam_every": 4.5, "slam_radius": 110.0, "summon": "", "summon_count": 0, "summon_every": 0.0},
	"serpent": {"title": "Морской змей", "subtitle": "Приходит вместе с бурей", "texture": "res://art/sprites/boss_serpent.svg",
		"color": Color(0.2, 0.8, 0.6), "hp": 340, "speed": 95.0, "barrage_count": 12, "barrage_every": 5.0,
		"slam_every": 5.5, "slam_radius": 100.0, "summon": "eel", "summon_count": 4, "summon_every": 10.0},
	"whale": {"title": "Ледяной кит", "subtitle": "Лёд трещит под его спиной", "texture": "res://art/sprites/boss_whale.svg",
		"color": Color(0.55, 0.8, 0.95), "hp": 460, "speed": 42.0, "barrage_count": 20, "barrage_every": 6.5,
		"slam_every": 3.2, "slam_radius": 150.0, "summon": "narwhal", "summon_count": 2, "summon_every": 12.0},
	"kraken": {"title": "Кракен", "subtitle": "Хозяин бездны", "texture": "res://art/sprites/boss_kraken.svg",
		"color": Color(0.6, 0.35, 1.0), "hp": 520, "speed": 60.0, "barrage_count": 18, "barrage_every": 4.5,
		"slam_every": 3.0, "slam_radius": 125.0, "summon": "angler", "summon_count": 4, "summon_every": 9.0},
}

const BARRAGE_WARN := 0.8
const SLAM_WARN := 1.2
const SLAM_DAMAGE := 2

var kind := "octopus"
var title := ""
var subtitle := ""
var barrage_every := 6.0
var barrage_count := 14
var slam_every := 4.5
var slam_radius := 110.0
var summon_type := ""
var summon_count := 0
var summon_every := 0.0

var projectile_container: Node

var _barrage_timer := 3.0
var _barrage_warning := -1.0
var _slam_timer := 2.0
var _slam_warning := -1.0
var _slam_pos := Vector2.ZERO
var _summon_timer := 5.0


## Вызвать до добавления в дерево: задаёт вид и характеристики босса главы.
func setup(boss_kind: String) -> void:
	kind = boss_kind if KINDS.has(boss_kind) else "octopus"
	var k: Dictionary = KINDS[kind]
	title = k.title
	subtitle = k.subtitle
	texture = load(k.texture)
	color = k.color
	max_hp = k.hp
	speed = k.speed
	barrage_count = k.barrage_count
	barrage_every = k.barrage_every
	slam_every = k.slam_every
	slam_radius = k.slam_radius
	summon_type = k.summon
	summon_count = k.summon_count
	summon_every = k.summon_every


func _ready() -> void:
	if title == "":
		setup(kind)
	super._ready()
	add_to_group("boss")
	health_changed.emit(hp, max_hp)


func _move(delta: float, current_speed: float) -> void:
	super._move(delta, current_speed)
	_update_barrage(delta)
	_update_slam(delta)
	if summon_every > 0.0:
		_summon_timer -= delta
		if _summon_timer <= 0.0:
			_summon_timer = summon_every
			Fx.ring(global_position, color.lightened(0.3), radius * 3.0, 0.5, 8.0)
			summon.emit(summon_type, summon_count)


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
		_barrage_timer = barrage_every
		_barrage_warning = 0.0


func _fire_barrage() -> void:
	if not projectile_container:
		return
	Fx.ring(global_position, color.lightened(0.2), radius * 2.5, 0.4, 8.0)
	Fx.shake(0.2)
	var offset := randf() * TAU
	for i in barrage_count:
		var ink := INK_SCENE.instantiate() as Ink
		ink.direction = Vector2.RIGHT.rotated(offset + TAU * i / barrage_count)
		ink.speed = 220.0
		projectile_container.add_child(ink)
		ink.global_position = global_position


func _update_slam(delta: float) -> void:
	if _slam_warning >= 0.0:
		_slam_warning += delta
		if _slam_warning >= SLAM_WARN:
			_slam_warning = -1.0
			Sound.play("slam")
			Fx.shake(0.55)
			Fx.ring(_slam_pos, Color(1, 0.4, 0.35), slam_radius * 1.3, 0.45, 12.0)
			Fx.burst(_slam_pos, Color(0.6, 0.85, 1.0), 26, 420.0, 6.0)
			if target.global_position.distance_to(_slam_pos) <= slam_radius:
				(target as Player).take_damage(SLAM_DAMAGE)
		return
	_slam_timer -= delta
	if _slam_timer <= 0.0:
		_slam_timer = slam_every
		_slam_warning = 0.0
		_slam_pos = target.global_position
		Sound.play("warning", -4.0)


func _draw_texture() -> void:
	var k := 1.0
	if _barrage_warning >= 0.0:
		k = 0.85 + 0.15 * sin(_barrage_warning * 30.0)
	var size := texture.get_size() * 0.5 * texture_scale * k
	var tint := Color(1.25, 1.1, 1.4) if _barrage_warning >= 0.0 else Color.WHITE
	if _flash > 0.0:
		tint = Color(2.5, 2.5, 2.5)
	_body.draw_texture_rect(texture, Rect2(-size / 2.0, size), false, tint)


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


func _draw() -> void:
	super._draw()
	_draw_slam_warning()


func _on_death_fx() -> void:
	Fx.burst(global_position, color.lightened(0.2), 60, 520.0, 9.0)
	Fx.burst(global_position, Color(1.0, 0.85, 0.5), 30, 380.0, 7.0)
	Fx.ring(global_position, Color(1, 0.9, 0.6), 420.0, 0.8, 14.0)
	Fx.shake(0.9)
	Fx.hitstop(0.25)
	Fx.flash(Color(1, 0.95, 0.8, 0.8), 0.8)


## Предупреждение об ударе щупальцем рисуем в точке на полу.
func _draw_slam_warning() -> void:
	if _slam_warning >= 0.0:
		var local := to_local(_slam_pos)
		var k := _slam_warning / SLAM_WARN
		draw_circle(local, slam_radius, Color(1, 0.2, 0.2, 0.12 + 0.2 * k))
		draw_arc(local, slam_radius * k, 0.0, TAU, 48, Color(1, 0.3, 0.3, 0.9), 4.0)
		draw_arc(local, slam_radius, 0.0, TAU, 48, Color(1, 0.3, 0.3, 0.9), 3.0)

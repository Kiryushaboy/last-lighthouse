extends Node2D
## Главная сцена: таймер ночи, появление врагов, опыт, уровни, конец забега.

## Какие враги приходят ночью: с какой секунды и как часто (вес).
const ENEMY_TYPES := [
	{"scene": preload("res://scenes/enemies/crab.tscn"), "from": 0.0, "weight": 1.0},
	{"scene": preload("res://scenes/enemies/jellyfish.tscn"), "from": 60.0, "weight": 0.45},
	{"scene": preload("res://scenes/enemies/squid.tscn"), "from": 120.0, "weight": 0.2},
	{"scene": preload("res://scenes/enemies/shell.tscn"), "from": 180.0, "weight": 0.12},
]
const GEM_SCENE := preload("res://scenes/xp_gem.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/boss.tscn")
const BOSS_AT := 270.0  ## на 4:30 из тумана выходит спрут

const RUN_TIME := 300.0  ## 5 минут до рассвета
const ARENA := Rect2(-900, -900, 1800, 1800)
const MAX_ENEMIES := 150
const SPAWN_DISTANCE := 800.0  ## чуть дальше края экрана

@onready var player: Player = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var enemies: Node2D = $World/Enemies
@onready var gems: Node2D = $World/Gems
@onready var beam: Beam = $World/Beam
@onready var enemy_projectiles: Node2D = $World/EnemyProjectiles
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud: Hud = $HUD
@onready var joystick: TouchJoystick = $Controls/Joystick
@onready var upgrade_menu: UpgradeMenu = $UpgradeMenu
@onready var end_screen: EndScreen = $EndScreen
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var workshop: Workshop = $Workshop

var time_left := RUN_TIME
var level := 1
var xp := 0
var xp_to_next := 5
var upgrades_taken := {}  ## id улучшения -> сколько раз взято

var _pending_levels := 0
var _over := false
var won := false
var shells_this_run := 0
var boss: Boss


func _ready() -> void:
	player.arena_rect = ARENA
	player.bullet_container = $World/Bullets
	camera.limit_left = int(ARENA.position.x)
	camera.limit_top = int(ARENA.position.y)
	camera.limit_right = int(ARENA.end.x)
	camera.limit_bottom = int(ARENA.end.y)

	_apply_workshop()
	player.died.connect(_on_player_died)
	player.health_changed.connect(hud.set_health)
	spawn_timer.timeout.connect(_on_spawn_timer)
	upgrade_menu.chosen.connect(_on_upgrade_chosen)
	end_screen.restart_pressed.connect(_restart)
	end_screen.workshop_pressed.connect(func(): end_screen.hide(); workshop.open())
	workshop.closed.connect(end_screen.show)
	hud.pause_pressed.connect(_open_pause)
	pause_menu.open_requested.connect(_open_pause)
	pause_menu.resume_pressed.connect(_close_pause)
	pause_menu.restart_pressed.connect(_restart)

	hud.set_health(player.hp, player.max_hp)
	hud.set_xp(xp, xp_to_next, level)
	hud.set_time(time_left)


func _process(delta: float) -> void:
	if _over:
		return
	time_left = maxf(time_left - delta, 0.0)
	hud.set_time(time_left)
	player.joystick_vector = joystick.vector
	if boss == null and RUN_TIME - time_left >= BOSS_AT:
		_spawn_boss()
	# Рассвет наступает, только когда спрут побеждён. До тех пор таймер стоит на 0:00.


func _notification(what: int) -> void:
	# Свернули приложение на телефоне: открываем паузу, чтобы не погибнуть без нас.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_open_pause()


## Вечные бонусы из мастерской действуют с первой секунды забега.
func _apply_workshop() -> void:
	player.max_hp += SaveData.level_of("hp")
	player.hp = player.max_hp
	player.crit_chance = 0.08 * SaveData.level_of("crit")
	player.speed *= 1.0 + 0.05 * SaveData.level_of("speed")
	for i in SaveData.level_of("start"):
		var choice := Upgrades.pick_choices(upgrades_taken, 1)
		if choice.is_empty():
			break
		upgrades_taken[choice[0].id] = upgrades_taken.get(choice[0].id, 0) + 1
		Upgrades.apply(choice[0].id, player)


# --- Пауза -------------------------------------------------------------

func _open_pause() -> void:
	if _over or upgrade_menu.visible or pause_menu.visible:
		return
	joystick.reset()
	get_tree().paused = true
	pause_menu.show()


func _close_pause() -> void:
	pause_menu.hide()
	get_tree().paused = false


# --- Враги -------------------------------------------------------------

func _on_spawn_timer() -> void:
	var elapsed := RUN_TIME - time_left
	# Чем дольше идёт ночь, тем больше врагов за раз и тем чаще они приходят.
	# Когда пришёл босс, мелочи вдвое меньше, чтобы было видно его атаки.
	var count := 1 + int(elapsed / 60.0)
	if is_instance_valid(boss):
		count = maxi(1, count / 2)
	for i in count:
		if enemies.get_child_count() >= MAX_ENEMIES:
			break
		_spawn_enemy(elapsed)
	spawn_timer.wait_time = maxf(0.5, 1.4 - elapsed / 330.0)


func _spawn_enemy(elapsed: float) -> void:
	var enemy := _pick_enemy_type(elapsed).instantiate() as Enemy
	enemy.target = player
	enemy.beam = beam
	# Каждые полторы минуты враги крепче и чуть быстрее.
	enemy.max_hp += int(elapsed / 90.0) * maxi(1, enemy.max_hp / 2)
	enemy.speed *= 1.0 + minf(elapsed / 300.0, 1.0) * 0.5
	if enemy is Squid:
		(enemy as Squid).projectile_container = enemy_projectiles
	enemy.killed.connect(_on_enemy_killed.bind(enemy.shell_chance))
	enemies.add_child(enemy)
	var angle := randf() * TAU
	var pos := player.global_position + Vector2.RIGHT.rotated(angle) * SPAWN_DISTANCE
	enemy.global_position = pos.clamp(ARENA.position, ARENA.end)


func _spawn_boss() -> void:
	boss = BOSS_SCENE.instantiate() as Boss
	boss.target = player
	boss.beam = beam
	boss.projectile_container = enemy_projectiles
	boss.killed.connect(_on_boss_killed)
	boss.health_changed.connect(hud.set_boss_health)
	enemies.add_child(boss)
	var pos := player.global_position + Vector2.UP * SPAWN_DISTANCE * 0.8
	boss.global_position = pos.clamp(ARENA.position, ARENA.end)
	hud.show_boss(boss.hp, boss.max_hp)


func _on_boss_killed(_at: Vector2, _xp: int) -> void:
	_add_shells(30)
	_finish(true)


func _add_shells(amount: int) -> void:
	shells_this_run += amount
	hud.set_shells(shells_this_run)


## Случайный тип врага с учётом весов среди уже открывшихся к этой секунде.
func _pick_enemy_type(elapsed: float) -> PackedScene:
	var open := ENEMY_TYPES.filter(func(t): return elapsed >= t.from)
	var total := 0.0
	for t in open:
		total += t.weight
	var roll := randf() * total
	for t in open:
		roll -= t.weight
		if roll <= 0.0:
			return t.scene
	return open[0].scene


func _on_enemy_killed(at: Vector2, xp_value: int, shell_chance: float) -> void:
	# Враг погиб во время расчёта физики, поэтому предметы создаём чуть позже.
	_spawn_gem.call_deferred(at, xp_value)
	if randf() < shell_chance:
		_spawn_gem.call_deferred(at + Vector2(14, 0), 1, true)


func _spawn_gem(at: Vector2, value: int, is_shell := false) -> void:
	var gem := GEM_SCENE.instantiate() as XpGem
	gem.value = value
	gem.is_shell = is_shell
	gem.player = player
	gem.collected.connect(_add_shells if is_shell else _add_xp)
	gems.add_child(gem)
	gem.global_position = at


# --- Опыт и улучшения --------------------------------------------------

func _add_xp(amount: int) -> void:
	if _over:
		return
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = 5 + (level - 1) * 3
		_pending_levels += 1
	hud.set_xp(xp, xp_to_next, level)
	if _pending_levels > 0 and not upgrade_menu.visible:
		_offer_upgrade()


func _offer_upgrade() -> void:
	var choices := Upgrades.pick_choices(upgrades_taken, 3)
	if choices.is_empty():
		_pending_levels = 0
		return
	_pending_levels -= 1
	joystick.reset()
	get_tree().paused = true
	upgrade_menu.show_choices(choices)


func _on_upgrade_chosen(id: String) -> void:
	upgrades_taken[id] = upgrades_taken.get(id, 0) + 1
	Upgrades.apply(id, player)
	hud.set_health(player.hp, player.max_hp)
	get_tree().paused = false
	if _pending_levels > 0:
		_offer_upgrade()


# --- Конец забега ------------------------------------------------------

func _on_player_died() -> void:
	_finish(false)


func _finish(victory: bool) -> void:
	if _over:
		return
	_over = true
	won = victory
	joystick.reset()
	upgrade_menu.hide()
	get_tree().paused = true
	# Бонус за выживание: ракушка за каждые 20 секунд ночи.
	shells_this_run += int((RUN_TIME - time_left) / 20.0)
	SaveData.add_shells(shells_this_run)
	end_screen.show_result(victory, level, RUN_TIME - time_left, shells_this_run)


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

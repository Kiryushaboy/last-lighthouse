extends Node2D
## Главная сцена: таймер ночи, появление врагов, опыт, уровни, конец забега.

const CRAB_SCENE := preload("res://scenes/crab.tscn")
const GEM_SCENE := preload("res://scenes/xp_gem.tscn")

const RUN_TIME := 300.0  ## 5 минут до рассвета
const ARENA := Rect2(-900, -900, 1800, 1800)
const MAX_ENEMIES := 150
const SPAWN_DISTANCE := 800.0  ## чуть дальше края экрана

@onready var player: Player = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var enemies: Node2D = $World/Enemies
@onready var gems: Node2D = $World/Gems
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud: Hud = $HUD
@onready var joystick: TouchJoystick = $Controls/Joystick
@onready var upgrade_menu: UpgradeMenu = $UpgradeMenu
@onready var end_screen: EndScreen = $EndScreen

var time_left := RUN_TIME
var level := 1
var xp := 0
var xp_to_next := 5
var upgrades_taken := {}  ## id улучшения -> сколько раз взято

var _pending_levels := 0
var _over := false


func _ready() -> void:
	player.arena_rect = ARENA
	player.bullet_container = $World/Bullets
	camera.limit_left = int(ARENA.position.x)
	camera.limit_top = int(ARENA.position.y)
	camera.limit_right = int(ARENA.end.x)
	camera.limit_bottom = int(ARENA.end.y)

	player.died.connect(_on_player_died)
	player.health_changed.connect(hud.set_health)
	spawn_timer.timeout.connect(_on_spawn_timer)
	upgrade_menu.chosen.connect(_on_upgrade_chosen)
	end_screen.restart_pressed.connect(_restart)

	hud.set_health(player.hp, player.max_hp)
	hud.set_xp(xp, xp_to_next, level)
	hud.set_time(time_left)


func _process(delta: float) -> void:
	if _over:
		return
	time_left -= delta
	hud.set_time(time_left)
	player.joystick_vector = joystick.vector
	if time_left <= 0.0:
		_finish(true)


func _notification(what: int) -> void:
	# Свернули приложение на телефоне: останавливаем время.
	# Полноценное меню паузы сделаем позже.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not _over and not upgrade_menu.visible:
		get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and not _over and not upgrade_menu.visible:
		get_tree().paused = false


# --- Враги -------------------------------------------------------------

func _on_spawn_timer() -> void:
	var elapsed := RUN_TIME - time_left
	# Чем дольше идёт ночь, тем больше крабов за раз и тем чаще они приходят.
	var count := 1 + int(elapsed / 60.0)
	for i in count:
		if enemies.get_child_count() >= MAX_ENEMIES:
			break
		_spawn_crab(elapsed)
	spawn_timer.wait_time = maxf(0.5, 1.4 - elapsed / 330.0)


func _spawn_crab(elapsed: float) -> void:
	var crab := CRAB_SCENE.instantiate() as Crab
	crab.target = player
	crab.max_hp = 2 + int(elapsed / 90.0)
	crab.speed = minf(90.0 + elapsed * 0.2, 150.0)
	crab.killed.connect(_on_enemy_killed)
	enemies.add_child(crab)
	var angle := randf() * TAU
	var pos := player.global_position + Vector2.RIGHT.rotated(angle) * SPAWN_DISTANCE
	crab.global_position = pos.clamp(ARENA.position, ARENA.end)


func _on_enemy_killed(at: Vector2, xp_value: int) -> void:
	# Враг погиб во время расчёта физики, поэтому кристалл создаём чуть позже.
	_spawn_gem.call_deferred(at, xp_value)


func _spawn_gem(at: Vector2, value: int) -> void:
	var gem := GEM_SCENE.instantiate() as XpGem
	gem.value = value
	gem.player = player
	gem.collected.connect(_add_xp)
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


func _finish(won: bool) -> void:
	if _over:
		return
	_over = true
	joystick.reset()
	upgrade_menu.hide()
	get_tree().paused = true
	end_screen.show_result(won, level, RUN_TIME - maxf(time_left, 0.0))


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

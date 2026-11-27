extends Node
## Прогресс между забегами: ракушки и уровни вечных бонусов мастерской.
## Автозагрузка «SaveData», хранится в user://save.cfg на устройстве.

signal changed

const PATH := "user://save.cfg"

## Бонусы мастерской. Цена уровня n = costs[n].
## Через сколько секунд «Второе дыхание» лечит одно сердце, по уровням.
const REGEN_EVERY := [0, 60, 45, 30]

const PERKS := [
	{"id": "hp", "title": "Крепкое здоровье", "desc": "+1 жизнь на старте", "costs": [10, 20, 35, 55, 80]},
	{"id": "power", "title": "Закалённые гарпуны", "desc": "+1 к урону оружия", "costs": [60, 150, 300]},
	{"id": "crit", "title": "Острые гарпуны", "desc": "+8% шанс двойного урона", "costs": [10, 20, 35, 55, 80]},
	{"id": "speed", "title": "Удобные сапоги", "desc": "+5% к скорости", "costs": [10, 20, 35, 55, 80]},
	{"id": "start", "title": "Опытный", "desc": "+1 случайное улучшение на старте", "costs": [30, 60, 100]},
	{"id": "bubble", "title": "Запасной пузырь", "desc": "Щит с самого начала ночи", "costs": [120]},
	{"id": "regen", "title": "Второе дыхание", "desc": "Сердце восстанавливается само", "costs": [40, 80, 130]},
	{"id": "pull", "title": "Морской магнит", "desc": "+15% к радиусу сбора", "costs": [15, 30, 50]},
	{"id": "luck", "title": "Удачливый ныряльщик", "desc": "+10% ракушек за ночь", "costs": [25, 50, 90]},
]

var shells := 0
var levels := {}  ## id бонуса -> купленный уровень
var stars := {}  ## номер ночи -> лучший результат в звёздах (0..3)
var current_night := 0  ## какую ночь сейчас играем (не сохраняется)
var hero := "keeper"  ## выбранный герой
var heroes := ["keeper"]  ## открытые герои
var best_time := 0.0  ## рекорд бесконечной ночи: секунд
var best_kills := 0  ## рекорд бесконечной ночи: врагов


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		shells = cfg.get_value("progress", "shells", 0)
		levels = cfg.get_value("progress", "levels", {})
		stars = cfg.get_value("progress", "stars", {})
		best_time = cfg.get_value("endless", "best_time", 0.0)
		hero = cfg.get_value("heroes", "current", "keeper")
		heroes = cfg.get_value("heroes", "owned", ["keeper"])
		best_kills = cfg.get_value("endless", "best_kills", 0)


func level_of(id: String) -> int:
	return levels.get(id, 0)


func perk(id: String) -> Dictionary:
	for p in PERKS:
		if p.id == id:
			return p
	return {}


## Цена следующего уровня или -1, если бонус прокачан до конца.
func next_cost(id: String) -> int:
	var costs: Array = perk(id).costs
	var lvl := level_of(id)
	return costs[lvl] if lvl < costs.size() else -1


func buy(id: String) -> bool:
	var cost := next_cost(id)
	if cost < 0 or shells < cost:
		return false
	shells -= cost
	levels[id] = level_of(id) + 1
	_save()
	return true


func stars_of(night: int) -> int:
	return stars.get(night, 0)


func total_stars() -> int:
	var t := 0
	for k in stars:
		t += stars[k]
	return t


## Записать результат ночи. Возвращает, сколько звёзд получено впервые (за них награда).
func record_stars(night: int, got: int) -> int:
	var before := stars_of(night)
	if got > before:
		stars[night] = got
		_save()
	return maxi(got - before, 0)


## Записать результат бесконечной ночи. Возвращает [новый рекорд времени?, новый рекорд врагов?].
func record_endless(time: float, kills: int) -> Array:
	var r := [time > best_time, kills > best_kills]
	best_time = maxf(best_time, time)
	best_kills = maxi(best_kills, kills)
	_save()
	return r


## Купить героя за ракушки (или просто выбрать, если уже открыт).
func choose_hero(id: String, cost: int) -> bool:
	if not id in heroes:
		if shells < cost:
			return false
		shells -= cost
		heroes.append(id)
	hero = id
	_save()
	return true


func add_shells(amount: int) -> void:
	shells += amount
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "shells", shells)
	cfg.set_value("progress", "levels", levels)
	cfg.set_value("progress", "stars", stars)
	cfg.set_value("endless", "best_time", best_time)
	cfg.set_value("heroes", "current", hero)
	cfg.set_value("heroes", "owned", heroes)
	cfg.set_value("endless", "best_kills", best_kills)
	cfg.save(PATH)
	changed.emit()

extends Node
## Прогресс между забегами: ракушки и уровни вечных бонусов мастерской.
## Автозагрузка «SaveData», хранится в user://save.cfg на устройстве.

signal changed

const PATH := "user://save.cfg"

## Бонусы мастерской. Цена уровня n = costs[n].
const PERKS := [
	{"id": "hp", "title": "Крепкое здоровье", "desc": "+1 жизнь на старте", "costs": [10, 20, 35, 55, 80]},
	{"id": "crit", "title": "Острые гарпуны", "desc": "+8% шанс двойного урона", "costs": [10, 20, 35, 55, 80]},
	{"id": "speed", "title": "Удобные сапоги", "desc": "+5% к скорости", "costs": [10, 20, 35, 55, 80]},
	{"id": "start", "title": "Опытный смотритель", "desc": "+1 случайное улучшение на старте", "costs": [30, 60, 100]},
]

var shells := 0
var levels := {}  ## id бонуса -> купленный уровень


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		shells = cfg.get_value("progress", "shells", 0)
		levels = cfg.get_value("progress", "levels", {})


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


func add_shells(amount: int) -> void:
	shells += amount
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "shells", shells)
	cfg.set_value("progress", "levels", levels)
	cfg.save(PATH)
	changed.emit()

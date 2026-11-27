class_name Upgrades
extends RefCounted
## Улучшения забега. У каждого понятное «что делает» и точные числа по уровням,
## чтобы на карточке было видно: «Урон: 1 → 2».
## Новое улучшение = запись в LIST + ветка в apply() и describe().

const MAX_LEVEL := 3

const LIST := [
	{"id": "damage", "title": "Острые гарпуны", "what": "Каждый гарпун бьёт сильнее"},
	{"id": "fire_rate", "title": "Быстрая перезарядка", "what": "Смотритель стреляет чаще"},
	{"id": "multishot", "title": "Веер", "what": "Несколько гарпунов за выстрел, веером"},
	{"id": "pierce", "title": "Пробивание", "what": "Гарпун летит сквозь врагов дальше"},
	{"id": "shield", "title": "Щит", "what": "Пузырь гасит один удар и восстанавливается"},
	{"id": "speed", "title": "Лёгкие сапоги", "what": "Бегаете быстрее"},
	{"id": "max_hp", "title": "Крепкий смотритель", "what": "Лишнее сердце и лечение"},
	{"id": "magnet", "title": "Магнит", "what": "Опыт и ракушки летят к вам издалека"},
	{"id": "beam", "title": "Линза Френеля", "what": "Луч маяка шире. В луче враги медленнее и получают ×2 урона"},
]

## Шаги улучшений по уровням (индекс = сколько раз уже взято).
const FIRE_STEP := 0.8  ## интервал между выстрелами умножается на это
const SHIELD_RECHARGE := [0.0, 12.0, 8.0, 5.0]
const SPEED_PCT := [100, 115, 130, 145]
const MAGNET_PCT := [100, 160, 220, 280]
const BEAM_DEG := [30, 40, 53, 70]  ## полная ширина луча
const AURA_STEP := 0.2  ## +20% радиуса огненного круга

## У молнии и огня свои названия для некоторых улучшений.
const WEAPON_TEXT := {
	"lightning": {
		"damage": ["Сильный разряд", "Каждая молния бьёт сильнее"],
		"fire_rate": ["Быстрый заряд", "Молния бьёт чаще"],
		"multishot": ["Цепная молния", "Молния перескакивает на большее число врагов"],
	},
	"aura": {
		"damage": ["Жаркое пламя", "Огонь жжёт сильнее"],
		"fire_rate": ["Частое пламя", "Огонь вспыхивает чаще"],
		"multishot": ["Большой фонарь", "Огненный круг шире"],
	},
}


static func info(id: String, weapon := "harpoon") -> Dictionary:
	for u in LIST:
		if u.id == id:
			var d: Dictionary = u.duplicate()
			var over: Dictionary = WEAPON_TEXT.get(weapon, {})
			if over.has(id):
				d.title = over[id][0]
				d.what = over[id][1]
			return d
	return {}


## Применить следующий уровень. level — каким он стал (1..MAX_LEVEL).
static func apply(id: String, player: Player, level: int) -> void:
	match id:
		"damage":
			player.damage += 1
		"fire_rate":
			player.fire_interval *= FIRE_STEP
		"multishot":
			player.projectiles += 1
		"pierce":
			player.pierce += 1
		"shield":
			player.set_shield(SHIELD_RECHARGE[level])
		"speed":
			player.speed *= float(SPEED_PCT[level]) / SPEED_PCT[level - 1]
		"max_hp":
			player.max_hp += 1
			player.heal(1)
		"magnet":
			player.pickup_radius *= float(MAGNET_PCT[level]) / MAGNET_PCT[level - 1]
		"beam":
			var beam := player.get_tree().get_first_node_in_group("beam") as Beam
			if beam:
				beam.half_width_deg = BEAM_DEG[level] / 2.0
		_:
			push_warning("Неизвестное улучшение: %s" % id)


## Что изменится, если взять улучшение ещё раз: «Урон: 1 → 2».
static func describe(id: String, level: int, player: Player) -> String:
	var n := level + 1
	var weapon := player.weapon if player else "harpoon"
	match id:
		"damage":
			var d := player.damage if player else 1
			return "Урон: %d → %d" % [d, d + 1]
		"fire_rate":
			var iv := player.fire_interval if player else 0.45
			var what := "Вспышек" if weapon == "aura" else ("Молний" if weapon == "lightning" else "Выстрелов")
			return "%s в секунду: %.1f → %.1f" % [what, 1.0 / iv, 1.0 / (iv * FIRE_STEP)]
		"multishot":
			var p := player.projectiles if player else 1
			if weapon == "lightning":
				return "Перескоков молнии: %d → %d" % [p + 1, p + 2]
			if weapon == "aura":
				return "Радиус огня: %d%% → %d%%" % [100 + (p - 1) * 20, 100 + p * 20]
			return "Гарпунов за выстрел: %d → %d" % [p, p + 1]
		"pierce":
			var pc := player.pierce if player else 0
			return "Пробивает врагов: %d → %d" % [pc, pc + 1]
		"shield":
			if level == 0:
				return "Восстановление щита: %d с" % SHIELD_RECHARGE[n]
			return "Восстановление щита: %d с → %d с" % [SHIELD_RECHARGE[level], SHIELD_RECHARGE[n]]
		"speed":
			return "Скорость: %d%% → %d%%" % [SPEED_PCT[level], SPEED_PCT[n]]
		"max_hp":
			var hp_max := player.max_hp if player else 5
			return "Сердец: %d → %d, и лечит одно" % [hp_max, hp_max + 1]
		"magnet":
			return "Радиус сбора: %d%% → %d%%" % [MAGNET_PCT[level], MAGNET_PCT[n]]
		"beam":
			return "Ширина луча: %d° → %d°" % [BEAM_DEG[level], BEAM_DEG[n]]
	return ""


## Выбирает до count случайных улучшений, которые ещё не взяты MAX_LEVEL раз.
## Пробивание есть только у гарпунов. Возвращает описания с названиями под оружие героя.
static func pick_choices(taken: Dictionary, count: int, weapon := "harpoon") -> Array:
	var available := LIST.filter(_allowed.bind(taken, weapon))
	available.shuffle()
	return available.slice(0, count).map(func(u): return info(u.id, weapon))


static func _allowed(u: Dictionary, taken: Dictionary, weapon: String) -> bool:
	if taken.get(u.id, 0) >= MAX_LEVEL:
		return false
	return not (u.id == "pierce" and weapon != "harpoon")

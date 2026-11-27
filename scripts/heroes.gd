class_name Heroes
extends RefCounted
## Герои: у каждого своё оружие и характеристики. Открываются за ракушки в меню «Герои».

const LIST := [
	{"id": "keeper", "title": "Смотритель", "weapon": "harpoon", "cost": 0,
		"desc": "Гарпуны в ближайшего врага. Надёжно и просто.",
		"hp": 5, "speed": 260.0, "damage": 1, "interval": 0.45, "pierce": 0,
		"tint": Color(1, 1, 1), "neon": Color(1.0, 0.75, 0.3)},
	{"id": "bosun", "title": "Боцман", "weapon": "harpoon", "cost": 150,
		"desc": "Тяжёлые гарпуны: бьют вдвое сильнее и пробивают врага, но реже. +1 сердце.",
		"hp": 6, "speed": 235.0, "damage": 2, "interval": 0.7, "pierce": 1,
		"tint": Color(1.0, 0.62, 0.62), "neon": Color(1.0, 0.45, 0.35)},
	{"id": "mechanic", "title": "Механик", "weapon": "lightning", "cost": 300,
		"desc": "Молния: бьёт мгновенно и перескакивает ещё на двух врагов рядом.",
		"hp": 5, "speed": 260.0, "damage": 1, "interval": 0.6, "pierce": 0,
		"tint": Color(0.7, 0.85, 1.3), "neon": Color(0.5, 0.8, 1.0)},
	{"id": "lamplighter", "title": "Фонарщица", "weapon": "aura", "cost": 450,
		"desc": "Огненный круг вокруг себя жжёт всех рядом. Быстрая, но 4 сердца.",
		"hp": 4, "speed": 285.0, "damage": 1, "interval": 0.5, "pierce": 0,
		"tint": Color(1.3, 0.9, 0.6), "neon": Color(1.0, 0.5, 0.25)},
]


static func get_hero(id: String) -> Dictionary:
	for h in LIST:
		if h.id == id:
			return h
	return LIST[0]


static func current() -> Dictionary:
	return get_hero(SaveData.hero)


## Задать герою базовые характеристики до бонусов мастерской.
static func apply(hero: Dictionary, player: Player) -> void:
	player.weapon = hero.weapon
	player.max_hp = hero.hp
	player.hp = hero.hp
	player.speed = hero.speed
	player.damage = hero.damage
	player.fire_interval = hero.interval
	player.pierce = hero.pierce
	player.tint = hero.tint
	player.neon = hero.neon

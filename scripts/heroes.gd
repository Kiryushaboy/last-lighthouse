class_name Heroes
extends RefCounted
## Герои: у каждого своё оружие и характеристики. Открываются за ракушки в меню «Герои».

const LIST := [
	{"id": "keeper", "sprite": "res://art/sprites/player.svg", "title": "Смотритель", "weapon": "harpoon", "cost": 0,
		"desc": "Гарпуны в ближайшего врага. Надёжно и просто.",
		"hp": 5, "speed": 260.0, "damage": 1, "interval": 0.45, "pierce": 0,
		"tint": Color(1, 1, 1), "neon": Color(1.0, 0.75, 0.3)},
	{"id": "mechanic", "sprite": "res://art/sprites/mechanic.svg", "title": "Механик", "weapon": "lightning", "cost": 1000,
		"desc": "Молния: бьёт мгновенно и перескакивает ещё на двух врагов рядом.",
		"hp": 5, "speed": 260.0, "damage": 1, "interval": 0.6, "pierce": 0,
		"tint": Color(1, 1, 1), "neon": Color(0.5, 0.8, 1.0)},
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
	player.texture = load(hero.sprite)
	player.neon = hero.neon

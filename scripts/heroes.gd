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
	{"id": "witch", "sprite": "res://art/sprites/witch.svg", "title": "Ведьма", "weapon": "bats", "cost": 2500,
		"desc": "Летучие мыши кружат рядом и сами бросаются на врагов поблизости.",
		"hp": 5, "speed": 285.0, "damage": 1, "interval": 0.6, "pierce": 0,
		"tint": Color(1, 1, 1), "neon": Color(0.75, 0.5, 1.0)},
	{"id": "siren", "sprite": "res://art/sprites/siren.svg", "title": "Сирена", "weapon": "wave", "cost": 4000,
		"desc": "Песня расходится кольцом: ранит и отбрасывает всех вокруг.",
		"hp": 4, "speed": 260.0, "damage": 2, "interval": 1.3, "pierce": 0,
		"tint": Color(1, 1, 1), "neon": Color(0.4, 0.95, 0.85)},
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

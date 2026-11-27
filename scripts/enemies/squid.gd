class_name Squid
extends Enemy
## Кальмар: держится на расстоянии и плюётся чернилами.

const INK_SCENE := preload("res://scenes/enemies/ink.tscn")

@export var keep_distance := 320.0
@export var shoot_interval := 2.5

var projectile_container: Node
var _cooldown := 1.5


func _move(delta: float, current_speed: float) -> void:
	var to_player := target.global_position - global_position
	var dist := to_player.length()
	if dist > keep_distance + 40.0:
		global_position += to_player.normalized() * current_speed * delta
	elif dist < keep_distance - 40.0:
		global_position -= to_player.normalized() * current_speed * delta

	_cooldown -= delta
	if _cooldown <= 0.0 and dist < keep_distance + 200.0 and projectile_container:
		_cooldown = shoot_interval
		var ink := INK_SCENE.instantiate() as Ink
		ink.direction = to_player.normalized()
		projectile_container.add_child(ink)
		ink.global_position = global_position


func _draw_body(c: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -radius - 4), Vector2(radius, 4), Vector2(0, radius), Vector2(-radius, 4)]), c)

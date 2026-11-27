class_name Puffer
extends Enemy
## Рыба-ёж: медленная, а при гибели разлетается чернильными шипами во все стороны.

const INK_SCENE := preload("res://scenes/enemies/ink.tscn")
const SPIKES := 6

var projectile_container: Node


func _on_death_fx() -> void:
	super._on_death_fx()
	if not projectile_container:
		return
	var offset := randf() * TAU
	for i in SPIKES:
		var ink := INK_SCENE.instantiate() as Ink
		ink.direction = Vector2.RIGHT.rotated(offset + TAU * i / SPIKES)
		ink.speed = 190.0
		projectile_container.add_child.call_deferred(ink)
		ink.set_deferred("global_position", global_position)

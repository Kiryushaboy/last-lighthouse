class_name Ember
extends Enemy
## Лавовый краб: в броне и медленный, но чем сильнее ранен, тем горячее и быстрее.


func _move(delta: float, current_speed: float) -> void:
	var rage := 1.0 + (1.0 - float(hp) / max_hp) * 1.3
	super._move(delta, current_speed * rage)
	_body.modulate = Color(1.0 + (rage - 1.0) * 0.8, 1.0, 1.0)

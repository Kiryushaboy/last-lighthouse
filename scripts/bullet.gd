class_name Bullet
extends Area2D
## Снаряд: летит прямо, бьёт первого врага (или нескольких, если есть пробивание).

var direction := Vector2.RIGHT
var speed := 720.0
var damage := 1
var pierce := 0
var lifetime := 1.0

var _spent := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent or not area is Crab:
		return
	(area as Crab).hit(damage)
	if pierce > 0:
		pierce -= 1
	else:
		_spent = true
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.6, 0.9, 1.0))

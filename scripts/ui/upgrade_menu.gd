class_name UpgradeMenu
extends CanvasLayer
## Меню выбора 1 из 3 улучшений. Работает, пока игра на паузе.

signal chosen(id: String)

@onready var _choices: VBoxContainer = $Box/Choices


func show_choices(choices: Array) -> void:
	for child in _choices.get_children():
		child.queue_free()
	for i in choices.size():
		var upgrade: Dictionary = choices[i]
		var button := Button.new()
		button.text = "%d. %s\n%s" % [i + 1, upgrade.title, upgrade.desc]
		button.custom_minimum_size = Vector2(0, 140)
		button.pressed.connect(_pick.bind(upgrade.id))
		_choices.add_child(button)
	show()


func _unhandled_input(event: InputEvent) -> void:
	# Клавиши 1-3 на ноутбуке.
	if not visible or not event is InputEventKey or not event.pressed:
		return
	var index: int = (event as InputEventKey).keycode - KEY_1
	var buttons := _choices.get_children().filter(func(b): return not b.is_queued_for_deletion())
	if index >= 0 and index < buttons.size():
		(buttons[index] as Button).pressed.emit()


func _pick(id: String) -> void:
	hide()
	chosen.emit(id)

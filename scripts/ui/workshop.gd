class_name Workshop
extends CanvasLayer
## Мастерская: вечные бонусы за ракушки. Строки собираются из SaveData.PERKS.

signal closed

@onready var _shells: Label = $Box/Shells
@onready var _rows: VBoxContainer = $Box/Rows
@onready var _back: Button = $Box/Back


func _ready() -> void:
	_back.pressed.connect(_close)


func open() -> void:
	_rebuild()
	show()


func _close() -> void:
	hide()
	closed.emit()


func _rebuild() -> void:
	_shells.text = "Ракушки: %d" % SaveData.shells
	for child in _rows.get_children():
		child.queue_free()
	for p in SaveData.PERKS:
		var lvl := SaveData.level_of(p.id)
		var cost := SaveData.next_cost(p.id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 150)
		button.add_theme_font_size_override("font_size", 28)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var price := "Максимум" if cost < 0 else "Купить за %d" % cost
		button.text = "%s  %d/%d\n%s\n%s" % [p.title, lvl, p.costs.size(), p.desc, price]
		button.disabled = cost < 0 or SaveData.shells < cost
		button.pressed.connect(_buy.bind(p.id))
		_rows.add_child(button)


func _buy(id: String) -> void:
	if SaveData.buy(id):
		_rebuild()

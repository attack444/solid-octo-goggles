extends Node2D

@onready var label = $Label

func start(text_to_show: String, start_pos: Vector2):
	label.text = text_to_show
	global_position = start_pos
	
	var tween = create_tween()
	
	# Движение вверх
	tween.tween_property(self, "position:y", position.y - 50, 0.8)
	
	# Исчезновение (прозрачность)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	
	await tween.finished
	
	queue_free()

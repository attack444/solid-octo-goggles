extends Control

@onready var event_text = $EventTextLabel
@onready var choice_a = $ChoiceAButton
@onready var choice_b = $ChoiceBButton

var current_event: Dictionary = {}

func initialize(event_data: Dictionary):
	current_event = event_data
	
	event_text.text = current_event.text
	choice_a.text = current_event.choice[0]
	choice_b.text = current_event.choice[1]
	
	choice_a.pressed.disconnect_all()
	choice_b.pressed.disconnect_all()
	
	choice_a.pressed.connect(func():
		apply_effect(0)
	)
	choice_b.pressed.connect(func():
		apply_effect(1)
	)

func apply_effect(choice_idx: int):
	var stat_to_change = current_event.stat_change[choice_idx]
	var effect = current_event.effect[choice_idx]
	
	# Изменение глобальных переменных
	match stat_to_change:
		"money":
			Global.money += effect
		"health":
			Global.health = clampf(Global.health + effect, 0.0, 100.0)
		"happiness":
			Global.happiness = clampf(Global.happiness + effect, 0.0, 100.0)
		_:
			push_warning("Неизвестный параметр события: " + stat_to_change)
			
	Global.emit_signal("game_state_changed")
	queue_free()

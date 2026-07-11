extends Control

@onready var event_text = $EventTextLabel
@onready var choice_a = $ChoiceAButton
@onready var choice_b = $ChoiceBButton

var current_event: Dictionary = {}

func _ready():
	# Подключаем кнопки ОДИН РАЗ при создании окна
	choice_a.pressed.connect(_on_choice_a_pressed)
	choice_b.pressed.connect(_on_choice_b_pressed)

func initialize(event_data: Dictionary):
	current_event = event_data
	
	# Заполняем текст на основе данных события
	event_text.text = current_event["text"]
	choice_a.text = current_event["choice"][0]
	choice_b.text = current_event["choice"][1]
	
	# Окно уже видно, потому что его добавил main.gd через add_child.
	# Если хочешь добавить эффект появления (fade-in) — можно сделать через Tween здесь.

func _on_choice_a_pressed():
	apply_effect(0)

func _on_choice_b_pressed():
	apply_effect(1)

func apply_effect(choice_idx: int):
	var stat_to_change = current_event["stat_change"][choice_idx]
	var effect = current_event["effect"][choice_idx]
	
	match stat_to_change:
		"money":
			Global.money += effect
		"health":
			Global.health = clampf(Global.health + effect, 0.0, 100.0)
		"happiness":
			Global.happiness = clampf(Global.happiness + effect, 0.0, 100.0)
		_:
			push_warning("Неизвестный параметр события: " + str(stat_to_change))
			
	Global.emit_signal("game_state_changed")
	queue_free()

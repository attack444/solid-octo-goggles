extends Control

# Привязка UI
@onready var happiness_status_label = $HappinessStatusLabel # Текущий уровень счастья
@onready var activities_container = $ActivitiesContainer   # VBoxContainer для кнопок развлечений
@onready var close_button = $CloseButton

func _ready():
	# 1. Подключение к глобальному сигналу для обновления
	Global.game_state_changed.connect(Callable(self, "update_ui"))
	
	# 2. Подключение кнопки закрытия
	if is_instance_valid(close_button):
		close_button.pressed.connect(_on_CloseButton_pressed)
		
	# 3. Первая отрисовка
	update_ui()

# --- ОБНОВЛЕНИЕ ИНТЕРФЕЙСА (Генерация кнопок) ---
func update_ui():
	
	# 1. Обновление статуса счастья
	happiness_status_label.text = "Счастье: %d / 100" % int(Global.happiness)
	
	# 2. Очистка и перерисовка контейнера
	for child in activities_container.get_children():
		child.queue_free()
		
	for key in Global.entertainment_data.keys():
		var activity = Global.entertainment_data[key]
		var btn = Button.new()
		
		var is_on_cooldown = Global.entertainment_cooldowns.has(key) and \
							 Global.entertainment_cooldowns[key] > Time.get_unix_time_from_system()

		# Форматирование текста кнопки
		if is_on_cooldown:
			var remaining = Global.entertainment_cooldowns[key] - Time.get_unix_time_from_system()
			btn.text = "%s (КД: %d сек)" % [activity.name, remaining]
			btn.disabled = true
		else:
			btn.text = "%s ($%d, +%d Счастья)" % [activity.name, int(activity.cost), int(activity.happiness_boost)]
			btn.disabled = Global.money < activity.cost

		# Подключение к логике покупки
		btn.pressed.connect(func():
			buy_activity(key)
		)
		
		activities_container.add_child(btn)
		
# --- ЛОГИКА ПОКУПКИ АКТИВНОСТИ ---
func buy_activity(key: String):
	var activity = Global.entertainment_data[key]
	
	if Global.money >= activity.cost:
		Global.money -= activity.cost
		
		# Увеличение счастья (используем clampf для ограничения от 0 до 100)
		Global.happiness = clampf(Global.happiness + activity.happiness_boost, 0.0, 100.0)
		
		# Установка времени восстановления (cooldown)
		var cooldown_end_time = Time.get_unix_time_from_system() + activity.cooldown
		Global.entertainment_cooldowns[key] = cooldown_end_time
		
		# Уведомляем UI об изменениях
		Global.emit_signal("game_state_changed")
		
	else:
		# Здесь можно добавить звуковой сигнал ошибки
		print("Недостаточно денег для " + activity.name)
		
# --- ЗАКРЫТИЕ ОКНА ---
func _on_CloseButton_pressed():
	queue_free()

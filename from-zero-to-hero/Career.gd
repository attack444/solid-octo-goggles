extends Control

# Привязка UI для карьеры
@onready var career_level_label = $CareerLevelLabel # Ур. Карьеры
@onready var career_upgrade_button = $CareerUpgradeButton # Кнопка апгрейда
@onready var achievements_container = $AchievementsContainer # Контейнер для достижений (VBoxContainer)
@onready var close_button = $CloseButton

const BRANCH_KEY = "career" # Ключ для данных в Global.progress_data

func _ready():
	# 1. Подключение к глобальному сигналу для обновления
	Global.game_state_changed.connect(Callable(self, "update_ui"))
	
	# 2. Подключение кнопки апгрейда
	career_upgrade_button.pressed.connect(func():
		# Global.try_upgrade_progress сам испустит сигнал game_state_changed при успехе
		Global.try_upgrade_progress(BRANCH_KEY)
	)
	
	# 3. Подключение кнопки закрытия
	if is_instance_valid(close_button):
		close_button.pressed.connect(_on_CloseButton_pressed)
		
	# 4. Первая отрисовка
	update_ui()

# --- ОБНОВЛЕНИЕ ИНТЕРФЕЙСА ---
func update_ui():
	var data = Global.progress_data[BRANCH_KEY]
	var next_level = data.level + 1
	
	# --- Обновление Карьеры ---
	if data.level >= data.max:
		career_level_label.text = "КАРЬЕРА: УРОВЕНЬ %d (MAX)" % data.level
		career_upgrade_button.text = "МАКСИМУМ"
		career_upgrade_button.disabled = true
	else:
		var cost = data.unlock_costs[next_level]
		career_level_label.text = "КАРЬЕРА: Ур. %d → %d" % [data.level, next_level]
		career_upgrade_button.text = "Апгрейд ($%d)" % cost
		career_upgrade_button.disabled = Global.money < cost
		
	# --- Обновление Достижений (Placeholder) ---
	# Для демонстрации, просто очистим и добавим текст. 
	# В реальной игре здесь лучше использовать отдельные сцены (ProgressItem)
	for child in achievements_container.get_children():
		child.queue_free()
		
	var prestige_label = Label.new()
	prestige_label.text = "Очки Престижа: " + str(Global.prestige_points)
	achievements_container.add_child(prestige_label)
	
	var money_earned_label = Label.new()
	money_earned_label.text = "Всего заработано: $" + str(int(Global.total_money_earned))
	achievements_container.add_child(money_earned_label)

# --- ФУНКЦИЯ ЗАКРЫТИЯ ---
func _on_CloseButton_pressed():
	queue_free()

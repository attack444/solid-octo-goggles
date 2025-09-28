extends Control

# Привязка кнопок
@onready var housing_button = $HousingButton
@onready var career_button = $CareerButton
@onready var education_button = $EducationButton

# Привязка меток
@onready var housing_label = $HousingLabel
@onready var career_label = $CareerLabel
@onready var education_label = $EducationLabel

# --- ИНИЦИАЛИЗАЦИЯ ---
func _ready():
	# Подключение к глобальному сигналу: любое изменение состояния игры
	# (покупка актива, престиж, доход) вызовет полное обновление этого окна.
	Global.game_state_changed.connect(Callable(self, "update_ui"))
	
	# Подключение кнопок к логике покупки
	housing_button.pressed.connect(func():
		# Global.try_upgrade_progress испустит сигнал game_state_changed при успехе
		Global.try_upgrade_progress("housing") 
	)
	career_button.pressed.connect(func():
		Global.try_upgrade_progress("career")
	)
	education_button.pressed.connect(func():
		Global.try_upgrade_progress("education")
	)
	
	# Первая отрисовка при открытии окна
	update_ui()

# --- ОБНОВЛЕНИЕ ИНТЕРФЕЙСА ---
func update_ui():
	# 1. Обновление меток уровней и стоимости
	update_branch_ui("housing", housing_label, housing_button)
	update_branch_ui("career", career_label, career_button)
	update_branch_ui("education", education_label, education_button)

# --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ ОДНОЙ ВЕТКИ ---
func update_branch_ui(branch_key: String, label: Label, button: Button):
	var data = Global.progress_data[branch_key]
	var next_level = data.level + 1
	
	# Проверка, достигнут ли максимум
	if data.level >= data.max:
		label.text = "%s: УРОВЕНЬ %d (MAX)" % [branch_key.capitalize(), data.level]
		button.text = "МАКСИМУМ"
		button.disabled = true
		return
		
	# Расчет стоимости следующего уровня
	var cost = data.unlock_costs[next_level]
	
	# Обновление текста
	label.text = "%s: Ур. %d → %d" % [branch_key.capitalize(), data.level, next_level]
	button.text = "Апгрейд ($%d)" % cost
	
	# Обновление статуса кнопки
	button.disabled = Global.money < cost

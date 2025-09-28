extends Control

# Привязка UI
@onready var income_multiplier_label = $IncomeMultiplierLabel # Метка для бонуса Престижа
@onready var passive_income_label = $PassiveIncomeLabel   # Метка текущего пассивного дохода
@onready var prestige_button = $PrestigeButton          # Кнопка Престижа
@onready var business_upgrades_container = $BusinessUpgradesContainer # VBoxContainer для апгрейдов
@onready var close_button = $CloseButton

# --- ИНИЦИАЛИЗАЦИЯ ---
func _ready():
	# 1. Подключение к глобальному сигналу: любое изменение состояния игры
	Global.game_state_changed.connect(Callable(self, "update_ui"))
	
	# 2. Подключение кнопки Престижа
	prestige_button.pressed.connect(_on_PrestigeButton_pressed)
	
	# 3. Подключение кнопки закрытия
	if is_instance_valid(close_button):
		close_button.pressed.connect(_on_CloseButton_pressed)
		
	# 4. Первая отрисовка (включает апгрейды)
	update_ui()

# --- ОБНОВЛЕНИЕ ИНТЕРФЕЙСА ---
func update_ui():
	
	# 1. Расчет бонуса престижа
	var prestige_bonus_percent = Global.prestige_points * 1.0 # 1% за каждое очко
	var total_income_multiplier = 1.0 + (prestige_bonus_percent / 100.0)

	# 2. Обновление меток
	passive_income_label.text = "Пассивный доход: $" + str(snapped(Global.get_income(), 0.01)) + " / сек"
	income_multiplier_label.text = "Бонус Престижа: x" + str(snapped(total_income_multiplier, 0.01))
	
	# 3. Обновление кнопки Престижа
	var prestige_rate: float = 10000.0 # Минимальная сумма для 1 очка
	var next_points = int(Global.total_money_earned / prestige_rate)
	
	if next_points > 0:
		prestige_button.text = "ПРЕСТИЖ (СБРОС) | Получить: %d очков" % next_points
		prestige_button.disabled = false
	else:
		var needed = prestige_rate - (Global.total_money_earned % prestige_rate)
		prestige_button.text = "ПРЕСТИЖ (Нужно еще $%d)" % int(needed)
		prestige_button.disabled = true
		
	# 4. Обновление специальных апгрейдов (Заглушка)
	# Здесь можно добавить логику для создания кнопок специальных апгрейдов
	if business_upgrades_container.get_child_count() == 0:
		var placeholder = Label.new()
		placeholder.text = "Место для будущих бизнес-апгрейдов (например, 'Рекламная кампания' или 'Налоговые льготы')."
		business_upgrades_container.add_child(placeholder)

# --- ОБРАБОТЧИК КНОПКИ ПРЕСТИЖА ---
func _on_PrestigeButton_pressed():
	if Global.prestige():
		# Global.prestige() сбросит игру и испустит сигнал game_state_changed.
		# update_ui() вызовется автоматически через этот сигнал.
		print("Престиж успешно выполнен!")
	else:
		# Добавить звуковой сигнал ошибки
		print("Невозможно выполнить Престиж.")

# --- ЗАКРЫТИЕ ОКНА ---
func _on_CloseButton_pressed():
	queue_free()

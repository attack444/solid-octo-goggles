extends Control

@onready var name_label = $HBoxContainer/NameLabel
@onready var level_label = $HBoxContainer/LevelLabel
@onready var cost_label = $HBoxContainer/CostLabel
@onready var buy_button = $HBoxContainer/BuyButton

var current_key: String = ""

func initialize(key: String):
	current_key = key
	update_ui()

func update_ui():
	# Проверка: есть ли вообще такой актив в Global
	if not Global.assets_data.has(current_key):
		queue_free() # Если нет — удаляем карточку, она не нужна
		return
	
	var data = Global.assets_data[current_key]
	
	# Обновляем текст
	name_label.text = data["name"]
	level_label.text = "Ур." + str(data.level)
	cost_label.text = "$" + str(int(data.current_cost))
	
	# Логика кнопки
	if data.level > 0:
		buy_button.text = "Куплено"
		buy_button.disabled = true
	else:
		buy_button.text = "Купить"
		buy_button.disabled = false

# Этот метод сработает благодаря connection в .tscn
func _on_BuyButton_pressed():
	if Global.buy_asset(current_key):
		# Покупка прошла: Global сам кинет сигнал game_state_changed,
		# и update_ui() вызовется автоматически через подписку в _ready()
		pass
	else:
		# Опционально: можно добавить мигание кнопки или звук «не хватает денег»
		print("Не хватает денег на покупку: ", current_key)

func _ready():
	# Подписываемся на изменения, чтобы карточка сама обновляла цену и статус
	Global.game_state_changed.connect(update_ui)
	
	# Если карточка создалась, а данные уже были изменены (редкий кейс),
	# можно вызвать update_ui один раз сразу, но initialize() это уже делает при создании

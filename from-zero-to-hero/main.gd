extends Node2D

# --- ГЛОБАЛЬНЫЕ ССЫЛКИ ---
var global: Node = get_node_or_null("/root/Global") # Проверь имя твоего синглтон-узла в Project Settings

# --- ПЕРЕМЕННЫЕ UI (будут заполнены при старте) ---
var money_label: Label = null
var health_label: Label = null
var happiness_label: Label = null
var income_label: Label = null

var shop_button: Button = null
var clicker_button: TextureButton = null

var windows_container: Control = null # Сюда будем добавлять окна (магазин, события)

# --- ТАЙМЕРЫ ---
var income_timer: Timer = null
var autosave_timer: Timer = null
var event_timer: Timer = null

func _ready():
	# 1. Находим все узлы по имени (не важно, где они лежат)
	money_label = find_node_by_name("MoneyLabel")
	health_label = find_node_by_name("HealthLabel")
	happiness_label = find_node_by_name("HappinessLabel")
	income_label = find_node_by_name("IncomeLabel")

	shop_button = find_node_by_name("ShopButton")
	clicker_button = find_node_by_name("ClickerButton") as TextureButton

	windows_container = find_node_by_name("WindowsContainer")

	income_timer = find_node_by_name("IncomeTimer") as Timer
	autosave_timer = find_node_by_name("AutosaveTimer") as Timer
	event_timer = find_node_by_name("EventTimer") as Timer

	# 2. Подключаем сигналы (если кнопки нашлись)
	if clicker_button:
		clicker_button.pressed.connect(_on_ClickerButton_pressed)
	
	if shop_button:
		shop_button.pressed.connect(_on_ShopButton_pressed)

	# 3. Запускаем таймеры (если нашлись)
	if income_timer:
		income_timer.start()
		income_timer.timeout.connect(_on_IncomeTimer_timeout)
	
	if autosave_timer:
		autosave_timer.start()
		autosave_timer.timeout.connect(_on_AutosaveTimer_timeout)
	
	if event_timer:
		event_timer.start()
		event_timer.timeout.connect(_on_EventTimer_timeout)

	# 4. Обновляем UI при старте
	update_ui()

	# Подписываемся на глобальные изменения
	if global:
		global.game_state_changed.connect(update_ui)
		# Если есть логика событий
		global.random_event_triggered.connect(_on_random_event_triggered)

func find_node_by_name(target_name: String) -> Node:
	"""
	Рекурсивно ищет узел по имени во всей сцене.
	Это избавляет от необходимости перестраивать дерево сцены.
	"""
	return get_tree().get_first_node_in_group(target_name) or _search_node(get_tree().root, target_name)

func _search_node(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for child in node.get_children():
		var found = _search_node(child, name)
		if found:
			return found
	return null

# --- ОБНОВЛЕНИЕ UI ---
func update_ui():
	if not global:
		return

	if money_label:
		money_label.text = "Деньги: " + str(global.money)
	if health_label:
		health_label.text = "Здоровье: " + str(int(global.health))
	if happiness_label:
		happiness_label.text = "Счастье: " + str(int(global.happiness))
	if income_label:
		income_label.text = "Доход/сек: " + str(global.get_income())

# --- ЛОГИКА КНОПОК ---
func _on_ClickerButton_pressed():
	if global:
		global.money += 1.0
		global.total_money_earned += 1.0
		global.emit_signal("game_state_changed")

func _on_ShopButton_pressed():
	# Тут логика открытия магазина (инстанцирование сцены магазина)
	# Пример:
	# var shop_scene = preload("res://Shop.tscn")
	# var new_shop = shop_scene.instantiate()
	# if windows_container:
	#     windows_container.add_child(new_shop)
	pass

# --- ЛОГИКА ТАЙМЕРОВ ---
func _on_IncomeTimer_timeout():
	if global:
		global.money += global.get_income()
		global.total_money_earned += global.get_income()
		global.emit_signal("game_state_changed")

func _on_AutosaveTimer_timeout():
	if global:
		global.save_game()

func _on_EventTimer_timeout():
	if global:
		global.trigger_random_event()

# --- ОБРАБОТКА СОБЫТИЙ ---
func _on_random_event_triggered(event_data: Dictionary):
	# Логика показа окна события
	# Например: инстанцируем EventWindow.tscn и добавляем в windows_container
	pass

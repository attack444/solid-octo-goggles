extends Node2D

# --- 1. ПРЕДЗАГРУЗКА И КОНСТАНТЫ ---
const FLOATING_TEXT_SCENE = preload("res://FloatingText.tscn")
const SHOP_SCENE = preload("res://Shop.tscn")
const EVENT_WINDOW_SCENE = preload("res://EventWindow.tscn") # Окно событий
const BASE_CLICK_AMOUNT: float = 1.0

# --- 2. ПРИВЯЗКА УЗЛОВ (Проверьте, что имена узлов в сцене точны!) ---
@onready var clicker_button = $ClickerButton  
@onready var shop_button = $CanvasLayer/HUD/Buttons/ShopButton        
@onready var prestige_button = $CanvasLayer/HUD/Buttons/PrestigeButton
# Добавьте привязки для всех кнопок перехода на экраны
@onready var progress_button = $CanvasLayer/HUD/Buttons/ProgressButton
@onready var events_button = $CanvasLayer/HUD/Buttons/EventsButton
@onready var inventory_button = $CanvasLayer/HUD/Buttons/InventoryButton
@onready var career_button = $CanvasLayer/HUD/Buttons/CareerButton
@onready var business_button = $CanvasLayer/HUD/Buttons/BusinessButton
@onready var entertainment_button = $CanvasLayer/HUD/Buttons/EntertainmentButton

@onready var income_timer = $Timers/IncomeTimer     
@onready var autosave_timer = $Timers/AutosaveTimer 
@onready var event_timer = $Timers/EventTimer        

@onready var audio_player = $AudioPlayer      
@onready var tutorial_panel = $TutorialPanel # Предполагается, что панель туториала - дочерний узел
@onready var tutorial_label = $TutorialPanel/TutorialLabel

# --- ПРИВЯЗКА МЕТОК (HUD) ---
@onready var money_label = $CanvasLayer/HUD/Labels/MoneyLabel
@onready var health_label = $CanvasLayer/HUD/Labels/HealthLabel
@onready var happiness_label = $CanvasLayer/HUD/Labels/HappinessLabel
@onready var income_label = $CanvasLayer/HUD/Labels/IncomeLabel
# ... добавьте achieve_label, если нужно

# --- ТУТОРИАЛ ---
var tutorial_steps: Array = [
	"Нажми на кнопку, чтобы получить деньги.", # Шаг 0
	"Открой Магазин.",                         # Шаг 1
	"Купи актив.",                             # Шаг 2
	"Следи за здоровьем и счастьем!"          # Шаг 3
]
var current_step: int = 0

# --- 3. ФУНКЦИИ ЖИЗНЕННОГО ЦИКЛА И ПОДКЛЮЧЕНИЯ ---

func _ready():
	# Подключение Таймеров
	income_timer.timeout.connect(_on_IncomeTimer_timeout)
	autosave_timer.timeout.connect(Global.save_game) # Автосохранение
	event_timer.timeout.connect(Global.trigger_random_event) # Запуск событий
	
	# Подключение к Глобальным Сигналам
	Global.game_state_changed.connect(Callable(self, "update_ui"))
	Global.random_event_triggered.connect(Callable(self, "_on_random_event_triggered"))
	
	# Подключение Кнопок (Пример для ShopButton)
	shop_button.pressed.connect(_on_ShopButton_pressed)
	clicker_button.pressed.connect(_on_ClickerButton_pressed)
	# ... Подключите все остальные кнопки: prestige_button.pressed.connect(...)
	
	Global.load_game()
	update_ui()
	
	# Запуск туториала
	if Global.total_money_earned == 0.0:
		show_tutorial()

# --- 4. ОБРАБОТЧИКИ КНОПОК ---

func _on_ClickerButton_pressed():
	Global.money += BASE_CLICK_AMOUNT
	Global.total_money_earned += BASE_CLICK_AMOUNT
	
	spawn_floating_text("+$" + str(int(BASE_CLICK_AMOUNT)), clicker_button.global_position)
	
	# Прогресс туториала: Шаг 0 -> Шаг 1
	if current_step == 0 and Global.total_money_earned > 0.0:
		next_step()
		
	Global.emit_signal("game_state_changed") # Обновить UI

func _on_ShopButton_pressed():
	var shop = SHOP_SCENE.instantiate()
	$WindowsContainer.add_child(shop) # Добавить в контейнер для окон
	
	# Прогресс туториала: Шаг 1 -> Шаг 2
	if current_step == 1:
		next_step()

# --- 5. ОБРАБОТЧИКИ ТАЙМЕРОВ И СОБЫТИЙ ---

func _on_IncomeTimer_timeout():
	Global.money += Global.get_income()
	
	# Начисление штрафов здоровья/счастья со временем
	Global.health = max(0.0, Global.health - 0.05)
	Global.happiness = max(0.0, Global.happiness - 0.02)
	
	Global.emit_signal("game_state_changed")

func _on_random_event_triggered(event_data: Dictionary):
	var event_window = EVENT_WINDOW_SCENE.instantiate()
	$WindowsContainer.add_child(event_window)
	event_window.initialize(event_data) 

# --- 6. ОБНОВЛЕНИЕ ИНТЕРФЕЙСА (UI) ---

func update_ui():
	money_label.text = "Деньги: $" + str(snapped(Global.money, 0.01))
	health_label.text = "Здоровье: " + str(int(Global.health))
	happiness_label.text = "Счастье: " + str(int(Global.happiness))
	income_label.text = "Доход/сек: $" + str(snapped(Global.get_income(), 0.01))
	# Обновление кнопок (disabled) и т.д.

# --- 7. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (ТЕКСТ И ТУТОРИАЛ) ---

func spawn_floating_text(text_to_show: String, start_pos: Vector2):
	var floating_text = FLOATING_TEXT_SCENE.instantiate()
	add_child(floating_text)
	floating_text.start(text_to_show, start_pos)

func show_tutorial():
	if current_step < tutorial_steps.size():
		tutorial_label.text = tutorial_steps[current_step]
		tutorial_panel.visible = true
	else:
		tutorial_panel.visible = false

func next_step():
	current_step += 1
	show_tutorial()

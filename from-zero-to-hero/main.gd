extends Node2D

# --- 1. ПРЕДЗАГРУЗКА И КОНСТАНТЫ ---
const FLOATING_TEXT_SCENE = preload("res://FloatingText.tscn")
const SHOP_SCENE = preload("res://Shop.tscn")
const EVENT_WINDOW_SCENE = preload("res://EventWindow.tscn")

const BASE_CLICK_AMOUNT: float = 1.0

# --- 2. ПРИВЯЗКА УЗЛОВ ---
@onready var clicker_button = $ClickerButton
# Проверь, что пути ниже ТОЧНО совпадают с именами узлов в редакторе Godot!
@onready var shop_button = $CanvasLayer/HUD/Buttons/ShopButton        
@onready var prestige_button = $CanvasLayer/HUD/Buttons/PrestigeButton
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
@onready var tutorial_panel = $TutorialPanel
@onready var tutorial_label = $TutorialPanel/TutorialLabel
@onready var windows_container = $WindowsContainer # Явное имя для удобства

# --- ПРИВЯЗКА МЕТОК (HUD) ---
@onready var money_label = $CanvasLayer/HUD/Labels/MoneyLabel
@onready var health_label = $CanvasLayer/HUD/Labels/HealthLabel
@onready var happiness_label = $CanvasLayer/HUD/Labels/HappinessLabel
@onready var income_label = $CanvasLayer/HUD/Labels/IncomeLabel

# --- ТУТОРИАЛ ---
var tutorial_steps: Array = [
	"Нажми на кнопку, чтобы получить деньги.",
	"Открой Магазин.",                         
	"Купи актив.",                             
	"Следи за здоровьем и счастьем!"           
]
var current_step: int = 0

# --- 3. ФУНКЦИИ ЖИЗНЕННОГО ЦИКЛА И ПОДКЛЮЧЕНИЯ ---
func _ready():
	# 1. Подключаем таймеры
	income_timer.timeout.connect(_on_income_timer_timeout)
	autosave_timer.timeout.connect(Global.save_game)
	event_timer.timeout.connect(Global.trigger_random_event)
	
	# 2. Подключаем сигналы ГЛОБАЛЬНОГО СКРИПТА (через отдельные функции-обёртки)
	Global.game_state_changed.connect(_on_global_state_changed)
	Global.random_event_triggered.connect(_on_global_random_event_triggered)
	
	# 3. Подключаем кнопки
	clicker_button.pressed.connect(_on_clicker_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	# Здесь нужно подключить остальные кнопки, если у них есть логика
	# prestige_button.pressed.connect(...)
	# progress_button.pressed.connect(...) и т.д.
	
	# 4. Загрузка и старт
	Global.load_game()
	update_ui()
	
	# Запуск туториала
	if Global.total_money_earned == 0.0:
		show_tutorial()

# --- 4. ОБРАБОТЧИКИ СИГНАЛОВ (Обёртки для чистоты кода) ---

func _on_global_state_changed():
	update_ui()

func _on_global_random_event_triggered(event_data: Dictionary):
	_on_random_event_triggered(event_data)

# --- 5. ОБРАБОТЧИКИ КНОПОК ---

func _on_clicker_button_pressed():
	Global.money += BASE_CLICK_AMOUNT
	Global.total_money_earned += BASE_CLICK_AMOUNT
	
	spawn_floating_text("+$" + str(int(BASE_CLICK_AMOUNT)), clicker_button.global_position)
	
	if current_step == 0 and Global.total_money_earned > 0.0:
		next_step()
		
	Global.emit_signal("game_state_changed")

func _on_shop_button_pressed():
	var shop = SHOP_SCENE.instantiate()
	windows_container.add_child(shop)
	
	if current_step == 1:
		next_step()

# Сюда добавь обработчики для остальных кнопок (Prestige, Progress и т.д.)
# func _on_prestige_button_pressed(): ...

# --- 6. ОБРАБОТЧИКИ ТАЙМЕРОВ ---

func _on_income_timer_timeout():
	var income = Global.get_income()
	Global.money += income
	
	# Штрафы со временем (можно настроить коэффициенты)
	Global.health = max(0.0, Global.health - 0.1)   # Чуть быстрее
	Global.happiness = max(0.0, Global.happiness - 0.05)
	
	Global.emit_signal("game_state_changed")

# --- 7. ОБНОВЛЕНИЕ ИНТЕРФЕЙСА (UI) ---

func update_ui():
	money_label.text = "Деньги: $" + str(snapped(Global.money, 0.01))
	health_label.text = "Здоровье: " + str(int(Global.health))
	happiness_label.text = "Счастье: " + str(int(Global.happiness))
	income_label.text = "Доход/сек: $" + str(snapped(Global.get_income(), 0.01))

# --- 8. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

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

func _on_random_event_triggered(event_data: Dictionary):
	var event_window = EVENT_WINDOW_SCENE.instantiate()
	windows_container.add_child(event_window)
	if event_window.has_method("initialize"):
		event_window.initialize(event_data) 

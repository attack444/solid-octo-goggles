extends Node

# --- ГЛОБАЛЬНЫЕ СИГНАЛЫ ---
signal game_state_changed
signal random_event_triggered(event_data)

# --- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ---
var money: float = 0.0
var passive_income_per_sec: float = 0.0
var last_save_time: int = 0
var health: float = 100.0
var happiness: float = 100.0
var prestige_points: int = 0
var total_money_earned: float = 0.0

# --- ДАННЫЕ АКТИВОВ, ПРОГРЕССА И ИНВЕНТАРЯ ---
var assets_data: Dictionary = {
	"bottle_collecting": { 
		"name": "Сбор бутылок", 
		"level": 0, 
		"base_cost": 10.0, 
		"current_cost": 10.0, 
		"base_income": 0.1, 
		"original_base_income": 0.1,
		"upgrade_level": 0, 
		"base_upgrade_cost": 100.0, 
		"upgrade_cost": 100.0
	},
	"car_wash": { 
		"name": "Мойка машин", 
		"level": 0, 
		"base_cost": 50.0, 
		"current_cost": 50.0, 
		"base_income": 0.5, 
		"original_base_income": 0.5,
		"upgrade_level": 0, 
		"base_upgrade_cost": 500.0, 
		"upgrade_cost": 500.0
	}
}

var progress_data: Dictionary = {
	"housing": { "level": 0, "max": 3, "unlock_costs": [0, 100, 500, 2000] },
	"career": { "level": 0, "max": 3, "unlock_costs": [0, 200, 1000, 5000] },
	"education": { "level": 0, "max": 3, "unlock_costs": [0, 50, 300, 1500] }
}

var entertainment_data: Dictionary = {
	"cinema": { "name": "Пойти в кино", "cost": 50.0, "happiness_boost": 15.0, "cooldown": 60 },
	"park": { "name": "Прогулка в парке", "cost": 10.0, "happiness_boost": 5.0, "cooldown": 30 },
}
var entertainment_cooldowns: Dictionary = {}

var events_db: Array = [
	{ "text": "Вы нашли кошелек", "choice": ["Оставить себе", "Вернуть"], "effect": [100, 0], "stat_change": ["money", "money"] },
	{ "text": "Вы простыли", "choice": ["Пойти к врачу", "Игнорировать"], "effect": [-30, -10], "stat_change": ["health", "health"] }
]

var inventory: Dictionary = { "key_to_city": 1, "lucky_coin": 3 }

const SAVE_PATH := "user://savegame.cfg"

func _ready():
	randomize()
	load_game()

# --- ФУНКЦИИ ЛОГИКИ ---

func update_passive_income():
	var total_income = 0.0
	for key in assets_data.keys():
		var data = assets_data[key]
		total_income += data.level * data.base_income
	passive_income_per_sec = total_income

func get_income() -> float:
	var base = passive_income_per_sec
	if health < 30: base *= 0.5 
	if happiness < 30: base *= 0.7
	var prestige_bonus_multiplier = 1.0 + (float(prestige_points) * 0.01)
	return base * prestige_bonus_multiplier
	
func buy_asset(key: String) -> bool:
	var data = assets_data.get(key)
	if data and money >= data.current_cost:
		money -= data.current_cost
		data.level += 1
		data.current_cost = data.base_cost * pow(1.15, data.level)
		
		update_passive_income()
		emit_signal("game_state_changed")
		return true
	return false

func upgrade_asset(key: String) -> bool:
	var data = assets_data.get(key)
	if data and money >= data.upgrade_cost:
		money -= data.upgrade_cost
		data.upgrade_level += 1
		data.upgrade_cost *= 2.0
		data.base_income *= 1.1
		
		update_passive_income()
		emit_signal("game_state_changed")
		return true
	return false

func try_upgrade_progress(branch: String) -> bool:
	var branch_data = progress_data.get(branch)
	if not branch_data:
		push_error("Неизвестный прогресс-ветка: " + branch)
		return false
		
	var next_level = branch_data.level + 1
	if next_level <= branch_data.max:
		var cost = branch_data.unlock_costs[next_level]
		if money >= cost:
			money -= cost
			branch_data.level = next_level
			
			emit_signal("game_state_changed")
			return true
	return false

func prestige() -> bool:
	const PRESTIGE_POINT_RATE: float = 10000.0 
	var bonus = int(total_money_earned / PRESTIGE_POINT_RATE)
	
	if bonus > 0:
		prestige_points += bonus
		
		# Сброс параметров
		money = 0.0
		health = 100.0
		happiness = 100.0
		total_money_earned = 0.0
		
		# Сброс активов к базовым значениям
		for key in assets_data.keys():
			var data = assets_data[key]
			data.level = 0
			data.current_cost = data.base_cost
			data.upgrade_level = 0
			data.upgrade_cost = data.base_upgrade_cost 
			# Безопасное восстановление дохода
			var base_income_to_restore = data.get("original_base_income", data.base_income)
			data.base_income = base_income_to_restore
			
		for key in progress_data.keys():
			progress_data[key].level = 0
			
		inventory.clear()
		entertainment_cooldowns.clear()
		
		update_passive_income()
		save_game()
		emit_signal("game_state_changed") 
		return true
		
	return false

func trigger_random_event():
	if events_db.size() == 0:
		return
	var event = events_db[randi() % events_db.size()]
	
	# Валидация события перед отправкой в UI
	if not (event.has("text") and event.has("choice") and event.has("stat_change") and event.has("effect")):
		push_warning("Некорректное событие в базе: " + str(event))
		return
	
	emit_signal("random_event_triggered", event) 

func add_item_to_inventory(key: String, count: int = 1):
	inventory[key] = inventory.get(key, 0) + count
	emit_signal("game_state_changed") 

# --- ФУНКЦИИ СОХРАНЕНИЯ/ЗАГРУЗКИ ---

func save_game():
	var config = ConfigFile.new()
	config.load(SAVE_PATH)
	
	config["global"] = {
		"money": money,
		"passive_income_per_sec": passive_income_per_sec,
		"health": health,
		"happiness": happiness,
		"prestige_points": prestige_points,
		"total_money_earned": total_money_earned,
		"last_save_time": last_save_time,
	}
	
	config["assets"] = assets_data
	config["progress"] = progress_data
	config["inventory"] = inventory
	config["entertainment_cooldowns"] = entertainment_cooldowns
	
	var error = config.save(SAVE_PATH)
	if error != OK:
		push_error("Ошибка сохранения игры: " + str(error))

func load_game() -> bool:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		return false
	
	var global_data = config["global"]
	# Безопасные get вместо прямого доступа
	money = global_data.get("money", 0.0)
	passive_income_per_sec = global_data.get("passive_income_per_sec", 0.0)
	health = global_data.get("health", 100.0)
	happiness = global_data.get("happiness", 100.0)
	prestige_points = global_data.get("prestige_points", 0)
	total_money_earned = global_data.get("total_money_earned", 0.0)
	last_save_time = global_data.get("last_save_time", 0)
	
	assets_data = config.get("assets", {})
	progress_data = config.get("progress", {})
	inventory = config.get("inventory", {})
	entertainment_cooldowns = config.get("entertainment_cooldowns", {})
	
	update_passive_income()
	emit_signal("game_state_changed")
	return true

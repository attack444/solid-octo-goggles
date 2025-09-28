extends HBoxContainer

var asset_key: String

@onready var name_label = $NameLabel
@onready var level_label = $LevelLabel
@onready var cost_label = $CostLabel
@onready var buy_button = $BuyButton
@onready var upgrade_button = $UpgradeButton

func initialize(key: String):
	asset_key = key
	buy_button.pressed.connect(_on_BuyButton_pressed)
	upgrade_button.pressed.connect(_on_UpgradeButton_pressed)
	update_display()

func update_display():
	var data = Global.assets_data[asset_key]
	var cost_display = str(snapped(data.current_cost, 0.01))
	var upgrade_cost_display = str(snapped(data.get("upgrade_cost", 0.0), 0.01))
	
	name_label.text = data.name
	level_label.text = "Ур. " + str(data.level)
	cost_label.text = "$" + cost_display
	
	buy_button.disabled = Global.money < data.current_cost
	upgrade_button.text = "Улучшить ($" + upgrade_cost_display + ")"
	upgrade_button.disabled = Global.money < data.get("upgrade_cost", 99999999.0)

func _on_BuyButton_pressed():
	if Global.buy_asset(asset_key):
		update_display()
		# Обновление всего магазина произойдет через Global.game_state_changed

func _on_UpgradeButton_pressed():
	if Global.upgrade_asset(asset_key):
		update_display()
		# Обновление всего магазина произойдет через Global.game_state_changed

extends Control

const ASSET_ITEM_SCENE = preload("res://AssetItem.tscn")

@onready var asset_list = $AssetList 
@onready var close_button = $CloseButton 

func _ready():
	# Слушаем глобальный сигнал
	Global.game_state_changed.connect(Callable(self, "generate_asset_list"))
	
	close_button.pressed.connect(queue_free)
	
	generate_asset_list()

func generate_asset_list():
	# Очищаем контейнер от всех старых элементов
	for child in asset_list.get_children():
		child.queue_free()

	# Создаем элемент для каждого актива
	for key in Global.assets_data.keys():
		var asset_item = ASSET_ITEM_SCENE.instantiate()
		asset_list.add_child(asset_item)
		
		# Инициализируем элемент, передавая ключ актива
		asset_item.initialize(key)

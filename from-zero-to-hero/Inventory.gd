extends Control

# Привязка UI
@onready var items_container = $ItemsContainer # VBoxContainer для предметов
@onready var close_button = $CloseButton

# Константы для отображения (замените на свои пути к ресурсам)
const ICON_PATH = "res://assets/icons/" # Путь к папке с Placeholder-иконками

func _ready():
	# 1. Подключение к глобальному сигналу для обновления
	Global.game_state_changed.connect(Callable(self, "update_ui"))
	
	# 2. Подключение кнопки закрытия
	if is_instance_valid(close_button):
		close_button.pressed.connect(_on_CloseButton_pressed)
		
	# 3. Первая отрисовка
	update_ui()

# --- ОБНОВЛЕНИЕ ИНТЕРФЕЙСА (Перерисовка) ---
func update_ui():
	
	# 1. Очистка контейнера
	for child in items_container.get_children():
		child.queue_free()
		
	# 2. Создание элементов для каждого предмета
	for key in Global.inventory.keys():
		var count = Global.inventory[key]
		
		# Предметы с нулевым или отрицательным количеством не показываем
		if count <= 0:
			continue
			
		var item_node = create_inventory_item(key, count)
		items_container.add_child(item_node)

# --- Создание одного элемента инвентаря (HBoxContainer) ---
func create_inventory_item(key: String, count: int) -> HBoxContainer:
	var item_box = HBoxContainer.new()
	item_box.alignment = HBoxContainer.ALIGNMENT_BEGIN
	
	# 1. Иконка-заглушка (TextureRect)
	var icon = TextureRect.new()
	# Пытаемся загрузить иконку по имени ключа, иначе используем заглушку
	var icon_texture = load(ICON_PATH + key + ".png") 
	if icon_texture:
		icon.texture = icon_texture
	else:
		# Placeholder-иконка (Создайте простой квадрат в редакторе и сохраните как placeholder.png)
		icon.texture = load(ICON_PATH + "placeholder.png") 
	
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_box.add_child(icon)
	
	# 2. Метка с названием и количеством
	var name_label = Label.new()
	# Здесь можно использовать отдельный словарь Global.item_names, если нужно красивое имя
	name_label.text = "  %s (x%d)" % [key.capitalize(), count]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_box.add_child(name_label)
	
	return item_box

# --- ФУНКЦИЯ ЗАКРЫТИЯ ---
func _on_CloseButton_pressed():
	queue_free()

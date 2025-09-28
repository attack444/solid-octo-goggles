# HUD.gd (прикреплен к CanvasLayer)
extends CanvasLayer

# Привязываем узлы к скрипту
@onready var money_label = $VBoxContainer/MoneyLabel 
@onready var income_label = $VBoxContainer/IncomeLabel

func _process(_delta):
	# Эта функция будет обновлять текст каждый кадр
	var formatted_money = str(snapped(Global.money, 0.01))
	money_label.text = "Деньги: $" + formatted_money
	
	var formatted_income = str(snapped(Global.passive_income_per_sec, 0.01))
	income_label.text = "Доход/сек: $" + formatted_income

extends Control

@onready var clawz = $CenterMargin/VBoxContainer/Clawz
@onready var block = $CenterMargin/VBoxContainer/Block

@onready var claws_bar = $CenterMargin/VBoxContainer/Clawz/ClawsBar
@onready var block_bar = $CenterMargin/VBoxContainer/Block/BlockBar

@onready var ult_box = $CenterMargin/UltBox
@onready var ult_label = $CenterMargin/UltBox/MarginContainer/UltLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	hide_claws()
	hide_block()
	hide_ult()
	
	HUD.deplete_claws.connect(deplete_claws)
	HUD.activate_claws.connect(show_claws)
	HUD.deactivate_claws.connect(hide_claws)
	
	HUD.deplete_block.connect(deplete_block)
	HUD.activate_block.connect(show_block)
	HUD.deactivate_block.connect(hide_block)
	
	HUD.deplete_shard.connect(deplete_shard)
	HUD.activate_ult.connect(show_ult)
	HUD.deactivate_ult.connect(hide_ult)

func deplete_shard():
	ult_label.text = str(int(ult_label.text) - 1)

func show_ult(amount):
	hide_claws()
	hide_block()
	
	ult_box.visible = true
	ult_label.text = str(amount)

func hide_ult():
	ult_box.visible = false

func show_claws():
	clawz.visible = true
	claws_bar.value = 100
	
func hide_claws():
	clawz.visible = false

func deplete_claws(amount: int):
	claws_bar.value -= amount
	if claws_bar.value <= 0:
		hide_claws()


func show_block():
	block.visible = true
	block_bar.value = 100

func hide_block():
	block.visible = false

func deplete_block(amount: int):
	block_bar.value -= amount
	if block_bar.value <= 0:
		hide_block()

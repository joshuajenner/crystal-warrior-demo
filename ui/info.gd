extends MarginContainer

@onready var main = $VBoxContainer/Main


# Called when the node enters the scene tree for the first time.
func _ready():
	main.visible = true

func _input(event):
	if event.is_action_pressed("toggle_info"):
		main.visible = !main.visible

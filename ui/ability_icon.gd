extends MarginContainer

@onready var label = $Panel/Label
@onready var progress = $Panel/Progress
@onready var timer = $Timer

@export var letter: String
@export var ability_num: int

var gold_ring = preload("res://assets/textures/ability_ring_gold.png")
var white_ring = preload("res://assets/textures/ability_ring_white.png")

var time_max: float = 0
var is_timer_on: bool = false

var is_in_use: bool = false
var is_on_cooldown: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = letter
	HUD.cast_ability_effect.connect(display_in_use)
	HUD.set_ability_cooldown.connect(display_cooldown)



func display_cooldown(number: int, time: float):
	if number == ability_num:
		is_on_cooldown = true
		progress.texture_progress = white_ring
		time_max = time
		timer.start(time)


func display_in_use(number: int, time: float):
	if number == ability_num:
		is_in_use = true
		progress.texture_progress = gold_ring
		time_max = time
		timer.start(time)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_in_use:
		progress.value = (timer.time_left / time_max)
	if is_on_cooldown:
		progress.value = 1 - (timer.time_left / time_max)
		label.text = str(int(timer.time_left))


func _on_timer_timeout():
	progress.texture_progress = white_ring
	progress.value = 1
	is_in_use = false
	is_on_cooldown = false
	label.text = letter

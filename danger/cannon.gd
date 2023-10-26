extends Node3D

@onready var timer = $Timer
@onready var spawn = $Spawn

var fireball = preload("res://danger/fireball.tscn")

func _on_timer_timeout():
	var new_fireball = fireball.instantiate()
	spawn.add_child(new_fireball)
#	new_fireball.position = spawn.position

extends Node3D

@onready var hit_box = $HitBox
@onready var drop_spawn = $DropSpawn

var drop = preload("res://entities/crystal_drop.tscn")
var health: float = 75

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func take_damage(amount: float):
	health -= amount
	if health <= 0:
		explode()


func explode():
	var enemies = hit_box.get_overlapping_areas()
	for enemy in enemies:
		if enemy.global_position == global_position:
			enemy.get_parent().take_damage(50)
			var new_drop = drop.instantiate()
			new_drop.global_position = drop_spawn.global_position
			get_parent().add_child(new_drop)
			self.queue_free()


func _on_hit_box_area_entered(area):
	if area.is_in_group("attack"):
		pass


func _on_timer_timeout():
	self.queue_free()

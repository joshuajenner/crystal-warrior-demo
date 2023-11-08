extends Node3D

@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.start(7)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position.x += 10 * delta


func _on_timer_timeout():
	self.queue_free()


func _on_area_3d_area_entered(area):
	if area.is_in_group("block") or area.is_in_group("breakable"):
		self.queue_free()


func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		var hit_x = body.global_position.x - global_position.x
		var hit_y = body.global_position.z - global_position.z
		var hit_direction = Vector2(hit_x, hit_y)
		body.get_hit(hit_direction)
		self.queue_free()


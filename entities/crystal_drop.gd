extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_falling: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	var rng = RandomNumberGenerator.new()
	velocity.x = rng.randf_range(-2.0, 2.0)
	velocity.y = 4
	velocity.z = rng.randf_range(-2.0, 2.0)

func pickup():
	self.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_on_floor():
		move_and_slide()
	if is_falling:
		velocity.y -= gravity * delta

func _on_timer_timeout():
	is_falling = false

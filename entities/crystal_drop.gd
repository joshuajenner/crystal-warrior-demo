extends CharacterBody3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var direction: Vector2


# Called when the node enters the scene tree for the first time.
func _ready():
	var rng = RandomNumberGenerator.new()
	velocity.x = rng.randf_range(-2.0, 2.0)
	velocity.y = 4
	velocity.z = rng.randf_range(-2.0, 2.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
		move_and_slide()

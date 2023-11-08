extends CharacterBody3D

var speed = 30
@export var direction: Vector3
@onready var csg_sphere_3d = $CSGSphere3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()


func rotate_mesh(new_direction: Vector3):
	csg_sphere_3d.look_at(new_direction)


func _on_timer_timeout():
	self.queue_free()


func _on_area_3d_area_entered(area):
	if area.is_in_group("enemy") or area.is_in_group("breakable"):
		area.get_parent().take_damage(40)
		self.queue_free()

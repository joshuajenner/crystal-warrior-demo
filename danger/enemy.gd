extends Node3D

@onready var label_3d = $Label3D
@onready var respawn_timer = $RespawnTimer
@onready var csg_mesh_3d = $CSGMesh3D
@onready var collision_shape_3d = $Area/CollisionShape3D
@onready var area = $Area

var health: float = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 100
	label_3d.text = str(health)
	csg_mesh_3d.use_collision = true
	collision_shape_3d.disabled = false
	area.monitorable = true
	area.monitoring = true

func take_damage(damage_amount: float):
	health -= damage_amount
	label_3d.text = str(health)
	if health <= 0:
		despawn()

func despawn():
	respawn_timer.start(4)
	self.visible = false
	csg_mesh_3d.use_collision = false
	collision_shape_3d.disabled = true
	area.monitorable = false
	area.monitoring = false

func _on_respawn_timer_timeout():
	self.visible = true
	_ready()

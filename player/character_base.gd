extends CharacterBody3D

@onready var camera_mount = $"Camera Mount"
@onready var animation_player = $Visual/YBot/AnimationPlayer
@onready var visual = $Visual

@onready var punch_timer = $Timers/PunchTimer
@onready var combo_timer = $Timers/ComboTimer


const SPEED = 2.7
const JUMP_VELOCITY = 4.5

var sens_horizontal = 0.5
var sens_vertical = 0.5

enum STATE {IDLE, MOVING, JUMPING, ATTACK, ULTIMATE}
enum COMBO {NONE, FIRST, SECOND}

@export var action: STATE = STATE.IDLE
var combo_state: COMBO = COMBO.NONE
var combo_timeout: float = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	action = STATE.IDLE
	animation_player.play("idle")
	animation_player.speed_scale = 1.1


func _input(event):
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
			visual.rotate_y(deg_to_rad(event.relative.x * sens_horizontal))
			camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_vertical))
	
	if event.is_action("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action("attack"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func throw_punch():
	if can_throw_punch():
		action = STATE.ATTACK
		throw_punch_from_combo()
		combo_timer.stop()
		punch_timer.start(0.9)


func can_throw_punch() -> bool:
	if action == STATE.IDLE:
		return true
	if action == STATE.MOVING:
		return true
		
	return false


func throw_punch_from_combo():
	match combo_state:
		COMBO.NONE:
			animation_player.play("punch_left")
			combo_state = COMBO.FIRST
		COMBO.FIRST:
			animation_player.play("punch_right")
			combo_state = COMBO.SECOND
		COMBO.SECOND:
			animation_player.play("punch_left")
			combo_state = COMBO.NONE


func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("attack"):
		throw_punch()
	
	if action == STATE.MOVING or action == STATE.IDLE:
		if direction:
			action = STATE.MOVING
			animation_player.play("walk_forward")
			
			visual.look_at(position + direction)
			
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			action = STATE.IDLE
			animation_player.play("idle")
			
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		
		move_and_slide()


func _on_punch_timer_timeout():
	action = STATE.IDLE
	combo_timer.start(combo_timeout)

func _on_combo_timer_timeout():
	combo_state = COMBO.NONE


func _on_animation_player_animation_finished(anim_name):
	action = STATE.IDLE

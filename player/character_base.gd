extends CharacterBody3D

@onready var camera_mount = $"Camera Mount"
@onready var animation_player = $Visual/YBot/AnimationPlayer
@onready var visual = $Visual

@onready var punch_timer = $Timers/PunchTimer
@onready var combo_timer = $Timers/ComboTimer
@onready var claw_timer = $Timers/ClawTimer
@onready var claw_cooldown_timer = $Timers/ClawCooldownTimer
@onready var block_timer = $Timers/BlockTimer
@onready var block_cooldown_timer = $Timers/BlockCooldownTimer
@onready var hit_timer = $Timers/HitTimer
@onready var pillar_cooldown_timer = $Timers/PillarCooldownTimer
@onready var ult_timer = $Timers/UltTimer
@onready var ult_cooldown_timer = $Timers/UltCooldownTimer
@onready var ult_shot_timer = $Timers/UltShotTimer

@onready var claws = $Visual/YBot/Armature/Skeleton3D/Claws
@onready var block_mesh = $Visual/YBot/Block/BlockMesh
@onready var attack_box = $Visual/YBot/AttackArea/AttackBox
@onready var block_box = $Visual/YBot/Block/BlockArea/BlockBox
@onready var shard_spawn = $ShardSpawn
@onready var pillar_spawn = $Visual/PillarSpawn
@onready var enemy_detection = $EnemyDetection
@onready var shard_detection = $ShardDetection
@onready var ult_shot_spawn = $Visual/UltShotSpawn

var pillar = preload("res://entities/crystal_pillar.tscn")
var shard_drop = preload("res://entities/crystal_drop.tscn")
var shard_shot = preload("res://entities/crystal_shot.tscn")

const SPEED = 2.7 * 2
const JUMP_VELOCITY = 5.5

var sens_horizontal = 0.5
var sens_vertical = 0.5

enum STATE {IDLE, MOVING, JUMPING, ATTACK, BLOCKING, CASTING, ULTIMATE, HIT}
enum COMBO {NONE, FIRST, SECOND}

@export var action: STATE = STATE.IDLE
var combo_state: COMBO = COMBO.NONE
var combo_timeout: float = 0.2

var claw_time: float = 9
var claw_cooldown: float = 4

var block_time: float = 5
var block_cooldown: float = 4

var hit_direction: Vector2

var base_damage: float = 25
var claw_damage: float = 50
var current_damage: float = base_damage

var claw_shard_spawned: bool = false
var claw_mana = 100
var block_shard_spawned: bool = false
var block_mana = 100

var pillar_cooldown = 6

var base_shard_amount: int = 10
var drop_shard_amount: int = 4
var ultimate_time: float = 15
var ultimate_cooldown_time: float = 10
var ultimate_shard_amount: int = 0
var ult_fire_rate: float = 0.2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	action = STATE.IDLE
	animation_player.play("idle")
	animation_player.speed_scale = 1.1
	claws.visible = false
	attack_box.disabled = true
	block_mesh.visible = false
	block_box.disabled = true


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
	
	# Crystal Claws
	if event.is_action("ability_1"):
		cast_ability_1()
	# Block
	if event.is_action_pressed("ability_2"):
		cast_ability_2()
	# Pillar
	if event.is_action_pressed("ability_3"):
		cast_ability_3()
	# A Thousand Shards
	if event.is_action_pressed("ability_4"):
		cast_ability_4()


func throw_punch():
	if can_cast_abilities() and is_on_floor():
		action = STATE.ATTACK
		throw_punch_from_combo()
		attack_box.disabled = false
		combo_timer.stop()
		punch_timer.start(0.9)


func can_cast_abilities() -> bool:
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


func cast_ability_1():
	if can_cast_abilities():
		if claw_timer.is_stopped() and claw_cooldown_timer.is_stopped():
			claws.visible = true
			claw_timer.start(claw_time)
			current_damage = claw_damage
			claw_shard_spawned = false
			claw_mana = 100
			HUD.cast_ability_effect.emit(1, claw_time)
			HUD.activate_claws.emit()

func cast_ability_2():
	if block_cooldown_timer.is_stopped() and can_cast_abilities():
		action = STATE.BLOCKING
		block_mesh.visible = true
		block_box.disabled = false
		block_shard_spawned = false
		block_mana = 100
		block_timer.start(block_time)
		animation_player.play("block")
		HUD.cast_ability_effect.emit(2, block_time)
		HUD.activate_block.emit()
	elif action == STATE.BLOCKING and not block_timer.is_stopped():
		block_timer.stop()
		_on_block_timer_timeout()

func cast_ability_3():
	if can_cast_abilities():
		if pillar_cooldown_timer.is_stopped():
			action = STATE.CASTING
			pillar_cooldown_timer.start(pillar_cooldown)
			HUD.set_ability_cooldown.emit(3, pillar_cooldown)
			animation_player.play("uppercut")
			
			var new_pillar = pillar.instantiate()
			new_pillar.global_position = get_pillar_spawn_position()
			get_parent().add_child(new_pillar)

func cast_ability_4():
	if can_cast_abilities():
		if ult_cooldown_timer.is_stopped():
			var nearby_areas = shard_detection.get_overlapping_areas()
			var shard_amount = base_shard_amount
			for area in nearby_areas:
				if area.is_in_group("drop"):
					shard_amount += drop_shard_amount
					area.get_parent().pickup()
			action = STATE.ULTIMATE
			ultimate_shard_amount = shard_amount
			_on_claw_timer_timeout()
			ult_timer.start(ultimate_time)
			HUD.activate_ult.emit(shard_amount)
			HUD.cast_ability_effect.emit(4, ultimate_time)


func throw_shard():
	if ult_shot_timer.is_stopped():
		var new_shot = shard_shot.instantiate()
		new_shot.global_position = ult_shot_spawn.global_position
		var new_dir = (ult_shot_spawn.global_position - global_position).normalized()
		new_shot.direction = new_dir
		get_parent().add_child(new_shot)
#		new_shot.rotate_mesh(new_dir)
		ultimate_shard_amount -= 1
		if ultimate_shard_amount <= 0:
			_on_ult_timer_timeout()
			return
		HUD.deplete_shard.emit()
		ult_shot_timer.start(ult_fire_rate)

func get_pillar_spawn_position() -> Vector3:
	var all_areas: Array[Area3D] = enemy_detection.get_overlapping_areas()
	for area in all_areas:
		if area.is_in_group("enemy"):
			var area_direction = (area.global_position - global_position).normalized()
			var char_dir = (pillar_spawn.global_position - global_position).normalized()
			if char_dir.dot(area_direction) >= 0.9:
				return area.global_position
		
	return pillar_spawn.global_position

func get_hit(new_direction: Vector2):
	action = STATE.HIT
	hit_direction = new_direction
	hit_timer.start(0.2)


func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		if not action == STATE.BLOCKING:
			animation_player.play("jump_idle")
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("attack"):
		if action == STATE.ULTIMATE:
			throw_shard()
		else:
			throw_punch()
	
	if action == STATE.MOVING or action == STATE.IDLE:
		if direction:
			action = STATE.MOVING
			if is_on_floor():
				animation_player.play("run_forward")
			
			visual.look_at(position + direction)
			
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			action = STATE.IDLE
			if is_on_floor():
				animation_player.play("idle")
			
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		
		move_and_slide()
		
	if action == STATE.BLOCKING:
		visual.look_at(position + direction)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		move_and_slide()
	
	if action == STATE.HIT:
		velocity.x = hit_direction.x * 10
		velocity.z = hit_direction.y * 10
		move_and_slide()
	
	if action == STATE.ULTIMATE:
		animation_player.play("fall")
		visual.look_at(position + direction)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		move_and_slide()


func _on_punch_timer_timeout():
	attack_box.disabled = true
	action = STATE.IDLE
	combo_timer.start(combo_timeout)

func _on_combo_timer_timeout():
	combo_state = COMBO.NONE


func _on_animation_player_animation_finished(anim_name):
	action = STATE.IDLE


func _on_claw_timer_timeout():
	claws.visible = false
	claw_cooldown_timer.start(claw_cooldown)
	current_damage = base_damage
	HUD.set_ability_cooldown.emit(1, claw_cooldown)
	HUD.deactivate_claws.emit()


func _on_block_timer_timeout():
	action = STATE.IDLE
	block_mesh.visible = false
	block_box.disabled = true
	block_cooldown_timer.start(block_cooldown)
	HUD.set_ability_cooldown.emit(2, block_cooldown)
	HUD.deactivate_block.emit()

func _on_hit_timer_timeout():
	action = STATE.IDLE
	hit_direction = Vector2.ZERO


func _on_block_area_area_entered(area):
	if area.is_in_group("danger"):
		block_mana -= 34
		HUD.deplete_block.emit(34)
		if block_mana <= 0 and not block_shard_spawned:
			block_shard_spawned = true
			spawn_shard()


func _on_attack_area_area_entered(area):
	if area.is_in_group("enemy"):
		area.get_parent().take_damage(current_damage)
		if not claw_timer.is_stopped():
			HUD.deplete_claws.emit(20)
			claw_mana -= 20
			if claw_mana <= 0 and not claw_shard_spawned:
				claw_shard_spawned = true
				spawn_shard()
	if area.is_in_group("breakable"):
		area.get_parent().take_damage(current_damage)


func spawn_shard():
	var new_shard = shard_drop.instantiate()
	new_shard.global_position = shard_spawn.global_position
	get_parent().add_child(new_shard)


func _on_ult_timer_timeout():
	action = STATE.IDLE
	HUD.deactivate_ult.emit()
	HUD.set_ability_cooldown.emit(4, ultimate_cooldown_time)

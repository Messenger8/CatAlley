extends CharacterBody2D

var spawn_position := Vector2(0,0)
@export var gravity := 1000.0
@export var walk_speed := 200.0
@export var run_speed := 350.0
@export var jump_force := -500.0
@export var dive_speed := 600.0
@export var dash_speed := 400.0
@export var dive_delay := 0.10 
@export var wall_slide_speed := 100.0
@export var wall_jump_push := 3000.0
@export var coyote_time := 0.15
@export var jump_buffer_time := 0.15
@export var jump_phase := 0

@onready var sprite: AnimatedSprite2D = $Sprite

var is_diving := false
var is_dashing := false
var is_wall_sliding := false
var facing_dir := 1

# timers
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

# animation state
var current_anim := ""

func _ready() -> void:
	spawn_position = global_position  # or get it from a SpawnPoint node
	# If you want to use a separate node:
	# var spawn_node = get_parent().get_node("SpawnPoint")
	# spawn_position = spawn_node.global_position

func play_anim(name: String, force: bool = false) -> void:
	if not force and current_anim == name:
		return
	current_anim = name
	sprite.play(name)


func _physics_process(delta: float) -> void:
		# Always start from neutral pose this frame
	sprite.position.x = 0
	sprite.rotation_degrees = 0
	# --- timers ---
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	# --- gravity ---
	if not is_on_floor() and not is_diving:
		velocity.y += gravity * delta

	# --- input & facing ---
	var input_dir := Input.get_axis("move_left", "move_right")

# Only change facing_dir when NOT stuck to a wall.
# This keeps the wall side consistent for the whole slide.
	if input_dir != 0 and not is_on_wall():
		facing_dir = sign(input_dir)

# Always flip using facing_dir (stable), not raw input_dir
	sprite.scale.x = facing_dir * 0.167


	# --- horizontal movement ---
	if not is_diving:
		_handle_horizontal_movement(input_dir)

	# --- jump buffering ---
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# perform jump if buffered + allowed (coyote)
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		jump_phase = 1 - jump_phase  # flip state on jump
		play_anim("jump", true)


	
	is_wall_sliding = false
	# --- wall slide + wall jump ---
	if not is_on_floor() and is_on_wall() and input_dir == facing_dir and velocity.y > 0.0:
		is_wall_sliding = true
		velocity.y = min(velocity.y, wall_slide_speed)
		if facing_dir == 1:
			sprite.rotation_degrees = 270
			sprite.position.x = 39
		else:
			sprite.position.x = -39
			sprite.rotation_degrees = 90
		play_anim("walking", true)

		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
			velocity.x = -facing_dir * wall_jump_push
			jump_phase = 1 - jump_phase
			play_anim("jump", true)


	# --- dive ---
	if Input.is_action_just_pressed("dash") and not is_on_floor() and not is_diving and not is_on_wall():
		is_diving = true
		await get_tree().create_timer(dive_delay).timeout
		velocity = Vector2(facing_dir * dive_speed, dive_speed)
		# if you have a dive anim, you can also force it here:
		# play_anim("dive", true)
	elif Input.is_action_just_pressed("dash"):
		# grounded attack, if you add one later
		pass

	# --- air dash (your second jump) ---da
	if Input.is_action_just_pressed("jump") and not is_dashing and not is_on_floor() and not is_on_wall():
		is_dashing = true
		is_diving = false
		jump_phase = 1 - jump_phase
		play_anim("jump", true)
		await get_tree().create_timer(0.05).timeout
		velocity = Vector2(facing_dir * dash_speed, -dash_speed)
	# if you later want a separate dash anim, swap to "dash" here

	# --- reset states ---
	if is_diving and (is_on_floor() or is_on_wall()):
		is_diving = false
	if is_dashing and is_on_floor():
		is_dashing = false
		velocity.y = 0.0
	# --- move ---
	move_and_slide()

	# --- animation state update AFTER movement ---
	_update_animation(input_dir)



func _handle_horizontal_movement(input_dir: float) -> void:
	if input_dir == 0.0:
		if not is_diving:
			velocity.x = lerp(velocity.x, 0.0, 0.2)
		return

	var target_speed := walk_speed
	
	if Input.is_action_pressed("dash"):
		target_speed = run_speed
	else:
		target_speed = walk_speed

	velocity.x = lerp(velocity.x, input_dir * target_speed, 0.2)


func _update_animation(input_dir: float) -> void:
	# priority: special states first
	if is_wall_sliding:
		play_anim("walking")
	
	elif is_diving:
		play_anim("dive")
		return

	elif is_dashing:
		play_anim("jump", true)
		return
	# airborne
	if not is_on_floor():
		if velocity.y < 0.0:
			# going up: keep jump anim (it was forced when jump started)
			play_anim("jump")
		else:
			# falling: use fall anim if you have one, or reuse jump
			play_anim("fall")  # or "jump" if no separate fall anim
		return

	# grounded movement
	if abs(velocity.x) > 10.0:
		if Input.is_action_pressed("dash"):
			play_anim("running")
		else:
			play_anim("walking")
	else:
		play_anim("idle")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			
func respawn() -> void:
	global_position = spawn_position

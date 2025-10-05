extends CharacterBody2D

@export var gravity := 1000.0
@export var walk_speed := 250.0
@export var run_speed := 350.0
@export var jump_force := -500.0
@export var dive_speed := 600.0
@export var dash_speed := 400.0
@export var dive_delay := 0.10 
@export var wall_slide_speed := 100.0
@export var wall_jump_push := 300.0
@export var coyote_time := 0.15
@export var jump_buffer_time := 0.15

var is_diving := false
var is_dashing := false
var facing_dir := 1

# timers
var coyote_timer := 0.0
var jump_buffer_timer := 0.0

func _physics_process(delta: float) -> void:
	# update timers
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Gravity (unless diving or wall sliding)
	if not is_on_floor() and not is_diving:
		velocity.y += gravity * delta

	# Input direction
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0:
		facing_dir = sign(input_dir)

	# Walking / Running (your existing movement)
	if not is_diving:
		_handle_horizontal_movement(input_dir)

	# Jump buffering (store input)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	# Perform jump if buffered + allowed
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = jump_force
		jump_buffer_timer = 0
		coyote_timer = 0

	# Wall slide
	if not is_on_floor() and is_on_wall() and input_dir == facing_dir and velocity.y > 0:
		velocity.y = min(velocity.y, wall_slide_speed)

		# Wall jump
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
			velocity.x = -facing_dir * wall_jump_push

	# Dive
	if Input.is_action_just_pressed("dash") and not is_on_floor() and not is_diving and not is_on_wall():
		is_diving = true
		await get_tree().create_timer(dive_delay).timeout
		velocity = Vector2(facing_dir * dive_speed, dive_speed)
		print("attack")
	elif Input.is_action_just_pressed("dash"):
		print("attack")

	# Air dash (your mechanic, renamed slightly for clarity)
	if Input.is_action_just_pressed("jump") and not is_dashing and not is_on_floor() and not is_on_wall():
		is_dashing = true
		is_diving = false
		await get_tree().create_timer(.05).timeout
		velocity = Vector2(facing_dir * dash_speed, -dash_speed)

	# Reset states
	if is_diving and is_on_floor() or is_on_wall():
		is_diving = false
	if is_dashing and is_on_floor():
		is_dashing = false
		velocity.y = 0

	move_and_slide()


func _handle_horizontal_movement(input_dir: float) -> void:
	if input_dir == 0:
		if not is_diving:
			velocity.x = 0
		return

	var target_speed = walk_speed
	if Input.is_action_pressed("dash"):
		target_speed = run_speed

	velocity.x = lerp(velocity.x, input_dir * target_speed, 0.2)

func _input(event):
	if event.is_action_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

extends CharacterBody2D

@export var gravity := 1000.0
@export var walk_speed := 250.0
@export var run_speed := 350.0
@export var jump_force := -500.0
@export var dive_speed := 600.0   # fixed diagonal dive speed
@export var dash_speed := 400.0
@export var dive_delay := 0.10 

var is_diving := false
var is_dashing := false
var facing_dir := 1  # 1 = right, -1 = left

func _physics_process(delta: float) -> void:
	# Gravity (only if not diving)
	if not is_on_floor() and not is_diving:
		velocity.y += gravity * delta

	# Walking
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0:
		facing_dir = sign(input_dir)
		if not is_diving:
			if Input.is_action_pressed("dash"):
				if is_on_floor():
					if input_dir < 0:
						if velocity.x > -run_speed:
							velocity.x = -run_speed
						if velocity.x < -run_speed:
							velocity.x += 10
					elif input_dir > 0:
						if velocity.x < run_speed:
							velocity.x = run_speed
						if velocity.x > run_speed:
							velocity.x -= 10
				else:
					if input_dir < 0:
						if velocity.x > -run_speed:
							velocity.x = -run_speed
						if velocity.x < -run_speed:
							velocity.x += 3
					elif input_dir > 0:
						if velocity.x < run_speed:
							velocity.x = run_speed
						if velocity.x > run_speed:
							velocity.x -= 3
			else:
				if is_on_floor():
					if input_dir < 0:
						if velocity.x > -walk_speed:
							velocity.x = -walk_speed
						if velocity.x < -walk_speed:
							velocity.x += 10
					elif input_dir > 0:
						if velocity.x < walk_speed:
							velocity.x = walk_speed
						if velocity.x > walk_speed:
							velocity.x -= 10
				else:
					if input_dir < 0:
						if velocity.x > -walk_speed:
							velocity.x = -walk_speed
						if velocity.x < -walk_speed:
							velocity.x += 3
					elif input_dir > 0:
						if velocity.x < walk_speed:
							velocity.x = walk_speed
						if velocity.x > walk_speed:
							velocity.x -= 3
	elif not is_diving:
		velocity.x = 0

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# Start dive (only in air, not already diving)
	if Input.is_action_just_pressed("dash") and not is_on_floor() and not is_diving:
		is_diving = true
		await get_tree().create_timer(dive_delay).timeout
		velocity = Vector2(facing_dir * dive_speed, dive_speed) # down-forward
		print("attacking")
	elif Input.is_action_just_pressed("dash"):
		print("attacking")

	#dash
	if Input.is_action_just_pressed("jump") and not is_dashing and not is_on_floor():
		is_dashing = true
		is_diving = false
		velocity = Vector2(0,0)
		await get_tree().create_timer(.05).timeout
		velocity = Vector2(facing_dir * dash_speed, -dash_speed)
	# End dive on landing
	if is_diving and is_on_floor():
		is_diving = false
	if is_dashing and is_on_floor():
		is_dashing = false
		# Momentum preserved — don't reset velocity.x
		# Optionally reduce y velocity if too strong
		velocity.y = 0  

	move_and_slide()

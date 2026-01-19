extends Camera2D

@export var target: Node2D                   # Assign your Player
var target_zoom: Vector2 = Vector2(1, 1)
var target_offset: Vector2 = Vector2.ZERO
var smooth_speed: float = 5.0

func _ready() -> void:
	$AudioStreamPlayer2D.stream.loop = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	
	# Smooth follow the player
	global_position = global_position.lerp(target.global_position, delta * smooth_speed)
	
	# Smooth zoom and offset
	zoom = zoom.lerp(target_zoom, delta * smooth_speed)
	offset = offset.lerp(target_offset, delta * smooth_speed)

# Called by CameraZones when entered
func set_zone(new_zoom: Vector2, new_offset: Vector2, new_speed: float) -> void:
	target_zoom = new_zoom
	target_offset = new_offset
	smooth_speed = new_speed

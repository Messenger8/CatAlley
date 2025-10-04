extends Area2D

@export var zoom: Vector2 = Vector2(1, 1)         # zoom in/out
@export var offset: Vector2 = Vector2.ZERO        # lead camera forward/back
@export var smooth_speed: float = 2.0             # transition speed

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):  # make sure your Player is in "player" group
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("set_zone"):
			cam.set_zone(zoom, offset, smooth_speed)

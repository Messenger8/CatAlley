extends Node2D

# 0 = solid on even jumps, 1 = solid on odd jumps
@export var required_phase := 0

@onready var sprite : AnimatedSprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var solid_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D

func _physics_process(delta: float) -> void:
	var should_be_solid := false

	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			# If the player's current jump_phase matches what we need,
			# this platform is solid for them
			if body.jump_phase == required_phase:
				should_be_solid = true
				break

	solid_shape.disabled = not should_be_solid
	if solid_shape.disabled:
		#CHANGE TO SPRITE FRAMES
		sprite.modulate = Color(0.061, 0.061, 0.061)
		
	else:
		sprite.modulate = Color(1, 1, 1)

extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var planet_clicked = false

signal planet_clicked_signal

func _ready() -> void:
	# Make sure it's pickable
	input_pickable = true
	
	# Randomize position within viewport bounds
	var viewport_size = get_viewport_rect().size
	var margin = 100  # Keep away from edges
	global_position = Vector2(
		randf_range(margin, viewport_size.x - margin),
		randf_range(margin, viewport_size.y - margin)
	)
	
	# Connect input signal
	input_event.connect(_on_input_event)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not planet_clicked:
			planet_clicked = true
			print("Planet clicked!")
			planet_clicked_signal.emit()

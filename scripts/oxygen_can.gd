extends Node2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D  # Your existing DetectionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var home_global_position: Vector2
var original_scale: Vector2  # Store the original scale

var in_oxygen_interface := false
var drain_rate := 15 # oxygen
var oxygen_count = 50
var max_oxygen_count = 50

func _ready() -> void:
	add_to_group("can")
	
	# Store original scale
	original_scale = scale
	
	$Area2D.set_pickable(true)
	# Connect mouse signals for dragging (NEW)
	detection_area.input_event.connect(_on_input_event)
	detection_area.mouse_entered.connect(_on_mouse_entered)
	detection_area.mouse_exited.connect(_on_mouse_exited)
	
	home_global_position = global_position
	
	progress_bar.max_value = oxygen_count
	progress_bar.value = oxygen_count
	progress_bar.visible = false

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("oxygen_interface"):
		in_oxygen_interface = true
		audio_stream_player_2d.play()
		animated_sprite_2d.play("pouring")

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("oxygen_interface"):
		in_oxygen_interface = false
		audio_stream_player_2d.stop()
		animated_sprite_2d.play("idle")

# NEW: Mouse input for dragging
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start dragging
			is_dragging = true
			drag_offset = global_position - get_global_mouse_position()
			animated_sprite_2d.play("idle")  # Optional: reset anim while dragging
		else:
			# End dragging
			is_dragging = false

# NEW: Hover effects (optional, makes it feel clickable)
func _on_mouse_entered() -> void:
	scale = original_scale * 1.05  # 5% bigger

func _on_mouse_exited() -> void:
	if not is_dragging:
		scale = original_scale  # Back to original

func _process(delta: float) -> void:
	if oxygen_count <= 0:
		queue_free()
		return
	
	# PASSIVE DRAIN WHILE INSIDE MACHINE
	if in_oxygen_interface:
		oxygen_count -= drain_rate * delta
		progress_bar.value = oxygen_count
	
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
		progress_bar.visible = true
	else:
		global_position = home_global_position
		if oxygen_count >= max_oxygen_count:
			progress_bar.visible = false

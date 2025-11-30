extends RigidBody2D

var dragging := false
var drag_offset := Vector2.ZERO
var target_position := Vector2.ZERO
@onready var detection_area: Area2D = $Area2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var sfx_finished: AudioStreamPlayer2D = $SFX_Finished

func _ready() -> void:
	print("=== SHIPMENT BLOCK READY ===")
	add_to_group("block")
	
	# CRITICAL: Set contact monitor for collision detection
	contact_monitor = true
	max_contacts_reported = 4
	if detection_area:
		detection_area.area_entered.connect(_on_dock_area_entered)
		detection_area.area_exited.connect(_on_dock_area_exited)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check if mouse is over this block
			var mouse_pos = get_global_mouse_position()
			var rect = Rect2(global_position - Vector2(61.5, 61.5), Vector2(123, 123))
			
			if rect.has_point(mouse_pos):
				print("STARTED DRAGGING BLOCK AT: ", global_position)
				dragging = true
				audio_stream_player_2d.play()
				freeze = false  # DON'T freeze - we need physics!
				drag_offset = global_position - mouse_pos
				get_viewport().set_input_as_handled()
		else:
			if dragging:
				print("STOPPED DRAGGING")
				audio_stream_player_2d.stop()
				dragging = false
				# Flick effect
				var velocity = (get_global_mouse_position() - (global_position - drag_offset)) * 15
				linear_velocity = velocity

func _physics_process(delta: float) -> void:
	if dragging:
		# Calculate target position
		target_position = get_global_mouse_position() + drag_offset
		
		# Apply strong force towards mouse - physics will handle collisions
		var direction = (target_position - global_position)
		var distance = direction.length()
		
		# Use very strong force to "snap" to mouse but let physics handle collisions
		linear_velocity = direction * 20
		
		# Dampen rotation while dragging
		angular_velocity *= 0.5
		
		# Visual feedback
		modulate = Color(1.2, 1.2, 1.2)
	else:
		modulate = Color(1, 1, 1)
		
		
func _on_dock_area_entered(area: Area2D) -> void:
	print("Area entered: ", area.name, " Groups: ", area.get_groups())
	if area.is_in_group("dock"):
		print("DOCK HIT! Adding food and destroying block")
		sfx_finished.play()
		await sfx_finished.finished
		GameManager.food_supply = min(GameManager.food_supply + 5, 50)
		GameManager.food_supply_changed.emit(GameManager.food_supply)
		queue_free()

func _on_dock_area_exited(area: Area2D) -> void:
	if area.is_in_group("dock"):
		print("Exited dock area: ", area.name)

extends Node2D

var in_area = false
var original_scale: Vector2  # Store the original scale
@onready var progress_bar = $ProgressBar  # Adjust path to your ProgressBar node
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	# Store original scale
	original_scale = scale
	
	# Connect to the appropriate cooldown signal
	GameManager.oxygen_cooldown_changed.connect(_on_cooldown_changed)
	
	# Initialize progress bar
	progress_bar.max_value = GameManager.COOLDOWN_TIME
	progress_bar.value = 0
	progress_bar.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed \
	and in_area \
	and GameManager.can_use_oxygen():
		audio_stream_player_2d.play()
		await audio_stream_player_2d.finished
		get_tree().change_scene_to_file("res://scenes/oxygen_area.tscn")

func _on_cooldown_changed(time_left: float) -> void:
	progress_bar.value = time_left
	
	# Show progress bar only during cooldown
	if time_left > 0:
		progress_bar.visible = true
		modulate = Color(0.5, 0.5, 0.5)  # Dim the button
	else:
		progress_bar.visible = false
		modulate = Color(1, 1, 1)  # Normal color

func _on_area_2d_mouse_entered() -> void:
	in_area = true
	scale = original_scale * 1.1  # 10% bigger

func _on_area_2d_mouse_exited() -> void:
	in_area = false
	scale = original_scale  # Back to original

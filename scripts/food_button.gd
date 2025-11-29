extends Node2D

var in_area = false
@onready var progress_bar = $ProgressBar  # Adjust path to your ProgressBar node

func _ready() -> void:
	# Connect to the appropriate cooldown signal
	# For shimpment button:
	GameManager.shimpment_cooldown_changed.connect(_on_cooldown_changed)
	# For oxygen button:
	# GameManager.oxygen_cooldown_changed.connect(_on_cooldown_changed)
	
	# Initialize progress bar
	progress_bar.max_value = GameManager.COOLDOWN_TIME
	progress_bar.value = 0
	progress_bar.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed \
	and in_area \
	and GameManager.can_use_shimpment():  # or can_use_oxygen() for oxygen button
		get_tree().change_scene_to_file("res://scenes/shimpment_area.tscn")

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

func _on_area_2d_mouse_exited() -> void:
	in_area = false

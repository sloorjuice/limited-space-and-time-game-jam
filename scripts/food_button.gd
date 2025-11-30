extends Node2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var in_area = false
var original_scale: Vector2  # Store the original scale
@onready var progress_bar = $ProgressBar

func _ready() -> void:
	# Store original scale
	original_scale = scale
	
	GameManager.shimpment_cooldown_changed.connect(_on_cooldown_changed)
	
	# Initialize progress bar
	progress_bar.max_value = GameManager.COOLDOWN_TIME
	progress_bar.value = 0
	progress_bar.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed \
	and in_area \
	and GameManager.can_use_shimpment():
		audio_stream_player_2d.play()
		await audio_stream_player_2d.finished
		get_tree().change_scene_to_file("res://scenes/shimpment_area.tscn")

func _on_cooldown_changed(time_left: float) -> void:
	progress_bar.value = time_left
	
	if time_left > 0:
		progress_bar.visible = true
		modulate = Color(0.5, 0.5, 0.5)
	else:
		progress_bar.visible = false
		modulate = Color(1, 1, 1)

func _on_area_2d_mouse_entered() -> void:
	in_area = true
	scale = original_scale * 1.1  # 10% bigger

func _on_area_2d_mouse_exited() -> void:
	in_area = false
	scale = original_scale  # Back to original

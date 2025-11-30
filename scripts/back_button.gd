extends Node2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_clicking = false
var in_area = false
var original_scale: Vector2  # Store the original scale

func _ready() -> void:
	# Store original scale
	original_scale = scale

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed \
	and in_area:
		# Determine which scene we're coming from and start appropriate cooldown
		var current_scene = get_tree().current_scene.scene_file_path
		if current_scene == "res://scenes/oxygen_area.tscn":
			GameManager.use_oxygen()
		elif current_scene == "res://scenes/shimpment_area.tscn":
			GameManager.use_shimpment()
		audio_stream_player_2d.play()
		await audio_stream_player_2d.finished
		
		get_tree().change_scene_to_file("res://scenes/space_shuttle.tscn")
		
func _on_area_2d_mouse_entered() -> void:
	in_area = true
	scale = original_scale * 1.1  # 10% bigger

func _on_area_2d_mouse_exited() -> void:
	in_area = false
	scale = original_scale  # Back to original

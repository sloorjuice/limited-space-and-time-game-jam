extends Node2D

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var detection_area: Area2D = $Area2D  # Make sure this is an Area2D!
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var can_in_area = false 

func _ready() -> void:
	# The oxygen_count is already stored in GameManager, no need to load it
	add_to_group("oxygen_interface")

func _process(delta: float) -> void:
	progress_bar.value = GameManager.oxygen_count
	
	if can_in_area:
		GameManager.oxygen_count += 15 * delta
	
	if GameManager.oxygen_count >= 100:
		GameManager.oxygen = min(GameManager.oxygen + 25, 50)
		GameManager.oxygen_count = 0  # Optional: reset or not

func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("can"):
		if audio_stream_player_2d.stream_paused == true:
			audio_stream_player_2d.stream_paused = false
		else:
			audio_stream_player_2d.play()
		can_in_area = true

func _on_detection_area_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("can"):
		audio_stream_player_2d.stream_paused = true
		can_in_area = false

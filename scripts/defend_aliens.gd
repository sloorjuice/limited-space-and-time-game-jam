extends Node2D
@onready var progress_bar: ProgressBar = $ProgressBar

const MISSION_TIME = 20.0  # 25 seconds mission time
var time_remaining = MISSION_TIME

func _ready() -> void:
	# Pause resource depletion
	GameManager.pause_depletion()
	print("Alien defense started - ", MISSION_TIME, " seconds remaining")
	progress_bar.max_value = MISSION_TIME
	progress_bar.value = MISSION_TIME

func _process(delta: float) -> void:
	time_remaining -= delta
	progress_bar.value = time_remaining
	
	# Debug output every 10 seconds
	if int(time_remaining) % 10 == 0 and int(time_remaining) != int(time_remaining + delta):
		print("Time remaining: ", int(time_remaining))
	
	if time_remaining <= 0:
		print("Mission complete! Returning to shuttle...")
		# Mission complete, return to space shuttle
		return_to_shuttle()

func return_to_shuttle() -> void:
	# Resume resource depletion
	GameManager.resume_depletion()
	print("Changing scene to space shuttle")
	# Change to space shuttle scene
	get_tree().change_scene_to_file("res://scenes/space_shuttle.tscn")

extends Node2D

@onready var dials_container: Node2D = $DialsContainer
@onready var planet: Area2D = $Plannet
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var instruction_label: Label = $CanvasLayer/InstructionLabel
@onready var dial_background: TextureRect = $DialBackground
@onready var plannet_background: TextureRect = $PlannetBackground
@onready var crosshair: TextureRect = $Crosshair

const MISSION_TIME = 16.0
const CROSSHAIR_X_OFFSET = 14.0   # Adjust this value to move the crosshair left/right
const CROSSHAIR_Y_OFFSET = 110.0  # Adjust this value to move the crosshair down

var time_remaining = MISSION_TIME
var aligned_dials: int = 0
var total_dials: int = 4
var phase: int = 1  # 1 = dials, 2 = planet

func _ready() -> void:
	GameManager.pause_depletion()
	planet.hide()
	crosshair.hide()
	plannet_background.hide()
	progress_bar.max_value = MISSION_TIME
	progress_bar.value = MISSION_TIME
	instruction_label.text = "Align all dials by dragging left/right!"
	
	# Debug: Print crosshair info
	print("Crosshair node: ", crosshair)
	print("Crosshair size: ", crosshair.size)
	print("Crosshair texture: ", crosshair.texture)
	
	# Connect dial signals
	for i in range(total_dials):
		var dial = dials_container.get_child(i)
		dial.dial_aligned.connect(_on_dial_aligned)
		dial.dial_misaligned.connect(_on_dial_misaligned)
	
	# Connect planet signal
	planet.planet_clicked_signal.connect(_on_planet_clicked)

func _process(delta: float) -> void:
	time_remaining -= delta
	progress_bar.value = time_remaining
	
	# Update crosshair position in planet phase
	if phase == 2:
		var mouse_pos = get_global_mouse_position()
		# Center crosshair with X and Y offset
		var offset = Vector2(
			crosshair.size.x / 2.0 - CROSSHAIR_X_OFFSET,
			crosshair.size.y / 2.0 - CROSSHAIR_Y_OFFSET
		)
		crosshair.global_position = mouse_pos - offset
		
		# Debug print every second
		if int(time_remaining) != int(time_remaining + delta):
			print("Mouse pos: ", mouse_pos)
			print("Crosshair pos: ", crosshair.global_position)
			print("Crosshair visible: ", crosshair.visible)
	
	if time_remaining <= 0:
		_fail_mission()

func _on_dial_aligned(dial_index: int) -> void:
	aligned_dials += 1
	print("Aligned dials: ", aligned_dials, "/", total_dials)
	if aligned_dials >= total_dials:
		_start_planet_phase()

func _on_dial_misaligned(dial_index: int) -> void:
	aligned_dials = max(0, aligned_dials - 1)

func _start_planet_phase() -> void:
	phase = 2
	dials_container.hide()
	planet.show()
	plannet_background.show()
	dial_background.hide()
	instruction_label.text = "Click the planet quickly!"
	
	# Show crosshair and hide mouse cursor
	crosshair.show()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	print("Planet phase started!")
	print("Crosshair should be visible now")
	print("Crosshair z_index: ", crosshair.z_index)

func _on_planet_clicked() -> void:
	print("Mission complete!")
	_return_to_shuttle()

func _fail_mission() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.trigger_game_over("navigation_failure")

func _return_to_shuttle() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.resume_depletion()
	get_tree().change_scene_to_file("res://scenes/space_shuttle.tscn")

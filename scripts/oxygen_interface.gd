extends Node2D

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var detection_area: Area2D = $Area2D  # Make sure this is an Area2D!

var oxygen_count = 0
var can_in_area = false 

func _ready() -> void:
	add_to_group("oxygen_interface")

func _process(delta: float) -> void:
	progress_bar.value = oxygen_count
	
	if can_in_area:
		oxygen_count += 15 * delta
	
	if oxygen_count >= 100:
		GameManager.oxygen = min(GameManager.oxygen + 25, 50)
		oxygen_count = 0  # Optional: reset or not

func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("can"):
		can_in_area = true

func _on_detection_area_area_exited(area: Area2D) -> void:
	if area.get_parent().is_in_group("can"):
		can_in_area = false

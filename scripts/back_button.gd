extends Node2D

var is_clicking = false
var in_area = false

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
		
		get_tree().change_scene_to_file("res://scenes/space_shuttle.tscn")
		
func _on_area_2d_mouse_entered() -> void:
	if in_area == false:
		in_area = true

func _on_area_2d_mouse_exited() -> void:
	if in_area == true:
		in_area = false

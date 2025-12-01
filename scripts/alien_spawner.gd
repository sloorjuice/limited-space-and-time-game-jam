extends Node2D

@export var alien_scene: PackedScene = preload("uid://c2gm5junwe152")
@export var spawn_rate: float = 1.2

var camera_rect: Rect2
var timer: Timer

func _ready():
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0 / spawn_rate
	timer.timeout.connect(_spawn_alien)
	timer.start()

func _update_camera_bounds():
	var camera = get_viewport().get_camera_2d()
	if camera:
		var zoom = camera.zoom
		var viewport_size = get_viewport_rect().size
		var visible_size = viewport_size / zoom
		var camera_pos = camera.get_screen_center_position()
		camera_rect = Rect2(
			camera_pos - visible_size / 2.0,
			visible_size
		)
	else:
		camera_rect = get_viewport_rect()

func _spawn_alien():
	if alien_scene == null:
		return
	
	_update_camera_bounds()
	
	var alien = alien_scene.instantiate() as Area2D
	get_parent().add_child(alien)
	
	var padding = 50.0
	var spawn_side = randi() % 4
	
	match spawn_side:
		0:  # Top
			alien.position = Vector2(
				randf_range(camera_rect.position.x - padding, camera_rect.end.x + padding),
				camera_rect.position.y - padding
			)
		1:  # Right
			alien.position = Vector2(
				camera_rect.end.x + padding,
				randf_range(camera_rect.position.y - padding, camera_rect.end.y + padding)
			)
		2:  # Bottom
			alien.position = Vector2(
				randf_range(camera_rect.position.x - padding, camera_rect.end.x + padding),
				camera_rect.end.y + padding
			)
		3:  # Left
			alien.position = Vector2(
				camera_rect.position.x - padding,
				randf_range(camera_rect.position.y - padding, camera_rect.end.y + padding)
			)

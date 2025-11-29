extends Node2D

@export var asteroid_scene: PackedScene = preload("uid://dot4prjkp5vgi")
@export var spawn_rate: float = 1.5  # Asteroids per second

var screen_size: Vector2
var timer: Timer

func _ready():
	screen_size = get_viewport_rect().size
	
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0 / spawn_rate
	timer.timeout.connect(_spawn_asteroid)
	timer.start()

func _spawn_asteroid():
	if asteroid_scene == null:
		return
	
	var asteroid = asteroid_scene.instantiate() as Area2D
	get_parent().add_child(asteroid)  # Add to main scene root
	
	# Spawn only from the right side
	var padding = 50.0
	asteroid.position = Vector2(screen_size.x + padding, randf_range(0, screen_size.y))
	
	# Move generally left, but with vertical variation
	var horizontal_speed = randf_range(-350.0, -150.0)  # Always moving left
	var vertical_speed = randf_range(-150.0, 150.0)     # Can move up or down
	asteroid.velocity = Vector2(horizontal_speed, vertical_speed)
	
	# Normalize to fixed speed range
	asteroid.velocity = asteroid.velocity.normalized() * randf_range(180.0, 320.0)

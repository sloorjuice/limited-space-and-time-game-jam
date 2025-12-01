extends Area2D

const SPEED = 600.0
const LIFETIME = 30.0  # Despawn after 3 seconds

var direction: Vector2 = Vector2.RIGHT
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	# Start a timer to auto-despawn
	var timer = Timer.new()
	timer.wait_time = LIFETIME
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_end)
	add_child(timer)
	timer.start()
	
	# Connect collision
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	
	# Despawn if off screen
	if position.x < -50 or position.x > screen_size.x + 50 or \
	   position.y < -50 or position.y > screen_size.y + 50:
		queue_free()

func _on_area_entered(area: Area2D):
	# Handle collision with enemies/asteroids
	if area.has_method("take_damage"):
		area.take_damage(1)
	queue_free()

func _on_lifetime_end():
	queue_free()

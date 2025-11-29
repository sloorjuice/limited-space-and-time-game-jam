extends Area2D

@export var textures: Array[Texture2D] = []

var velocity: Vector2 = Vector2.ZERO
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	
	# Random texture if multiple provided
	if textures.size() > 0:
		$Sprite2D.texture = textures[randi() % textures.size()]
	
	# Random scale for variety
	var scale_rand = randf_range(0.5, 1.2)  # Reduced size
	scale = Vector2(scale_rand, scale_rand)
	
	# Auto-resize collision shape
	if $CollisionShape2D.shape is CircleShape2D:
		$CollisionShape2D.shape.radius *= scale_rand
	
	# Detect player hits - use area_entered instead of body_entered
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float):
	position += velocity * delta
	
	# Despawn if way off-screen
	if (position.x < -200 or position.x > screen_size.x + 200 or
		position.y < -200 or position.y > screen_size.y + 200):
		queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group("player"):
		area.die()  # Triggers game over
		queue_free()

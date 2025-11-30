extends ParallaxLayer

@export var speed: float = 10.0  # pixels per second (tweak as needed)

func _process(delta):
	motion_offset.x -= speed * delta  # moves left (use + to go right)

extends Area2D

const SPEED = 200.0

# How much padding from the top/bottom of the screen (optional, set to 0 if you want exact edges)
const SCREEN_PADDING = 70

# Horizontal movement constraints
const MAX_RIGHT_POSITION = 150.0  # How far right the player can move
const MIN_LEFT_POSITION = 50.0    # Left boundary

var screen_size: Vector2

func _ready():
	add_to_group("player")
	# Get the visible screen size (works in both editor and exported game)
	screen_size = get_viewport_rect().size

func _physics_process(delta: float) -> void:
	# Get vertical input only (ui_up = up arrow or W, ui_down = down arrow or S)
	var vertical_direction := Input.get_axis("move_up", "move_down")
	
	# Get horizontal input (ui_left = left arrow or A, ui_right = right arrow or D)
	var horizontal_direction := Input.get_axis("ui_left", "ui_right")
	
	# Apply movement on both axes - use position instead of velocity
	position.x += horizontal_direction * SPEED * delta
	position.y += vertical_direction * SPEED * delta
	
	# Clamp vertical position to stay inside the screen (top and bottom)
	var top_limit = SCREEN_PADDING
	var bottom_limit = screen_size.y - SCREEN_PADDING
	global_position.y = clamp(global_position.y, top_limit, bottom_limit)
	
	# Clamp horizontal position to limited range
	global_position.x = clamp(global_position.x, MIN_LEFT_POSITION, MAX_RIGHT_POSITION)


func die():
	GameManager.trigger_game_over("asteroid_death")

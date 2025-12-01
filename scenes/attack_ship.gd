extends Area2D

const MAX_SPEED = 400.0
const ACCELERATION = 300.0
const DECELERATION = 200.0
const MIN_MOUSE_DISTANCE = 50.0
const ROTATION_SPEED = 10.0
const FIRE_RATE = 0.2
const ATTACK_COOLDOWN = 0.2
@onready var fire_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_light: PointLight2D = $FireLight

const SCREEN_PADDING = 70

const LASER_SCENE = preload("uid://dita2duqyo0")

var current_speed = 0.0
var camera_rect: Rect2
var can_shoot = true
var shoot_timer = 0.0
var attack_cooldown_timer = 0.0
var was_shooting

func _ready():
	add_to_group("player")
	_update_camera_bounds()

func _update_camera_bounds():
	var camera = get_viewport().get_camera_2d()
	if camera:
		var zoom = camera.zoom
		var viewport_size = get_viewport_rect().size
		# Calculate visible area in world coordinates
		var visible_size = viewport_size / zoom
		var camera_pos = camera.get_screen_center_position()
		camera_rect = Rect2(
			camera_pos - visible_size / 2.0,
			visible_size
		)
	else:
		# Fallback to viewport size if no camera
		camera_rect = get_viewport_rect()

func _physics_process(delta: float) -> void:
	_update_camera_bounds()
	
	var mouse_pos = get_global_mouse_position()
	var distance_to_mouse = global_position.distance_to(mouse_pos)
	
	if distance_to_mouse > MIN_MOUSE_DISTANCE:
		var target_angle = global_position.angle_to_point(mouse_pos)
		var current_angle = rotation
		
		var speed_factor = 1.0 - (current_speed / MAX_SPEED) * 0.5
		var adjusted_rotation_speed = ROTATION_SPEED * speed_factor
		
		rotation = lerp_angle(current_angle, target_angle, adjusted_rotation_speed * delta)
	
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	var is_mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if is_mouse_pressed and can_shoot and attack_cooldown_timer <= 0:
		shoot_laser()
		can_shoot = false
		shoot_timer = FIRE_RATE
		was_shooting = true
	
	if not is_mouse_pressed and was_shooting:
		attack_cooldown_timer = ATTACK_COOLDOWN
		was_shooting = false
	
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true
	
	var is_thrusting = Input.is_action_pressed("accelerate")
	
	if is_thrusting:
		current_speed = min(current_speed + ACCELERATION * delta, MAX_SPEED)
		if fire_animation and not fire_animation.is_playing():
			fire_animation.play()
			fire_animation.visible = true
			fire_light.visible = true
	else:
		current_speed = max(current_speed - DECELERATION * delta, 0.0)
		if fire_animation and fire_animation.is_playing():
			fire_animation.stop()
			fire_animation.visible = false
			fire_light.visible = false
	
	if current_speed > 0:
		var direction = Vector2.RIGHT.rotated(rotation)
		position += direction * current_speed * delta
	
	# Clamp to camera bounds
	var top_limit = camera_rect.position.y + SCREEN_PADDING
	var bottom_limit = camera_rect.end.y - SCREEN_PADDING
	var left_limit = camera_rect.position.x + SCREEN_PADDING
	var right_limit = camera_rect.end.x - SCREEN_PADDING
	
	global_position.x = clamp(global_position.x, left_limit, right_limit)
	global_position.y = clamp(global_position.y, top_limit, bottom_limit)

func shoot_laser():
	var laser = LASER_SCENE.instantiate()
	laser.global_position = global_position
	laser.rotation = rotation
	laser.direction = Vector2.RIGHT.rotated(rotation)
	get_parent().add_child(laser)

func die():
	GameManager.trigger_game_over("alien_death")

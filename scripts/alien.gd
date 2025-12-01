extends Area2D

@export var speed: float = 100.0
@export var health: int = 2

var player: Node2D = null
var camera_rect: Rect2

func _ready():
	area_entered.connect(_on_area_entered)
	
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

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

func _physics_process(delta: float):
	if player:
		var direction = (player.global_position - global_position).normalized()
		position += direction * speed * delta
		look_at(player.global_position)
	
	_update_camera_bounds()
	
	# Despawn if far outside camera bounds
	var despawn_padding = 400.0
	if position.x < camera_rect.position.x - despawn_padding or \
	   position.x > camera_rect.end.x + despawn_padding or \
	   position.y < camera_rect.position.y - despawn_padding or \
	   position.y > camera_rect.end.y + despawn_padding:
		queue_free()

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		queue_free()

func _on_area_entered(area: Area2D):
	if area.is_in_group("player"):
		area.die()
		queue_free()

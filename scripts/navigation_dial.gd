extends Node2D

@export var dial_index: int = 0
@onready var dial_sprite = $DialSprite
@onready var indicator = $Indicator
@onready var target_indicator = $TargetIndicator
@onready var clickable_area = $ClickableArea

var current_rotation: float = 0.0
var target_angle: float = 0.0
var is_aligned: bool = false
var is_dragging: bool = false

const ALIGNMENT_THRESHOLD = 0.15
const ROTATION_SENSITIVITY = 0.01
const DRAG_RADIUS = 200.0  # How far from center you can drag

signal dial_aligned(dial_index: int)
signal dial_misaligned(dial_index: int)

func _ready() -> void:
	print("Navigation Dial Ready! Index: ", dial_index)
	
	target_angle = randf() * TAU
	target_indicator.rotation = target_angle
	current_rotation = randf() * TAU
	dial_sprite.rotation = current_rotation

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check if click is within drag radius
			var distance = global_position.distance_to(event.position)
			if distance < DRAG_RADIUS:
				is_dragging = true
				print("Started dragging dial ", dial_index)
		else:
			if is_dragging:
				print("Stopped dragging dial ", dial_index)
			is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		print("Dragging dial ", dial_index, " with delta: ", event.relative.x)
		current_rotation += event.relative.x * ROTATION_SENSITIVITY
		
		# Normalize rotation
		current_rotation = fmod(current_rotation, TAU)
		if current_rotation < 0:
			current_rotation += TAU

func _process(delta: float) -> void:
	dial_sprite.rotation = current_rotation
	indicator.rotation = current_rotation
	
	var angle_diff = abs(angle_difference(current_rotation, target_angle))
	var was_aligned = is_aligned
	is_aligned = angle_diff < ALIGNMENT_THRESHOLD
	
	if is_aligned:
		indicator.modulate = Color.GREEN
		if not was_aligned:
			print("Dial ", dial_index, " aligned!")
			dial_aligned.emit(dial_index)
	else:
		indicator.modulate = Color.RED
		if was_aligned:
			dial_misaligned.emit(dial_index)

func angle_difference(a: float, b: float) -> float:
	var diff = b - a
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff

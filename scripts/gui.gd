extends CanvasLayer

@onready var food_supply_bar: ProgressBar = $MarginContainer/HBoxContainer/Control2/FoodSupplyBar
@onready var oxygen_bar: ProgressBar = $MarginContainer/HBoxContainer/Control/OxygenBar
@onready var survivor_count_label: Label = $MarginContainer/HBoxContainer/SuvivorCountLabel
@onready var death_screen: Control = $DeathScreen
@onready var death_message: Label = $DeathScreen/DeathMessage
@onready var warning: Control = $Warning
@onready var warning_message: Label = $Warning/WarningMessage
@onready var time_left: Label = $TimeLeft
@onready var winning: Control = $Winning

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the bar ranges once
	oxygen_bar.max_value = 50
	food_supply_bar.max_value = 50
	
	oxygen_bar.value = GameManager.oxygen
	food_supply_bar.value = GameManager.food_supply
	survivor_count_label.text = "Survivors: " + str(GameManager.survivor_count)
	
	# Connect to signals
	GameManager.oxygen_changed.connect(_on_oxygen_changed)
	GameManager.food_supply_changed.connect(_on_food_supply_changed)
	GameManager.survivor_count_changed.connect(_on_survivor_count_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.warning_started.connect(_on_warning_started)
	GameManager.warning_ended.connect(_on_warning_ended)
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.player_won.connect(_on_player_won)
	
	# Make sure screens are hidden
	death_screen.hide()
	winning.hide()
	
	# IMPORTANT: Force update warning display immediately
	_update_warning_display()


func _process(delta: float) -> void:
	# Removed - no longer needed in _process
	pass

func _update_warning_display() -> void:
	if GameManager.warning_active:
		warning_message.text = GameManager.current_warning_message
		warning.visible = true
	else:
		warning.visible = false

func _on_oxygen_changed(new_value: float) -> void:
	oxygen_bar.value = new_value

func _on_food_supply_changed(new_value: float) -> void:
	food_supply_bar.value = new_value

func _on_survivor_count_changed(new_count: int) -> void:
	survivor_count_label.text = "Survivors: " + str(new_count)
	
	# Add visual feedback for low survivor count
	if new_count <= 10:
		survivor_count_label.modulate = Color.RED
	elif new_count <= 20:
		survivor_count_label.modulate = Color.ORANGE
	else:
		survivor_count_label.modulate = Color.WHITE

func _on_game_over(message: String) -> void:
	death_message.text = message
	death_screen.show()
	get_tree().paused = true

func _on_warning_started(message: String) -> void:
	_update_warning_display()

func _on_warning_ended() -> void:
	_update_warning_display()

func _on_time_updated(time_remaining: float) -> void:
	var minutes = int(time_remaining) / 60
	var seconds = int(time_remaining) % 60
	time_left.text = "Time before landing on inhabital plannet: %dm %ds" % [minutes, seconds]

func _on_player_won() -> void:
	winning.show()
	get_tree().paused = true

extends Node

var oxygen = 50.0
var food_supply = 50.0

# Cooldown tracking
var shimpment_cooldown = 0.0
var oxygen_cooldown = 0.0
const COOLDOWN_TIME = 8.0

# Depletion pause flag
var depletion_paused = false

# Food depletion system
var food_timer = 0.0
var next_food_depletion = 0.0
const MIN_FOOD_TIME = 2.0
const MAX_FOOD_TIME = 8.0
const FOOD_DEPLETION_AMOUNT = 5.0

# Survival timer
const WIN_TIME = 300 # 1200.0  # 20 minutes in seconds (20 * 60)
var survival_time = 0.0

# Random event system
var event_timer = 0.0
const MIN_EVENT_TIME = 25.0
const MAX_EVENT_TIME = 75.0
var next_event_time = 0.0
const WARNING_TIME = 3.0
var pending_event: EventType = EventType.DEFEND_ASTEROIDS
var warning_active = false
var warning_timer = 0.0
var current_warning_message = ""  # ADD THIS LINE

enum EventType {
	DEFEND_ASTEROIDS,
}

var death_messages = {
	"food_death": "Everyone starved to death.",
	"oxygen_death": "Everyone's head exploded. There was no Oxygen.",
	"asteroid_death": "You got hit by a freaking asteroid. Everyone is smushed."
}

var event_warnings = {
	EventType.DEFEND_ASTEROIDS: "Asteroids Incoming.",
}

signal oxygen_changed(new_value: float)
signal food_supply_changed(new_value: float)
signal shimpment_cooldown_changed(time_left: float)
signal oxygen_cooldown_changed(time_left: float)
signal random_event_triggered(event_type: EventType)
signal game_over(death_message: String)
signal warning_started(warning_message: String)
signal warning_ended()
signal time_updated(time_left: float)
signal player_won()

func _ready() -> void:
	set_process(true)
	schedule_next_event()
	schedule_next_food_depletion()
func _process(delta: float) -> void:
	# Survival timer (always counting)
	survival_time += delta
	var time_remaining = WIN_TIME - survival_time
	time_updated.emit(time_remaining)
	
	# Check for win condition
	if survival_time >= WIN_TIME:
		trigger_win()
		return
	
	# Resource depletion (only if not paused)
	if not depletion_paused:
		if oxygen > 0:
			oxygen -= delta
			oxygen = max(oxygen, 0)
			oxygen_changed.emit(oxygen)
			
			if oxygen <= 0:
				trigger_game_over("oxygen_death")
		
		food_timer += delta
		if food_timer >= next_food_depletion:
			deplete_food()
			schedule_next_food_depletion()
	
	# Cooldown updates (always run)
	if shimpment_cooldown > 0:
		shimpment_cooldown -= delta
		shimpment_cooldown = max(shimpment_cooldown, 0)
		shimpment_cooldown_changed.emit(shimpment_cooldown)
	
	if oxygen_cooldown > 0:
		oxygen_cooldown -= delta
		oxygen_cooldown = max(oxygen_cooldown, 0)
		oxygen_cooldown_changed.emit(oxygen_cooldown)
	
	# Warning timer
	if warning_active:
		warning_timer -= delta
		if warning_timer <= 0:
			warning_active = false
			warning_ended.emit()
			execute_random_event()
	
	# Random event timer (only count when not paused and no warning active)
	if not depletion_paused and not warning_active:
		event_timer += delta
		if event_timer >= next_event_time:
			start_event_warning()
			schedule_next_event()

func trigger_win() -> void:
	pause_depletion()
	set_process(false)
	print("YOU WIN! Survived 20 minutes!")
	player_won.emit()

func schedule_next_food_depletion() -> void:
	food_timer = 0.0
	next_food_depletion = randf_range(MIN_FOOD_TIME, MAX_FOOD_TIME)
	print("Next food depletion in: ", next_food_depletion, " seconds")

func deplete_food() -> void:
	if food_supply > 0:
		food_supply -= FOOD_DEPLETION_AMOUNT
		food_supply = max(food_supply, 0)
		food_supply_changed.emit(food_supply)
		print("Food consumed! Remaining: ", food_supply)
		
		if food_supply <= 0:
			trigger_game_over("food_death")

func trigger_game_over(death_type: String) -> void:
	pause_depletion()
	set_process(false)
	var message = death_messages.get(death_type, "Game Over!")
	game_over.emit(message)

func schedule_next_event() -> void:
	event_timer = 0.0
	next_event_time = randf_range(MIN_EVENT_TIME, MAX_EVENT_TIME)
	print("Next event in: ", next_event_time, " seconds")

func start_event_warning() -> void:
	pending_event = EventType.DEFEND_ASTEROIDS
	warning_active = true
	warning_timer = WARNING_TIME
	current_warning_message = event_warnings.get(pending_event, "Random Event Incoming!")  # STORE IT
	print("Warning: ", current_warning_message)
	warning_started.emit(current_warning_message)

func execute_random_event() -> void:
	print("Random event triggered: ", pending_event)
	random_event_triggered.emit(pending_event)
	get_tree().change_scene_to_file("res://scenes/defend_astroids.tscn")

func pause_depletion() -> void:
	depletion_paused = true

func resume_depletion() -> void:
	depletion_paused = false

func can_use_shimpment() -> bool:
	return shimpment_cooldown <= 0

func can_use_oxygen() -> bool:
	return oxygen_cooldown <= 0

func use_shimpment() -> void:
	shimpment_cooldown = COOLDOWN_TIME

func use_oxygen() -> void:
	oxygen_cooldown = COOLDOWN_TIME

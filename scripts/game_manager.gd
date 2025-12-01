extends Node

var oxygen = 50.0
var food_supply = 50.0

var oxygen_count = 0

# Survivor system
var survivor_count = 20
const INITIAL_SURVIVORS = 20
const OXYGEN_DEATH_RATE = 3.0  # Survivors lost per second with no oxygen
const FOOD_DEATH_RATE = 1.0  # Survivors lost per second with no food

# Random event survivor costs
const ASTEROID_SURVIVOR_COST = 15
const ALIEN_SURVIVOR_COST = 15
const NAVIGATION_SURVIVOR_COST = 15

# Cooldown tracking
var shimpment_cooldown = 0.0
var oxygen_cooldown = 0.0
const COOLDOWN_TIME = 14.0

# Depletion pause flag
var depletion_paused = false
var survival_paused = false

# Grace period
const GRACE_PERIOD = 5.0
var grace_timer = GRACE_PERIOD

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
const MIN_EVENT_TIME = 25
const MAX_EVENT_TIME = 55
var next_event_time = 0.0
const WARNING_TIME = 3.0
var pending_event: EventType = EventType.DEFEND_ASTEROIDS
var warning_active = false
var warning_timer = 0.0
var current_warning_message = ""
var last_event: EventType = EventType.DEFEND_ASTEROIDS  # Track last event

# Audio players
var death_audio_player: AudioStreamPlayer
var warning_audio_player: AudioStreamPlayer
var bg_music_player: AudioStreamPlayer

# Track if audio is initialized
var audio_initialized = false

enum EventType {
	DEFEND_ASTEROIDS,
	DEFEND_ALIENS,
	CALIBRATE_NAVIGATION,
}

var death_messages = {
	"food_death": "Everyone starved to death.",
	"oxygen_death": "Everyone's head exploded. There was no Oxygen.",
	"asteroid_death": "You got hit by a freaking asteroid. Everyone is smushed.",
	"alien_death": "Aliens abducted and ate everyone. You lose.",
	"navigation_failure": "Ship drifted off course into a black hole. Everyone is spaghettified."
}

var sound_effects = {
	"death": "res://assets/foghorn-313218.mp3",
	"warning": "res://assets/siren-a-248662.mp3",
	"BGMusic": "res://assets/space-vessel-background-noise-350616.mp3.download/space-vessel-background-noise-350616.mp3"
}

var event_warnings = {
	EventType.DEFEND_ASTEROIDS: "Asteroids Incoming.",
	EventType.DEFEND_ALIENS: "Alien Attack Imminent!",
	EventType.CALIBRATE_NAVIGATION: "Navigation System Malfunction!",
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
signal survivor_count_changed(new_count: int)

func _ready() -> void:
	set_process(true)
	schedule_next_event()
	schedule_next_food_depletion()
	_initialize_audio()
	survivor_count_changed.emit(survivor_count)

func _initialize_audio() -> void:
	if audio_initialized:
		return
	
	# Setup audio players
	death_audio_player = AudioStreamPlayer.new()
	death_audio_player.stream = load(sound_effects["death"])
	death_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(death_audio_player)
	
	warning_audio_player = AudioStreamPlayer.new()
	warning_audio_player.stream = load(sound_effects["warning"])
	warning_audio_player.volume_db = -30.0
	add_child(warning_audio_player)
	
	# Setup background music
	bg_music_player = AudioStreamPlayer.new()
	bg_music_player.stream = load(sound_effects["BGMusic"])
	bg_music_player.volume_db = -9.0
	bg_music_player.autoplay = true
	add_child(bg_music_player)
	bg_music_player.finished.connect(_on_bg_music_finished)
	bg_music_player.play()
	
	audio_initialized = true

func _on_bg_music_finished() -> void:
	# Loop the background music
	if bg_music_player and bg_music_player.stream:
		bg_music_player.play()

func _process(delta: float) -> void:
	# Ensure audio is initialized
	if not audio_initialized:
		_initialize_audio()
	
	# Grace period countdown
	if grace_timer > 0:
		grace_timer -= delta
		if grace_timer <= 0:
			print("Grace period ended - resource depletion starting")
	
	# Survival timer (always counting)
	if not survival_paused:
		survival_time += delta
		var time_remaining = WIN_TIME - survival_time
		time_updated.emit(time_remaining)
		
		# Check for win condition
		if survival_time >= WIN_TIME:
			trigger_win()
			return
	
	# Resource depletion (only if not paused AND grace period is over)
	if not depletion_paused and grace_timer <= 0:
		# Oxygen depletion
		if oxygen > 0:
			oxygen -= delta
			oxygen = max(oxygen, 0)
			oxygen_changed.emit(oxygen)
		
		# Survivor death from lack of resources
		var death_rate = 0.0
		
		if oxygen <= 0:
			death_rate += OXYGEN_DEATH_RATE
		
		if food_supply <= 0:
			death_rate += FOOD_DEATH_RATE
		
		# Apply survivor deaths
		if death_rate > 0:
			kill_survivors(death_rate * delta)
		
		# Food depletion
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

func kill_survivors(amount: float) -> void:
	var survivors_to_kill = int(amount)
	if amount - survivors_to_kill > randf():  # Handle fractional deaths probabilistically
		survivors_to_kill += 1
	
	if survivors_to_kill > 0:
		survivor_count = max(0, survivor_count - survivors_to_kill)
		survivor_count_changed.emit(survivor_count)
		
		if survivor_count <= 0:
			# Determine which death message to show
			var death_type = "food_death"  # Default
			
			if oxygen <= 0 and food_supply <= 0:
				# If both are depleted, oxygen takes precedence (faster death)
				death_type = "oxygen_death"
			elif oxygen <= 0:
				death_type = "oxygen_death"
			elif food_supply <= 0:
				death_type = "food_death"
			
			trigger_game_over(death_type)

func trigger_game_over(death_type: String) -> void:
	pause_depletion()
	set_process(false)
	
	# Stop warning sound if playing
	if warning_audio_player and warning_audio_player.playing:
		warning_audio_player.stop()
	
	# Stop background music
	if bg_music_player and bg_music_player.playing:
		bg_music_player.stop()
	
	# Play death sound
	if death_audio_player:
		death_audio_player.play()
	
	var message = death_messages.get(death_type, "Game Over!")
	game_over.emit(message)

func trigger_win() -> void:
	pause_depletion()
	set_process(false)
	
	# Stop background music on win
	if bg_music_player and bg_music_player.playing:
		bg_music_player.stop()
	
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

func schedule_next_event() -> void:
	event_timer = 0.0
	next_event_time = randf_range(MIN_EVENT_TIME, MAX_EVENT_TIME)
	print("Next event in: ", next_event_time, " seconds")

func start_event_warning() -> void:
	# Choose a different event than the last one
	var available_events = [EventType.DEFEND_ASTEROIDS, EventType.DEFEND_ALIENS, EventType.CALIBRATE_NAVIGATION]
	available_events.erase(last_event)  # Remove the last event from options
	
	# If we somehow have no options (shouldn't happen with 3 events), add them back
	if available_events.is_empty():
		available_events = [EventType.DEFEND_ASTEROIDS, EventType.DEFEND_ALIENS, EventType.CALIBRATE_NAVIGATION]
	
	pending_event = available_events[randi() % available_events.size()]
	last_event = pending_event  # Update last event
	
	warning_active = true
	warning_timer = WARNING_TIME
	current_warning_message = event_warnings.get(pending_event, "Random Event Incoming!")
	print("Warning: ", current_warning_message)
	
	# Play warning sound
	if warning_audio_player:
		warning_audio_player.play()
	
	warning_started.emit(current_warning_message)

func execute_random_event() -> void:
	print("Executing event: ", pending_event)
	
	# Stop warning sound before loading the event scene
	if warning_audio_player and warning_audio_player.playing:
		warning_audio_player.stop()
	
	pause_depletion()
	
	match pending_event:
		EventType.DEFEND_ASTEROIDS:
			get_tree().change_scene_to_file("res://scenes/defend_astroids.tscn")
		EventType.DEFEND_ALIENS:
			get_tree().change_scene_to_file("res://scenes/defend_aliens.tscn")
		EventType.CALIBRATE_NAVIGATION:
			get_tree().change_scene_to_file("res://scenes/calibrate_navigation.tscn")
	
	random_event_triggered.emit(pending_event)

# New function to call when player fails an event
func fail_random_event(event_type: EventType) -> void:
	var survivors_killed = 0
	match event_type:
		EventType.DEFEND_ASTEROIDS:
			survivors_killed = ASTEROID_SURVIVOR_COST
		EventType.DEFEND_ALIENS:
			survivors_killed = ALIEN_SURVIVOR_COST
		EventType.CALIBRATE_NAVIGATION:
			survivors_killed = NAVIGATION_SURVIVOR_COST
	
	survivor_count = max(0, survivor_count - survivors_killed)
	survivor_count_changed.emit(survivor_count)
	print("Event failed! Lost ", survivors_killed, " survivors. Remaining: ", survivor_count)
	
	# Check if all survivors are dead
	if survivor_count <= 0:
		var death_type = ""
		match event_type:
			EventType.DEFEND_ASTEROIDS:
				death_type = "asteroid_death"
			EventType.DEFEND_ALIENS:
				death_type = "alien_death"
			EventType.CALIBRATE_NAVIGATION:
				death_type = "navigation_failure"
		trigger_game_over(death_type)
	else:
		# Still have survivors - return to space shuttle
		resume_depletion()
		# Use call_deferred to avoid physics callback issues
		get_tree().call_deferred("change_scene_to_file", "res://scenes/space_shuttle.tscn")

func pause_depletion() -> void:
	depletion_paused = true
	print("Resource depletion paused")

func resume_depletion() -> void:
	depletion_paused = false
	print("Resource depletion resumed")

func can_use_shimpment() -> bool:
	return shimpment_cooldown <= 0

func can_use_oxygen() -> bool:
	return oxygen_cooldown <= 0

func use_shimpment() -> void:
	shimpment_cooldown = COOLDOWN_TIME
	shimpment_cooldown_changed.emit(shimpment_cooldown)

func use_oxygen() -> void:
	oxygen_cooldown = COOLDOWN_TIME
	oxygen_cooldown_changed.emit(oxygen_cooldown)

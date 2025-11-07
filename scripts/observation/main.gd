extends Node2D

var score = 0
var Event = preload("res://scenes/event/event.tscn")
var nextScene = preload("res://scenes/results/results.tscn")
var localization = preload("res://scenes/observation/localization.tscn")

const OFFSET_MAP = [
	Vector2(960,540), #This should be dynamic
	Vector2.ZERO
]

@export_enum ("CENTER:0","CORNER:1") var SELECTED_OFFSET = 0

@export var SPEED = 0.05
@export var EVENTS_LIMIT = 10

@onready var ScoreLabel = $Score as Label
@onready var Events = $Events as Node2D
@onready var PlayerObservers = $PlayerObservers as Node2D
@onready var RotatingStarField = $RotatingStarField
@onready var SessionTimer = $SessionTimer as Timer

var target_map: Dictionary = {}
var scores: Dictionary = {}

var eventIdInc = 0



func _ready():
	randomize()

	# Initialize target map and score tracking?
	for player_data in Global.PLAYERS:
		target_map[player_data.name] = []
		scores[player_data.name] = 0

	for playerObserver in PlayerObservers.get_children().filter(func(child): return child is PlayerObserver):
		playerObserver.connect("observation_ended", _on_player_observe)

	Global.ROTATION_AXIS = OFFSET_MAP[SELECTED_OFFSET]
	RotatingStarField.initialize_with_set_values()

	Events.position = Global.ROTATION_AXIS
	SessionTimer.start()

	create_new_localization()

func _process(delta: float) -> void:
	var rotation_speed = SPEED * delta
	Events.rotate(rotation_speed)
	rotate_observing_players(rotation_speed)
	ScoreLabel.text = "Score: " + str(score)
	# TODO: Make this use the new Localization scene instead of event
	#if (len(Events.get_children()) < EVENTS_LIMIT):
		#create_new_localization()
	score = scores.values().reduce(sum, 0)


func sum(accum, number):
	return accum + number


func create_new_event():
	eventIdInc+=1
	var newEvent = Event.instantiate()

	newEvent.set("location", get_random_point())
	newEvent.set("points", randi_range(10,20))
	newEvent.set("id", eventIdInc)
	Events.add_child(newEvent)
	newEvent.connect('player_over', _on_event_player_over)
	newEvent.connect('player_exited', _on_player_exited)


func create_new_localization():
	eventIdInc+=1
	var newLocalization = localization.instantiate()
	newLocalization.set("location", get_random_point())
	newLocalization.eventId = eventIdInc
	Events.add_child(newLocalization)
	newLocalization.connect('player_over', _on_event_player_over)
	newLocalization.connect('player_exited', _on_event_player_over)


func get_random_point() -> Vector2:
	var center_vector = get_viewport_rect().size / 2. # Center of screen
	var angle = randf_range(0, TAU)
	var radius = center_vector.y
	var distance = randf() * radius
	return center_vector + Vector2.from_angle(angle) * distance


func _on_event_player_over(event:Node2D, playerObserver:PlayerObserver) -> void:
	target_map[playerObserver.controlling_player.name].append(event)


func _on_player_exited(event:Node2D, playerObserver:PlayerObserver) -> void:
	target_map[playerObserver.controlling_player.name].remove_at(target_map[playerObserver.controlling_player.name].find(event))


func _on_player_observe(playerObserver:PlayerObserver):
	# TODO: Rethink observation logic
	for event in target_map[playerObserver.controlling_player.name].filter(func (x): return x is Localization):
		if event is Localization:
			#event.interact_at(playerObserver.target.global_position, playerObserver)
			interact_at(playerObserver, event)


func interact_at(player:PlayerObserver, localization:Localization):
	var targetRect = player.collision_shape.shape.get_rect() # Rect2(pos-(reveal_size/2), reveal_size)
	var playerGlobalRect = Rect2(player.to_global(targetRect.position),targetRect.size)

	if localization.SourceEvent != null && playerGlobalRect.has_point(localization.to_global(localization.SourceEvent.position)):
		localization.SourceEvent.visible = true
	#var localPosition = player.target.global_position - global_position

	#for x in range(-reveal_size.x/2, reveal_size.x/2):
	for x in range(playerGlobalRect.position.x, playerGlobalRect.end.x):
		for y in range(playerGlobalRect.position.y, playerGlobalRect.end.y):
			var p = localization.to_local(Vector2(x, y))
			if p.x >= 0 and p.x < localization.image.get_width() and p.y >= 0 and p.y < localization.image.get_height():
				localization.image.set_pixelv(p, Color.TRANSPARENT)
	localization.mask_tex.update(localization.image)


func rotate_observing_players(rotation_speed):
	for playerObserver in PlayerObservers.get_children().filter(func(child):return child is PlayerObserver && child.is_observing):
		playerObserver.rotate_relative_to_background(rotation_speed)


func _on_session_timer_timeout() -> void:
	SceneManager.change_scene_with_transition(self, nextScene)

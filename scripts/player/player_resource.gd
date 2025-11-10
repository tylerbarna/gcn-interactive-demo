class_name PlayerResource extends Resource

@export var id: int = 1
@export var player_color: Color

var input_prefix: String
var active: bool = false
var name: String

var observatory_id: int
var observatory: Telescope
var ready:bool = false

## Observations can later be grouped by event id to check event coverage
var observations = []

func _init():
	name = "Player%d" % id
	input_prefix = "p%d" % id

func get_input_prefix():
	return "p%d" % id

func toggle_active():
	active = !active

func toggle_ready():
	ready = !ready

func add_observation(observation):
	observations.append(observation)

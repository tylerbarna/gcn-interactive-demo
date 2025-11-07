extends Node2D

signal player_over
signal player_exited

@export var location: Vector2
@export var points: int = 10
@export var decay_rate:int = 5

@onready var decay_timer = $DecayTimer as Timer
@onready var sprite = $Sprite2D as Sprite2D


func _ready() -> void:
	global_position = location
	#decay_timer.wait_time = 1 # Decay rate happens at a per second rate
	var tween = create_tween()
	# This rate could probably be better defined
	tween.tween_property(self, "modulate:a", 0, (decay_timer.wait_time / decay_rate) * points)
	decay_timer.start()
	sprite.scale *= float(points / 20.0) #?


func _process(_delta: float) -> void:
	if global_position.x < 0:
		queue_free()
	if points <= 0:
		queue_free()


func _on_decay_timer_timeout() -> void:
	points -= decay_rate


func _on_event_area_body_entered(body: Node2D) -> void:
	if body.name == "Target":
		var player = body.get_parent()
		player_over.emit(self, player)


func _on_event_area_body_exited(body: Node2D) -> void:
	if body.name == "Target":
		var player = body.get_parent()
		player_exited.emit(self, player)

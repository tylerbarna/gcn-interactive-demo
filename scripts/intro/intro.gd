extends Control

@onready var logo = $Logo

func _process(delta):
	logo.rotation += 0.05 * delta

func _input(event):
	if event.is_pressed():
		_end_intro()

func _end_intro():
	SceneManager.change_scene_with_transition(
		self,
		load("res://scenes/observatory_selection/telescope_select.tscn")
	)

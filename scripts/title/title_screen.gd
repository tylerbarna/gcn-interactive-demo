extends Control

# TODO: Update scene to use a better graphic for the circular frame

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_pressed():
		_start_game()

func _start_game():
	SceneManager.change_scene_with_transition(
		self,
		load("res://scenes/intro/intro.tscn")
	)

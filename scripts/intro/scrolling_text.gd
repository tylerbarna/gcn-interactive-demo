extends AnimationPlayer


@export var dialogue_label_paths: Array[NodePath] = []
@onready var key_sound: AudioStreamPlayer = $KeySound
var dialogue_labels: Array[RichTextLabel] = []


func _ready():
	for path in dialogue_label_paths:
		var label = get_node(path)
		if label and label is RichTextLabel:
			label.bbcode_enabled = true
			dialogue_labels.append(label)
		else:
			push_warning("Node at %s is not a RichTextLabel" % path)
	key_sound.stream = load("res://sounds/key-press.wav")
	await show_typed_all()


func show_typed_all() -> void:
	var affiliation_1 = Global.AFFILIATIONS.pick_random()
	var affiliation_2 = Global.AFFILIATIONS.pick_random()
	var font: Font = load("res://fonts/JetBrainsMono-Regular.ttf")

	var background := "You are a scientist working on follow-up astronomy at %s.\n\nYour alert pipeline has received a new Notice from %s via GCN's Kafka stream." % [affiliation_1, affiliation_2]
	var next_steps := "It is your job now to find and characterize the event!\n\nYou will each select from an array of telescopes to pinpoint the source and conduct targeted follow-up."
	var continue_prompt := "Press any button to continue..."

	await typewriter_text_all(background, font, 3)
	await typewriter_text_all(next_steps, font, 3)
	await typewriter_text_all(continue_prompt, font, 0)


func typewriter_text_all(message: String, font: Font, pause_length: float):
	for label in dialogue_labels:
		label_config(label, font)

	for character in message:
		for label in dialogue_labels:
			if !pause_length:
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_text(character)
		key_sound.pitch_scale = randf_range(0.9, 1.1)
		key_sound.volume_db = -20
		key_sound.play()
		await get_tree().create_timer(0.05).timeout

	for label in dialogue_labels:
		label.pop()
		label.pop()

	if pause_length:
		await get_tree().create_timer(pause_length).timeout
		for label in dialogue_labels:
			label.clear()


func label_config(label, font):
	label.clear()
	label.push_font(font)
	label.push_color(Color8(39,156,41))

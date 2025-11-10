class_name PlayerObserver extends Node2D

## Selected Obeservatory
@export var observatory_id:int

# Player Stats, these will be determined by Observatory selection screen
@export var slew_speed := 300.0
@export var sensitivity := 1 # Should scale inversely with observation_area
@export var observation_area = Vector2.ZERO
@export var wavelength = 500 # This may be better as a type (ex: UV, Radio, etc)
# that can be used to check group collaboration
@export var controlling_player: PlayerResource

@onready var target = $Target as CharacterBody2D
@onready var light_cone = $LightCone as Polygon2D
@onready var collision_shape = $Target/CollisionShape2D as CollisionShape2D
@onready var sprite = $Target/Sprite as Sprite2D
@onready var target_shader = $Target/Sprite.material as ShaderMaterial
@onready var timer = $InactiveTimeout as Timer
@onready var sensitivity_timer = $SensitivityTimer as Timer



signal observe
signal observation_ended

var is_observing := false
var active_band_id = 0


func _ready():
	target_shader.set_shader_parameter('player_color', controlling_player.player_color)
	collision_shape.shape.size = observation_area
	sprite.scale.x = observation_area.x / sprite.texture.get_width() # 480.0
	sprite.scale.y = observation_area.y / sprite.texture.get_height()

	light_cone.color = controlling_player.player_color
	light_cone.color.a = .5

	if !controlling_player.active:
		visible = false

	sensitivity_timer.wait_time = sensitivity
	sensitivity_timer.autostart = false


func _input(event):
	if (event.is_action_pressed("%s_primary" % controlling_player.get_input_prefix())):
		# Enable player
		if !controlling_player.active:
			controlling_player.active = true
			light_cone.modulate.a = .5
		elif is_observing:
			is_observing = false
			sensitivity_timer.stop()
		else:
			is_observing = true
			#currentObsId += 1
			observe.emit(self)
			sensitivity_timer.start()
			#currentObsStart = Time.get_unix_time_from_system()
		target_shader.set_shader_parameter('is_observing', is_observing)
	elif (event.is_action_pressed("%s_secondary" % controlling_player.get_input_prefix())):
		_cycle_observation_band()
	# Restart the timeout counter for inactive players
	timer.stop()
	timer.start()


func _process(_delta):
	light_cone.polygon = draw_arms()


func _physics_process(_delta: float) -> void:
	if (!controlling_player.active):
		return
	# Move target relative to player position
	if !is_observing:
		target.velocity = Vector2(
			Input.get_action_strength(controlling_player.get_input_prefix() + "_right")
			- Input.get_action_strength(controlling_player.get_input_prefix() + "_left"),
			Input.get_action_strength(controlling_player.get_input_prefix() + "_down")
			- Input.get_action_strength(controlling_player.get_input_prefix() + "_up")
		) * slew_speed
	else:
		target.velocity = Vector2.ZERO
	target.move_and_slide()


func draw_arms_circular() -> PackedVector2Array:
	var shape = collision_shape.shape as CircleShape2D

	var target_position = collision_shape.global_position - global_position
	var target_angle = target_position.angle() - collision_shape.global_rotation
	var T = target_position.length()
	var angle_offset = asin(shape.radius/T)

	var phi_1 = target_angle + angle_offset
	var phi_2 = target_angle - angle_offset

	var l = sqrt(T**2 - (shape.radius)**2)

	return PackedVector2Array([
		Vector2.ZERO,
		Vector2(cos(phi_1) * l, sin(phi_1)*l),
		Vector2(cos(phi_2) * l, sin(phi_2)*l)
	])


func draw_arms() -> PackedVector2Array:
	var shape = collision_shape.shape as RectangleShape2D
	var target_position:Vector2 = Vector2(
		collision_shape.global_position - global_position
	).rotated(-rotation)

	return PackedVector2Array([
		# Point at the players origin
		Vector2.ZERO,
		# Bottom left corner:
		target_position + Vector2(-shape.size.x/2, shape.size.y/2),
		# Bottom right corner
		target_position + Vector2(shape.size.x/2, shape.size.y/2),
	])


func rotate_relative_to_background(rotation_speed) -> void:
	var relative_vector:Vector2 = target.global_position
	relative_vector -= Global.ROTATION_AXIS
	relative_vector = relative_vector.rotated(rotation_speed)
	relative_vector += Global.ROTATION_AXIS
	target.global_position = relative_vector


func _on_inactive_timeout_timeout() -> void:
	controlling_player.active = false
	is_observing = false
	target.position = Vector2.ZERO
	light_cone.polygon = draw_arms()


func _on_sensitivity_timer_timeout() -> void:
# End observation, refactor:
	is_observing = false
	target_shader.set_shader_parameter('is_observing', is_observing)

	#currentObsEnd = Time.get_unix_time_from_system()
	#observations.append({
		#"id": currentObsId,
		#"start":currentObsStart,
		#"stop":currentObsEnd
	#})
	observation_ended.emit(self)


func _cycle_observation_band() -> void:
	active_band_id = (active_band_id + 1) % len(controlling_player.observatory.bands)

func current_band():
	return controlling_player.observatory.bands[active_band_id]

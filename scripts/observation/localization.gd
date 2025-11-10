class_name Localization extends Node2D


@onready var MaskArea = $MaskArea
@onready var SourceEvent = $Event
@onready var CollisionPolygon = $MaskArea/CollisionPolygon2D

@export_enum (
	"Swift_BAT:", 	# Arcmin localization
	"FERMI_GBM:1", 	# Larger circle
	"LVK:2" 		# Banana shape
) var LocalizationType = 0

@export var Radius:int = 100
@export var InnerRadius:int = 50
@export var location: Vector2

signal player_over
signal player_exited

var RoundedPolygon: RoundedPolygon2D = RoundedPolygon2D.new()
var image: Image
var mask_tex : ImageTexture:
	set(value):
		mask_tex = value
		queue_redraw()
var eventId:int

func _ready() -> void:
	global_position = location
	var polygon:PackedVector2Array = []
	if LocalizationType == 0:
		SourceEvent.position = get_random_point_in_circle()
		polygon = generate_circular_polygon(Radius, Vector2(Radius, Radius)).polygon
	elif LocalizationType == 1:
		SourceEvent.position = get_random_point_in_circle()
		polygon = generate_circular_polygon(Radius, Vector2(Radius, Radius)).polygon
	else:
		var poly1 = generate_circular_polygon(Radius, Vector2.ZERO)
		var poly2 = generate_circular_polygon(InnerRadius, Vector2(Radius,2 *Radius))
		var clipped_array = Geometry2D.clip_polygons(poly1.polygon, poly2.polygon)
		polygon = clipped_array[0]

		poly1.queue_free()
		poly2.queue_free()

	CollisionPolygon.polygon = polygon
	RoundedPolygon.polygon = polygon
	RoundedPolygon.uv = polygon
	MaskArea.add_child(RoundedPolygon)
	image = Image.create_empty(1920, 1080, false, Image.FORMAT_RGBA8)
	image.fill(RoundedPolygon.color)
	mask_tex = ImageTexture.create_from_image(image)

	RoundedPolygon.color = Color(randf(),randf(),randf(),.5)
	RoundedPolygon.corner_radius = 50
	RoundedPolygon.corner_detail = 20
	RoundedPolygon.texture = mask_tex
	RoundedPolygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func generate_circular_polygon(radius:int, offset_vector:Vector2) -> Polygon2D:
	var points = 24
	var polygon = Polygon2D.new()
	polygon.color = Color(randf(),randf(),randf(),.5)
	var rotation_angle = (2 * PI) / points # Radians
	var vect = Vector2(radius,0)
	var vect_array:PackedVector2Array = []
	for _i in points:
		vect_array.append(vect+offset_vector)
		vect = vect.rotated(rotation_angle)
	polygon.polygon= vect_array
	polygon.uv = vect_array
	return polygon


func get_random_point_in_circle() -> Vector2:
	var l = randi_range(0, Radius)
	var angle = randf_range(0, 2 * PI)
	var vector = Vector2(l, 0)
	return vector.rotated(angle) + Vector2(Radius, Radius)


func _on_mask_area_body_entered(body: Node2D) -> void:
	if body.name == "Target":
		var player = body.get_parent()
		player_over.emit(self, player)


func _on_mask_area_body_exited(body: Node2D) -> void:
	if body.name == "Target":
		var player = body.get_parent()
		player_exited.emit(self, player)

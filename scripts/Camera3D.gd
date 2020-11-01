extends Camera

onready var follow : Spatial = get_node("../Player")

export(Vector3) var offset = Vector3(0.0, 50.0, 20.0)
export(float) var zoom_speed = 100.0

var prev_offset_y = -1

func _ready():
	prev_offset_y = offset.y

func _process(delta):
	translation = follow.translation
	var new_offset_y = offset.y + follow.velocity.length() / 3.0
	if abs(prev_offset_y - new_offset_y) > (zoom_speed * delta):
		new_offset_y = prev_offset_y + (zoom_speed * sign(new_offset_y - prev_offset_y) * delta)
	translation.y = new_offset_y
	prev_offset_y = new_offset_y
	translation.z += offset.z

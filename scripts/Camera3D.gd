extends Camera

var follow : Spatial

export(Vector3) var offset = Vector3(0.0, 20.0, 20.0)
export(float) var zoom_speed = 100.0

var prev_offset_y = -1
var prev_offset_x = 0.0
var prev_offset_z = 0.0

func _ready():
	prev_offset_y = offset.y

func _process(delta):
	if follow == null:
		return
		
	translation = follow.translation
	var new_offset_y = offset.y + follow.velocity.length() / 1.0
	if abs(prev_offset_y - new_offset_y) > (zoom_speed * delta):
		new_offset_y = prev_offset_y + (zoom_speed * sign(new_offset_y - prev_offset_y) * delta)
	translation.y = new_offset_y
	prev_offset_y = new_offset_y
	translation.z += offset.z
	var new_offset_x = follow.transform.basis.z.x * follow.velocity.length() / 2.0
	var new_offset_z = follow.transform.basis.z.z * follow.velocity.length() / 2.0
	new_offset_x = prev_offset_x + ((new_offset_x-prev_offset_x) * 1.0 * delta)
	new_offset_z = prev_offset_z + ((new_offset_z-prev_offset_z) * 1.0 * delta)
	print("desired : %.3f, old : %.3f, new : %.3f" % [follow.transform.basis.z.x * follow.velocity.length() / 4.0, new_offset_x, prev_offset_x])
	translation.x -= new_offset_x
	translation.z -= new_offset_z
	prev_offset_x = new_offset_x
	prev_offset_z = new_offset_z

extends Spatial

export(float) var gravity_strength := 9000.0

func get_gravity(obj : Spatial) -> Vector3:
	var plane_obj : Vector3 = obj.global_transform.origin
	plane_obj.y = 0.0
	var plane_self : Vector3 = self.global_transform.origin
	plane_self.y = 0.0
	var dir = plane_self - plane_obj
	var r = dir.length()
	dir = dir.normalized()
	if r == 0.0:
		r = 1.0
	var attraction = gravity_strength / (r*r)
	attraction = clamp(attraction, 0.0, gravity_strength)
	
	return dir * attraction


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("attractors")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

extends KinematicBody

onready var root_ref = get_node("..")

var cur_time := 0.0
var explosion = preload("res://scenes/Explosion3D.tscn")

func _physics_process(delta : float):
	cur_time += delta
	if cur_time > root_ref.lifetime_sec:
		queue_free()
		return
		
	var move : Vector3 = global_transform.basis.z * delta * root_ref.m_sec
#	var start = self.translation
#	var end = start + move
#	var space_state = get_world().direct_space_state
#	var col = space_state.intersect_ray(start, end)
	
	#if col.empty():
	var col = move_and_collide(move)
	#else:
	#	self.transform.origin = col.position
		
	#move = move.rotated(get_parent().rotation)
	#var col = move_and_collide(move)
	if col:
		var n = explosion.instance()
		get_node("../..").call_deferred("add_child", n)
		n.Start(null)
		n.transform.origin = col.position
		if col.collider.has_method("damage"):
			col.collider.damage(10.0)
		queue_free()

extends Area

onready var root_ref = get_node("..")

var cur_time := 0.0
var explosion = preload("res://scenes/Explosion3D.tscn")

func _physics_process(delta : float):
	cur_time += delta
	if cur_time > root_ref.lifetime_sec:
		queue_free()
		return
	
	var colls : Array = get_overlapping_bodies()
	if len(colls) > 0:
		var hit_only_shooter = true
		for col in colls:
			if col != root_ref.shooter:
				hit_only_shooter = false
			if col.has_method("damage") and (col != root_ref.shooter || (cur_time > root_ref.self_harm_delay_sec)):
				col.damage(80.0)
		if not hit_only_shooter or cur_time > root_ref.self_harm_delay_sec:
			var n = explosion.instance()
			get_node("../..").add_child(n)
			n.Start(null)
			n.global_transform.origin = self.global_transform.origin
			queue_free()
		
	var move : Vector3 = (global_transform.basis.z * delta * root_ref.m_sec) + (root_ref.extra_velocity * delta)
	self.global_translate(move)

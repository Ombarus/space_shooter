extends Area
class_name LarpaTail

var root_ref
var explosion = preload("res://scenes/Explosion3D.tscn")
var cur_time := 0.0
var lifetime_sec := 5.0
export(float) var tail_m_sec := 14.0
var dir := Vector3.ZERO

func _ready():
	pass

func _physics_process(delta : float):
	cur_time += delta
	if cur_time > lifetime_sec:
		queue_free()
		return
		
	var colls : Array = get_overlapping_bodies()
	if len(colls) > 0:
		for col in colls:
			if col.has_method("damage"):
				col.damage(5.0)
		var n = explosion.instance()
		get_node("../..").add_child(n)
		n.Start(null)
		n.global_transform.origin = self.global_transform.origin
		queue_free()
		return
		
	var move : Vector3 = dir * delta * tail_m_sec
	self.global_translate(move)
	

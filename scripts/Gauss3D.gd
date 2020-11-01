extends KinematicBody

export(float) var lifetime_sec := 5.0

var explosion = preload("res://scenes/Explosion3D.tscn")
var velocity := Vector3(0,0,0)

var cur_time := 0.0

func _ready():
	cur_time = 0.0


func _physics_process(delta):
	cur_time += delta
	if cur_time > lifetime_sec:
		queue_free()
		return
		
	var move : Vector3 = velocity * delta
	var start = self.translation
	var end = start + move
	var space_state = get_world().direct_space_state
	var col = space_state.intersect_ray(start, end)
	
	if col.empty():
		col = move_and_collide(move)
	else:
		self.transform.origin = col.position
		
	#move = move.rotated(get_parent().rotation)
	#var col = move_and_collide(move)
	if col:
		var n = explosion.instance()
		get_node("../..").call_deferred("add_child", n)
		n.Start(null)
		n.transform.origin = col.position
		BehaviorEvents.emit_signal("OnWeaponCollision", col.collider)
		queue_free()
	

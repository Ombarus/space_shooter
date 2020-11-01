extends KinematicBody2D

export(float) var lifetime_sec := 5.0

var explosion = preload("res://scenes/Explosion.tscn")
var velocity := Vector2(0,0)

var cur_time := 0.0

func _ready():
	cur_time = 0.0


func _physics_process(delta):
	cur_time += delta
	if cur_time > lifetime_sec:
		get_parent().queue_free()
		return
		
	var move : Vector2 = velocity * delta
	var col = move_and_collide(move)
	if col:
		var n = explosion.instance()
		get_node("../..").call_deferred("add_child", n)
		n.Start(null)
		n.position = col.position
		get_parent().queue_free()
	

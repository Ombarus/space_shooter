extends KinematicBody2D

export(bool) var active = true

var velocity := Vector2()
var laser = preload("res://scenes/Gauss.tscn")
var cur_inst = null

var target = null

var i := 0

var cur_angle := 0.0
var time_accum := 0.0

func _ready():
	time_accum = 0.0
	target = get_parent().find_node("Player")

func _physics_process(delta):
	if not active:
		return
	#velocity.y += 90
	#if not Input.is_action_pressed("ui_accept"):
	velocity = velocity / 1.03

	var apply_force := Vector2(0, 0)
	var target_pos : Vector2 = target.global_position + Vector2(200.0, 0.0).rotated(cur_angle)
	cur_angle += delta
	
	apply_force = target_pos - self.global_position
	get_node("../Polygon2D").global_position = target_pos
	apply_force = apply_force.normalized() * 30.0
	var motion : Vector2 = velocity + apply_force
	velocity = move_and_slide(motion, Vector2(0.0, 0.0))
	
	velocity.x = clamp(velocity.x, -1000.0, 1000.0)
	velocity.y = clamp(velocity.y, -1000.0, 1000.0)
	
	look_at(target.global_position)
	
	time_accum += delta
	if time_accum > 0.5:
		fire()
		time_accum = 0.0

func fire():
	var n = laser.instance()
	get_node("..").call_deferred("add_child", n)
	var launch_vel = Vector2(3000.0, 0)
	launch_vel = launch_vel.rotated(self.rotation)
	launch_vel += velocity
	n.get_node("KinematicBody2D").velocity = launch_vel
	n.position = get_node("gun").global_position
	n.rotation = self.rotation
	cur_inst = n


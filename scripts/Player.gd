extends KinematicBody2D

var velocity := Vector2()
var laser = preload("res://scenes/Gauss.tscn")
var cur_inst = null

var i := 0

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("touch"):
			fire()

func _physics_process(delta):
	#velocity.y += 90
	if Input.is_action_pressed("ui_accept"):
		var boost = Vector2(60, 0)
		boost = boost.rotated(self.rotation)
		velocity += boost
	
	velocity = velocity / 1.01

	var apply_force := Vector2(0, 0)
	if Input.is_action_pressed("ui_left"):
		apply_force.x -= 10
	if Input.is_action_pressed("ui_right"):
		apply_force.x += 10
	if Input.is_action_pressed("ui_up"):
		apply_force.y -= 10
	if Input.is_action_pressed("ui_down"):
		apply_force.y += 10

	#apply_force = apply_force.rotated(rotation)
	var motion : Vector2 = velocity + apply_force
	velocity = move_and_slide(motion, Vector2(0.0, 0.0))
	
	velocity.x = clamp(velocity.x, -5000.0, 5000.0)
	velocity.y = clamp(velocity.y, -5000.0, 5000.0)
	
	look_at(get_global_mouse_position())

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


extends KinematicBody

var velocity := Vector3()
onready var cam : Camera = get_node("../Camera")
var laser = preload("res://scenes/Gauss3D.tscn")

var should_fire = false

var attractor := []

var i := 0

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("touch"):
			should_fire = true

func _physics_process(delta):
	#velocity.y += 90
	var base_str = 0.35
	var boost_str = 2.0
	if Input.is_action_pressed("ui_accept"):
		var boost : Vector3 = self.transform.basis.z * -boost_str
		velocity += boost
	
	velocity = velocity / 1.01

	var apply_force := Vector3(0, 0, 0)
	if Input.is_action_pressed("ui_left"):
		apply_force.x -= base_str
	if Input.is_action_pressed("ui_right"):
		apply_force.x += base_str
	if Input.is_action_pressed("ui_up"):
		apply_force.z -= base_str
	if Input.is_action_pressed("ui_down"):
		apply_force.z += base_str

	#apply_force = apply_force.rotated(rotation)
	
	var gravity = Vector3.ZERO
	var attractors = get_tree().get_nodes_in_group("attractors")
	for attractor in attractors:
		gravity += attractor.get_gravity(self) * delta
	
	var motion : Vector3 = velocity + apply_force + gravity
	velocity = move_and_slide(motion, Vector3(0.0, 1.0, 0.0))
	
	velocity.x = clamp(velocity.x, -100.0, 100.0)
	velocity.z = clamp(velocity.z, -100.0, 100.0)
	velocity.y = 0.0
	self.translation.y = 0.0
	
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var dir : Vector3 = cam.project_ray_normal(mouse_pos)
	var orig : Vector3 = cam.project_ray_origin(mouse_pos)
	var board_plane := Plane(Vector3(0.0, 1.0, 0.0), 0.0)
	var cam_pos : Vector3 = board_plane.intersects_ray(orig, dir)
	
	var cam_pos_2d := Vector2(cam_pos.x, cam_pos.z)
	var player_pos_2d := Vector2(self.translation.x, self.translation.z)
	var player_heading_2d := Vector2(self.transform.basis.z.x, self.transform.basis.z.z)
	var desired_heading_2d := player_pos_2d - cam_pos_2d
	var phi : float = desired_heading_2d.angle_to(player_heading_2d)
	
	phi *= delta * 3.0
	
	self.rotation.y += phi
	
	var desired_z = clamp(phi * 7.5, deg2rad(-45.0), deg2rad(45.0))
	var offset = desired_z - self.rotation.z 
	self.rotation.z += offset * delta * 20.0
	
	if should_fire:
		should_fire = false
		fire(delta)
#	var desired_trans : Transform = self.transform.looking_at(cam_pos, Vector3(0.0, 1.0, 0.0))
#
#	var interpolated_trans = self.transform.interpolate_with(desired_trans, 0.05)
#	var zeta = interpolated_trans.basis.z.cross(self.transform.basis.z)
#	var phi = interpolated_trans.basis.z.angle_to(self.transform.basis.z)
#	print(zeta)
#	if zeta.y > 0.001:
#		phi *= -1
#	self.transform = interpolated_trans
#	print(phi)
#	self.rotation.z = phi * 20.0
	
	
	#look_at(pos, Vector3(0.0, 1.0, 0.0))

func fire(delta):
	var n : KinematicBody = laser.instance()
	var launch_vel : Vector3 = self.transform.basis.z * -300.0
	launch_vel += velocity
	n.velocity = launch_vel
	n.transform = get_node("gun").global_transform
	
	var move : Vector3 = launch_vel * delta
	var start = n.transform.origin
	var end = start + move
	var space_state = get_world().direct_space_state
	var col = space_state.intersect_ray(start, end)
	
	if col.empty():
		n.transform.origin += move
	else:
		n.transform.origin = col.position
		
	#move = move.rotated(get_parent().rotation)
	#var col = move_and_collide(move)
	if col:
		var e = n.explosion.instance()
		get_node("..").call_deferred("add_child", e)
		e.Start(null)
		e.transform.origin = col.position
		n.queue_free()
	else:
		get_node("..").call_deferred("add_child", n)


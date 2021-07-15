extends KinematicBody
class_name Player3D

var velocity := Vector3()
var cam : Camera
var laser = preload("res://scenes/Gauss3D.tscn")

var should_fire = false

var attractor := []

var ui_accept : bool = false
var apply_force : Vector3 = Vector3.ZERO
var phi : float

var i := 0

func _ready():
	if get_tree().get_network_unique_id() != int(self.name):
		return
		
	cam = get_tree().root.find_node("Camera", true, false)
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("touch"):
			should_fire = true

func _physics_process(delta):
	if not Server.is_server and cam == null:
		return
		
	var base_str = 0.35
		
	if not Server.is_server:
		var apply_force := Vector2(0, 0)
		if Input.is_action_pressed("ui_left"):
			apply_force.x -= base_str
		if Input.is_action_pressed("ui_right"):
			apply_force.x += base_str
		if Input.is_action_pressed("ui_up"):
			apply_force.y -= base_str
		if Input.is_action_pressed("ui_down"):
			apply_force.y += base_str
			
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
		
		 #s_update_input(touch : bool, ui_accept : bool, dir : Vector2, mouse_phi : Vector2):
		Server.rpc_unreliable_id(1, "s_update_input", 
			should_fire,
			Input.is_action_pressed("ui_accept"), 
			apply_force,
			phi)
		return
		
	var boost_str = 2.0
	if ui_accept:
		var boost : Vector3 = self.transform.basis.z * -boost_str
		velocity += boost
	
	velocity = velocity / 1.01
	
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
	
	var delta_phi = phi * delta * 3.0
	
	self.rotation.y += delta_phi
	
	var desired_z : float = clamp(phi * 7.5, deg2rad(-45.0), deg2rad(45.0))
	var offset = desired_z - self.rotation.z 
	self.rotation.z += offset * delta * 20.0
	
	if should_fire:
		should_fire = false
		fire(delta)
		
	Client.rpc_unreliable("c_udpate_player", self.name, self.transform)
		

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
		
	if col:
		var e = n.explosion.instance()
		get_node("..").call_deferred("add_child", e)
		e.Start(null)
		e.transform.origin = col.position
		n.queue_free()
	else:
		get_node("..").call_deferred("add_child", n)


extends KinematicBody
class_name Player3D

var velocity := Vector3()
var cam : Camera
var gauss = preload("res://scenes/Gauss3D.tscn")
var larpa = preload("res://scenes/weapons/Larpa.tscn")
var laser = preload("res://scenes/weapons/Laser.tscn")
var cur_weapon

var fire_button := false
var prev_fire_button := false
var last_bullet : Spatial = null

var attractor := []

var ui_accept : bool = false
var apply_force : Vector3 = Vector3.ZERO
var phi : float

var i := 0

func _ready():
	if not Server.is_server and get_tree().get_network_unique_id() != int(self.name):
		return
		
	cam = get_tree().root.find_node("Camera", true, false)
	if cam != null:
		cam.follow = self
		
func client_data_received(params : Array):
	if params[0] == 0: # player input
		fire_button = params[1] # touch
		ui_accept = params[2] # ui_accept
		apply_force = Vector3(params[3].x, 0.0, params[3].y) # dir
		phi = params[4] # mouse_phi
	
func server_data_received(params : Array):
	if params[0] == 0: # player position update
		transform = params[1]
	elif params[0] == 1: # Spawn Object (probably should go in a spawn manager but this is just a prototype)
		#larpa.resource_path, last_bullet.transform, last_bullet.get_path(), [0, last_bullet.rng.state]
		var resource_path : String = params[1]
		var init_transform : Transform = params[2]
		var spawn_path : NodePath = params[3]
		var spawn_name : String = params[4]
		var remote_init : Array = params[5]
		last_bullet = load(resource_path).instance()
		get_node(spawn_path).add_child(last_bullet)
		last_bullet.name = spawn_name
		last_bullet.transform = init_transform
		last_bullet.server_data_received(remote_init)
		if !last_bullet.IsHeld():
			last_bullet = null
	elif params[0] == 2:
		call_deferred("stop_bullet")

func stop_bullet():
	if last_bullet != null:
		last_bullet.free()
		last_bullet = null

#func _unhandled_input(event):
#	if event is InputEventMouseButton:
#		if event.is_action_pressed("touch"):
#			should_fire = true
#		if event.is_action_released("touch") and last_bullet != null and last_bullet.IsHeld() == true:
#			should_stop_fire = true

func _physics_process(delta):
	if last_bullet != null:
		var launch_vel : Vector3 = self.transform.basis.z * -1.0
		last_bullet.transform = get_node("gun").global_transform
		last_bullet.transform.basis.z = launch_vel
		
	if not Server.is_server and cam == null:
		return
		
	var base_str = 0.35
		
	if not Server.is_server or Server.is_single_player:
		var apply_force_local := Vector2(0, 0)
		if Input.is_action_pressed("ui_left"):
			apply_force_local.x -= base_str
		if Input.is_action_pressed("ui_right"):
			apply_force_local.x += base_str
		if Input.is_action_pressed("ui_up"):
			apply_force_local.y -= base_str
		if Input.is_action_pressed("ui_down"):
			apply_force_local.y += base_str
			
		var mouse_pos : Vector2 = get_viewport().get_mouse_position()
		var dir : Vector3 = cam.project_ray_normal(mouse_pos)
		var orig : Vector3 = cam.project_ray_origin(mouse_pos)
		var board_plane := Plane(Vector3(0.0, 1.0, 0.0), 0.0)
		var cam_pos : Vector3 = board_plane.intersects_ray(orig, dir)
		
		var cam_pos_2d := Vector2(cam_pos.x, cam_pos.z)
		var player_pos_2d := Vector2(self.translation.x, self.translation.z)
		var player_heading_2d := Vector2(self.transform.basis.z.x, self.transform.basis.z.z)
		var desired_heading_2d := player_pos_2d - cam_pos_2d
		var phi_local : float = desired_heading_2d.angle_to(player_heading_2d)
		
		#s_update_input(touch : bool, ui_accept : bool, dir : Vector2, mouse_phi : Vector2):
		Server.rpc_unreliable_id(1, "s_update_object", self.get_path(), [
			0, # player input
			Input.is_action_pressed("touch"),
			Input.is_action_pressed("ui_accept"), 
			apply_force_local,
			phi_local
		])
		if not Server.is_single_player:
			return
		else:
			phi = phi_local
			ui_accept = Input.is_action_pressed("ui_accept")
			apply_force = Vector3(apply_force_local.x, apply_force_local.y, 0.0)
		
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
	
	var fired := false
	var stopped := false
	if fire_button and not prev_fire_button:
		fired = fire(delta)
	if not fire_button and last_bullet != null and last_bullet.IsHeld() == true:
		stopped = stop_fire()
		
	prev_fire_button = fire_button
	Client.rpc_unreliable("c_update_object", self.get_path(), [0, self.transform])
		

func fire(delta) -> bool:
	if not Server.is_server:
		return false
	if last_bullet != null and last_bullet.IsHeld():
		return false
		
	last_bullet = cur_weapon.instance()
	
	print("Spawn Bullet")
	
	var launch_vel : Vector3 = self.transform.basis.z * -1.0
	#launch_vel += velocity
	#n.velocity = launch_vel
	last_bullet.transform = get_node("gun").global_transform
	last_bullet.transform.basis.z = launch_vel
	
	var move : Vector3 = launch_vel * delta
	var start = last_bullet.transform.origin
	var end = start + move
	var space_state = get_world().direct_space_state
	var col = space_state.intersect_ray(start, end)
	
	if col.empty():
		last_bullet.transform.origin += move
	else:
		last_bullet.transform.origin = col.position
		
	get_node("..").add_child(last_bullet)
	
	print(self.get_path())
	Client.rpc("c_update_object", self.get_path(), [1, 
		cur_weapon.resource_path, last_bullet.transform, last_bullet.get_parent().get_path(), last_bullet.name,
		last_bullet.get_init_data()
	])
	#Client.rpc("c_spawn", larpa.resource_path, last_bullet.transform, last_bullet.name, get_node("..").get_path(), [])
	
	if !last_bullet.IsHeld():
		last_bullet = null
		
	return true
	
	
func stop_fire() -> bool:
	print("stop fire")
	if last_bullet != null and last_bullet.IsHeld():
		Client.rpc("c_update_object", self.get_path(), [2])
		call_deferred("stop_bullet")
		return true
	return false

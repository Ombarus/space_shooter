extends KinematicBody

var velocity := Vector3()

var random_target := Vector3()

var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	random_target.x = rng.randf_range(-240.0, 240.0)
	random_target.z = rng.randf_range(-240.0, 240.0)


func _physics_process(delta):
	get_node("../ai_target").transform.origin = random_target
	#velocity.y += 90
	var base_str := 0.35
	var boost_str := 2.0
	
	var boost_btn := false
	var left_btn := false
	var right_btn := false
	var up_btn := false
	var down_btn := false
	
	var target_dir = (self.transform.origin - random_target).normalized()
	if (target_dir - self.transform.basis.z).length() <= 0.1:
		boost_btn = true
	
	if boost_btn:
		var boost : Vector3 = self.transform.basis.z * -boost_str
		velocity += boost
	
	velocity = velocity / 1.01

	var apply_force := Vector3(0, 0, 0)
	if left_btn:
		apply_force.x -= base_str
	if right_btn:
		apply_force.x += base_str
	if up_btn:
		apply_force.z -= base_str
	if down_btn:
		apply_force.z += base_str

	#apply_force = apply_force.rotated(rotation)
	var motion : Vector3 = velocity + apply_force
	velocity = move_and_slide(motion, Vector3(0.0, 1.0, 0.0))
	
	velocity.x = clamp(velocity.x, -100.0, 100.0)
	velocity.z = clamp(velocity.z, -100.0, 100.0)
	velocity.y = 0.0
	self.translation.y = 0.0
	
#	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
#	var dir : Vector3 = cam.project_ray_normal(mouse_pos)
#	var orig : Vector3 = cam.project_ray_origin(mouse_pos)
#	var board_plane := Plane(Vector3(0.0, 1.0, 0.0), 0.0)
	var cam_pos : Vector3 = random_target
	
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
	
	var zeroed_orig : Vector3 = self.transform.origin
	zeroed_orig.y = 0
	var zeroed_target : Vector3 = random_target
	zeroed_target.y = 0
	if (zeroed_orig - zeroed_target).length() <= 5.0:
		random_target.x = rng.randf_range(-240.0, 240.0)
		random_target.z = rng.randf_range(-240.0, 240.0)

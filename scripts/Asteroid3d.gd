extends StaticBody



var rot_vec := Vector3(0.0, 0.0, 0.0)
var rng = RandomNumberGenerator.new()
var max_rot_speed = 0.6

func _ready():
	rng.randomize()
	rot_vec = Vector3(rng.randf_range(-max_rot_speed, max_rot_speed), rng.randf_range(-max_rot_speed, max_rot_speed), rng.randf_range(-max_rot_speed, max_rot_speed))


func _physics_process(delta):
	self.rotation += rot_vec * delta

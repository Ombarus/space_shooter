extends BaseWeapon

export(float) var lifetime_sec := 5.0
export(float) var m_sec := 400.0

var explosion = preload("res://scenes/Explosion3D.tscn")
var dir := Vector3(0,0,-1)
var shooter : Node
var extra_velocity := Vector3.ZERO
var body : Spatial

var cur_time := 0.0

func _ready():
	cur_time = 0.0
	
func server_data_received(params):
	if params[0] == 0: # initialize on spawn
		shooter = get_node(params[1])
		extra_velocity = params[2]

func get_init_data():
	return [0, shooter.get_path(), extra_velocity]
	
func GetEnergyCost():
	return 110.0


func _process(delta : float):
	cur_time += delta
	if not is_instance_valid(body):
		# wait for tail to die
		if cur_time > lifetime_sec:
			queue_free()
		return

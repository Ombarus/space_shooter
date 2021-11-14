extends BaseWeapon
class_name Larpa

export(float) var m_sec := 30.0
export(float) var lifetime_sec := 5.0
export(float) var spawnrate_sec := 0.08
export(float) var spawnangle_deg := 45
export(float) var spawnangle_min_deg := 30

var larpa_tail_scene : PackedScene
var body : Spatial
var dir := Vector3(0,0,-1)
var cur_time := 0.0
var rng := RandomNumberGenerator.new()

func server_data_received(params):
	if params[0] == 0: # initialize on spawn
		rng.state = params[1]

func get_init_data():
	return [0, rng.state]
	
func _ready():
	rng.randomize()
	larpa_tail_scene = preload("res://scenes/weapons/LarpaTail.tscn")
	body = get_node("KinematicBody")

func _process(delta : float):
	cur_time += delta
	if not is_instance_valid(body):
		# wait for tail to die
		if cur_time > lifetime_sec:
			queue_free()
		return
	#if Server.is_server:
	while cur_time >= spawnrate_sec:
		cur_time -= spawnrate_sec
		var n : LarpaTail = larpa_tail_scene.instance() as LarpaTail
		call_deferred("add_child", n)
		var rand_angle = rng.randf() * deg2rad(spawnangle_deg) * 2.0 - deg2rad(spawnangle_deg)
		rand_angle += deg2rad(spawnangle_min_deg) * sign(rand_angle)
		var tail_dir = transform.basis.z * -1.0
		tail_dir = tail_dir.rotated(Vector3.UP, rand_angle)
		n.translation = get_node("KinematicBody").translation + Vector3.FORWARD# + (tail_dir * 5.0)
		n.dir = tail_dir
		
		#Client.rpc("c_spawn", "res://scenes/weapons/LarpaTail.tscn", n.transform, n.name, get_path(), [tail_dir])
			
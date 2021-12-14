extends BaseWeapon

export var MaxDist := 10.0
export var DamPerSec := 20.0

var spark : Spatial = null
var spark_scene = preload("res://scenes/weapons/LaserSpark.tscn")

func IsHeld():
	return true

func _exit_tree():
	if spark != null:
		spark.queue_free()

func server_data_received(params):
	pass
		
func get_init_data():
	return []
	
func GetEnergyCost():
	return 25.0 # per second?
		
func _physics_process(delta):
	var space_state : PhysicsDirectSpaceState = get_world().direct_space_state
	var end_point : Vector3 = self.translation + (self.global_transform.basis.z.normalized() * MaxDist)
	var result : Dictionary = space_state.intersect_ray(self.translation, end_point, [], pow(2,1) + 1)
	if not result.empty():
		end_point = result.position
		if spark == null:
			spark = spark_scene.instance()
			get_parent().add_child(spark)
		spark.translation = end_point
		var norm : Vector3 = result.normal
		norm.y = 0.0
		var a : float = norm.angle_to(Vector3.RIGHT)
		spark.rotation.y = a
		if result.collider.has_method("damage"):
			result.collider.damage(DamPerSec * delta)
	elif spark != null:
		spark.queue_free()
		spark = null
	self.scale = Vector3(1.0, 1.0, -(end_point-self.translation).length())

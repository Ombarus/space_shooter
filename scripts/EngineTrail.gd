extends Spatial

onready var reactor_ref : MeshInstance = get_node("Reactor")
onready var trail_ref : MeshInstance = get_node("Trail")
onready var trail_root : Spatial = get_node("TrailRoot")
var parent_player : Player3D

var tail_points := []

func _ready():
	parent_player = get_parent()
	#trail_ref.set_as_toplevel(true)

func _process(delta):
	var input := parent_player.apply_force
	var input_str = input.length()
	#print(input_str)
	reactor_ref.scale = Vector3(input_str, input_str, input_str)
	
	var new_p : Vector3 = trail_root.global_transform.origin
	#print("ship pos : " + str(new_p))
	#var new_p : Vector3 = trail_ref.transform.origin
	if (tail_points.size() <= 0 or abs((tail_points[tail_points.size()-1] - new_p).length()) > 0.01):
		tail_points.push_back(new_p)
	
	if tail_points.size() > 20:
		tail_points.remove(0)
	
	trail_ref.LinePointList = tail_points
	trail_ref.global_transform = Transform.IDENTITY
	trail_ref.update_visual()

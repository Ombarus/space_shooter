extends Control

var follow_ref : Spatial
export(NodePath) onready var Follow
export(NodePath) onready var CameraRef = get_node(CameraRef)
export(Vector2) var Offset : Vector2 = Vector2(0,0)

func _ready():
	if has_node(Follow):
		follow_ref = get_node(Follow)
	
func _process(delta):
	if follow_ref == null:
		return
		
	var screen_pos = CameraRef.unproject_position(Follow.global_transform.origin) + Offset
	var vp_size = self.get_viewport().size
	if get_viewport().is_size_override_enabled():
		vp_size = get_viewport().get_size_override()
		
	rect_position = screen_pos

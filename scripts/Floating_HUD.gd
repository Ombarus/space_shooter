extends Control

class_name HUD

var follow_ref = null
export(NodePath) onready var Follow
var camera_ref = null
export(NodePath) var CameraRef
export(Vector2) var Offset : Vector2 = Vector2(0,0)

func _ready():
	if has_node(Follow):
		follow_ref = get_node(Follow)
	camera_ref = get_node(CameraRef)
	
func _process(delta):
	if follow_ref == null or camera_ref == null:
		return
	
	get_node("VBoxContainer/Hull").max_value = follow_ref.max_hp
	get_node("VBoxContainer/Hull").value = follow_ref.cur_hp
	
	get_node("VBoxContainer/HBoxContainer/Energy").max_value = follow_ref.weapon_max_energy
	get_node("VBoxContainer/HBoxContainer/Energy").value = follow_ref.weapon_cur_energy
	
	var screen_pos = camera_ref.unproject_position(follow_ref.global_transform.origin) + Offset
	var vp_size = self.get_viewport().size
	if get_viewport().is_size_override_enabled():
		vp_size = get_viewport().get_size_override()
		
	rect_position = screen_pos

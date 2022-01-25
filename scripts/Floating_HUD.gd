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
	
	get_node("VBoxContainer/HBoxContainer2/Overheat").max_value = follow_ref.boost_max_energy
	get_node("VBoxContainer/HBoxContainer2/Overheat").value = follow_ref.boost_cur_energy
	if follow_ref.boost_overheat == true and follow_ref.boost_cur_energy <= 0.0:
		get_node("VBoxContainer/HBoxContainer2/Overheat/AnimationPlayer").play("overheat")
	else:
		get_node("VBoxContainer/HBoxContainer2/Overheat/AnimationPlayer").play("RESET")
	
	var screen_pos = camera_ref.unproject_position(follow_ref.global_transform.origin) + Offset
	#var vp_size = self.get_viewport().size
	#if get_viewport().is_size_override_enabled():
	#	vp_size = get_viewport().get_size_override()
		
	for c in get_parent().get_children():
		if c != self and "follow_ref" in c:
			var target_pos = c.follow_ref.transform.origin
			var my_pos = follow_ref.transform.origin
			var target_dir = (target_pos - my_pos).normalized()
			var pointer = get_node("EnemyPointer")
			pointer.position = Vector2(target_dir.x, target_dir.z) * 140.0 - Offset
			pointer.rotation = Vector2(0.0, -1.0).angle_to(Vector2(target_dir.x, target_dir.z))
		
	rect_position = screen_pos

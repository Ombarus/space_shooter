extends Control

export(NodePath) onready var camera_ref = get_node(camera_ref)
export(NodePath) onready var follow_ref = get_node(follow_ref)

func _process(delta):
	var screen_pos = camera_ref.unproject_position(follow_ref.global_transform.origin)
	rect_position = screen_pos
	

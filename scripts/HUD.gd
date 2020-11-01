extends CanvasLayer


export(NodePath) var pointer_ref = ""
export(NodePath) var origin_ref = ""

onready var _pointer_ref : Spatial = get_node(pointer_ref)
onready var _origin_ref : Spatial = get_node(origin_ref)
onready var _hp : ColorRect = get_node("SafeArea/hp")

var hp := 500.0

func _ready():
	BehaviorEvents.connect("OnWeaponCollision", self, "OnWeaponCollision_Callback")
	_hp.rect_size.x = hp
	
func OnWeaponCollision_Callback(obj):
	if obj == _pointer_ref:
		hp -= 10.0
		if hp <= 0.0:
			hp = 500.0
		_hp.rect_size.x = hp

func _process(delta):
	var cam : Camera = get_viewport().get_camera()
	var ref_pos : Vector3 = _pointer_ref.transform.origin
	var orig_3d : Vector3 = _origin_ref.transform.origin
	var ref_2d : Vector2 = cam.unproject_position(ref_pos)
	var orig_2d : Vector2  = cam.unproject_position(orig_3d)
	
	var ship_pointer : Control = get_node("SafeArea/ship_pointer")
	
	var vp_size = self.get_viewport().size
	if get_viewport().is_size_override_enabled():
		vp_size = get_viewport().get_size_override()
		
	if ref_2d.x > 0.0 and ref_2d.x < vp_size.x and ref_2d.y > 0.0 and ref_2d.y < vp_size.y:
		ship_pointer.visible = false
	else:
		ship_pointer.visible = true
		
	ref_2d.x = clamp(ref_2d.x, vp_size.x * 0.02, vp_size.x - (vp_size.x * 0.02))
	ref_2d.y = clamp(ref_2d.y, vp_size.y * 0.02, vp_size.y - (vp_size.y * 0.02))
	ship_pointer.rect_position = ref_2d
	
func _input(event):
	if event.is_action_pressed("full_screen"):
		OS.window_fullscreen = not OS.window_fullscreen
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

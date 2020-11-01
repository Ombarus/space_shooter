extends CheckBox

export(NodePath) var AIShip

onready var _aiship = get_node(AIShip)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.pressed = _aiship.active



func _on_CheckBox_toggled(button_pressed):
	_aiship.active = button_pressed

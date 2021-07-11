extends Resource
class_name Biome


export var gradient : GradientTexture setget colorsSet, colorsGet
export var startHeight : float setget startHeightSet, startHeightGet
export var tint : Color
export var tintPercent : float

func colorsSet(value):
	gradient = value
	emit_signal("changed")
	if not gradient.is_connected("changed", self, "ColorsChanged"):
		gradient.connect("changed", self, "ColorsChanged")
	
func colorsGet():
	return gradient
	
func ColorsChanged():
	emit_signal("changed")
	
func startHeightSet(value):
	startHeight = value
	emit_signal("changed")

func startHeightGet():
	return startHeight


tool
extends Resource
class_name NoiseSettings

export var Enabled : bool = true setget setEnabled, getEnabled
export var Noise : OpenSimplexNoise setget setNoise, getNoise
export var Amplitude : float = 1.0 setget setAmplitude, getAmplitude

func setEnabled(value):
	Enabled = value
	emit_signal("changed")
	
func getEnabled():
	return Enabled
	
func setNoise(value):
	Noise = value
	emit_signal("changed")
	if Noise != null and Noise.is_connected("changed", self, "NoiseChanged_Callback") == false:
		Noise.connect("changed", self, "NoiseChanged_Callback")
		
func getNoise():
	return Noise
	
func setAmplitude(value):
	Amplitude = value
	emit_signal("changed")
	
func getAmplitude():
	return Amplitude
		
func NoiseChanged_Callback():
	emit_signal("changed")

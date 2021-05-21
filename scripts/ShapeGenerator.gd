tool
extends Resource
class_name ShapeGenerator

export var Radius : float = 1.0 setget radiusSet, radiusGet
export var Resolution : int = 10 setget resSet, resGet
export(Array, Resource) var Noise : Array setget noiseSet, noiseGet
export var MinValue : float = 1.0 setget MinValSet, MinValGet
export var Amplitude : float = 1.0 setget AmplitudeSet, AmplitudeGet

func AmplitudeSet(value):
	Amplitude = value
	emit_signal("changed")
	
func AmplitudeGet():
	return Amplitude

func MinValSet(value):
	MinValue = value
	emit_signal("changed")
	
func MinValGet():
	return MinValue

func radiusSet(value):
	Radius = value
	emit_signal("changed")
	
func radiusGet():
	return Radius

func resSet(value):
	Resolution = value
	emit_signal("changed")
	
func noiseSet(value):
	Noise = value
	emit_signal("changed")
	#if not Noise.is_connected("changed", self, "NoiseChanged"):
	#	Noise.connect("changed", self, "NoiseChanged")

#func NoiseChanged():
#	emit_signal("changed")

func noiseGet():
	return Noise
	
func resGet():
	return Resolution

func CalculatePointOnPlanet(pointOnUnitSphere : Vector3) -> Vector3:
	var elevation : float = 0.0
	for n in Noise:
		elevation += n.Noise.get_noise_3dv(pointOnUnitSphere) * n.Amplitude
	elevation = max(0, elevation - MinValue)
	return pointOnUnitSphere * Radius * (1+elevation)

tool
extends Resource
class_name ShapeGenerator

export var disable_generation := false
export var Radius : float = 1.0 setget radiusSet, radiusGet
export var Resolution : int = 10 setget resSet, resGet
export(Array, Resource) var Noise : Array setget noiseSet, noiseGet
export var MinValue : float = 1.0 setget MinValSet, MinValGet
export var Material : Material setget MaterialSet, MaterialGet
export(Array, Resource) var Biomes : Array setget BiomesSet, BiomesGet
export var BiomeNoise : OpenSimplexNoise setget BiomeNoiseSet, BiomeNoiseGet
export var BiomeNoiseAmplitude : float setget BiomeAmpSet, BiomeAmpGet
export var BiomeNoiseOffset : float setget BiomeNoiseOffsetSet, BiomeNoiseOffsetGet
export(float, 0.0, 1.0) var blendAmount : float setget blendAmountSet, blendAmountGet

func blendAmountSet(value):
	blendAmount = value
	emit_signal("changed")
	
func blendAmountGet():
	return blendAmount

func BiomeNoiseOffsetSet(value):
	BiomeNoiseOffset = value
	emit_signal("changed")
	
func BiomeNoiseOffsetGet():
	return BiomeNoiseOffset

func BiomeNoiseSet(value):
	BiomeNoise = value
	emit_signal("changed")
	if BiomeNoise != null and not BiomeNoise.is_connected("changed", self, "NoiseChanged"):
		BiomeNoise.connect("changed", self, "NoiseChanged")
		
func BiomeNoiseGet():
	return BiomeNoise
	
func BiomeAmpSet(value):
	BiomeNoiseAmplitude = value
	emit_signal("changed")
	
func BiomeAmpGet():
	return BiomeNoiseAmplitude

func BiomesSet(value):
	Biomes = value
	emit_signal("changed")
	for n in Biomes:
		if not n.is_connected("changed", self, "NoiseChanged"):
			n.connect("changed", self, "NoiseChanged")
	
func BiomesGet():
	return Biomes

func MaterialSet(value):
	Material = value
	emit_signal("changed")
	
func MaterialGet():
	return Material

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
	for n in Noise:
		if not n.is_connected("changed", self, "NoiseChanged"):
			n.connect("changed", self, "NoiseChanged")

func NoiseChanged():
	emit_signal("changed")

func noiseGet():
	return Noise
	
func resGet():
	return Resolution

func CalculatePointOnPlanet(pointOnUnitSphere : Vector3) -> Vector3:
	var elevation : float = 0.0
	var base_elevation = 0.0
	if Noise.size() > 0:
		base_elevation = Noise[0].Noise.get_noise_3dv(pointOnUnitSphere) * Noise[0].Amplitude
	for n in Noise:
		if n.Enabled:
			var mask = 1.0
			if n.UseFirstLayerAsMask:
				mask = base_elevation
			elevation += n.Noise.get_noise_3dv(pointOnUnitSphere) * n.Amplitude * mask
	elevation = max(0, elevation - MinValue)
	return pointOnUnitSphere * Radius * (1+elevation)
	
func UpdateBiomeTexture():
	var imageTexture = ImageTexture.new()
	var dynImage = Image.new()
	
	var h : int = Biomes.size()
	if h > 0:
		var data : PoolByteArray
		var w : int = Biomes[0].gradient.width
		#data.resize(w * h)
		#dynImage.create(w, h, false, Image.FORMAT_RGBA8)
		for b in Biomes:
			data.append_array(b.gradient.get_data().get_data())
		dynImage.create_from_data(w,h,false,Image.FORMAT_RGBA8, data)
	
		imageTexture.create_from_image(dynImage, 4)
		imageTexture.resource_name = "The created texture!"
		
	return imageTexture

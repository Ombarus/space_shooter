tool
extends Spatial

export(Resource) var ShapeSource setget shapeSet, shapeGet
export var localUp : Vector3 setget localUpSet, localUpGet

var _arrays := []
var axisA : Vector3
var axisB : Vector3
var min_height : float
var max_height : float

func shapeSet(value):
	ShapeSource = value
	_ready()

func shapeGet():
	return ShapeSource

func localUpSet(value):
	localUp = value
	_ready()

func localUpGet():
	return localUp
	
func shapeSource_changed():
	_ready()

func _ready():
	if !is_inside_tree():
		return
	if ShapeSource.disable_generation:
		return
	if !ShapeSource.is_connected("changed", self, "shapeSource_changed"):
		ShapeSource.connect("changed", self, "shapeSource_changed")
	axisA = Vector3(localUp.y, localUp.z, localUp.x)
	axisB = localUp.cross(axisA)
	
	_arrays.resize(Mesh.ARRAY_MAX)
	var normal_array := PoolVector3Array()
	var uv_array := PoolVector2Array()
	var vertex_array := PoolVector3Array()
	var index_array := PoolIntArray()
	var resolution : int = (ShapeSource as ShapeGenerator).Resolution
		
	var num_vertices : int = resolution * resolution
	var num_indices : int = (resolution-1) * (resolution-1) * 6
	
	normal_array.resize(num_vertices)
	uv_array.resize(num_vertices)
	vertex_array.resize(num_vertices)
	index_array.resize(num_indices)
	
	var triIndex : int = 0
	min_height = 999999.0
	max_height = -999999.0
	for y in range(resolution):
		for x in range(resolution):
			var i : int = x + y * resolution
			var percent := Vector2(x,y) / (resolution-1)
			var pointOnUnitCube : Vector3 = localUp + (percent.x - 0.5) * 2 * axisA + (percent.y - 0.5) * 2 * axisB
			var pointOnUnitSphere = pointOnUnitCube.normalized()
			pointOnUnitCube = ShapeSource.CalculatePointOnPlanet(pointOnUnitSphere)
			vertex_array[i] = pointOnUnitCube
			normal_array[i] = Vector3.ZERO
			uv_array[i] = Vector2(BiomePercentFromPoint(pointOnUnitSphere), 0.0)
			var l = pointOnUnitCube.length()
			if l < min_height:
				min_height = l
			if l > max_height:
				max_height = l
			
			if x != resolution-1 and y != resolution-1:
				index_array[triIndex+2] = i
				index_array[triIndex+1] = i+resolution+1
				index_array[triIndex] = i+resolution
				
				index_array[triIndex+5] = i
				index_array[triIndex+4] = i+1
				index_array[triIndex+3] = i+resolution+1
				triIndex += 6
	
	# recalculate normals
	for a in range(0, index_array.size(), 3):
		var b : int = a + 1
		var c : int = a + 2
		var ab : Vector3 = vertex_array[index_array[b]] - vertex_array[index_array[a]]
		var bc : Vector3 = vertex_array[index_array[c]] - vertex_array[index_array[b]]
		var ca : Vector3 = vertex_array[index_array[a]] - vertex_array[index_array[c]]
		var cross_ab_bc : Vector3 = ab.cross(bc) * -1.0
		var cross_bc_ca : Vector3 = bc.cross(ca) * -1.0
		var cross_ca_ab : Vector3 = ca.cross(ab) * -1.0
		normal_array[index_array[a]] += cross_ab_bc + cross_bc_ca + cross_ca_ab
		normal_array[index_array[b]] += cross_ab_bc + cross_bc_ca + cross_ca_ab
		normal_array[index_array[c]] += cross_ab_bc + cross_bc_ca + cross_ca_ab
	for i in range(normal_array.size()):
		normal_array[i] = normal_array[i].normalized()
		
	#for y in range(resolution):
	#	for x in range(resolution):
	#		var i : int = x + y * resolution
			

	# PoolXArray are copy-on-write, so if I'm planning to modify it in a loop I should do it with a Array reference
	# and only set the PoolXArray of UVs once per frame!
	_arrays[Mesh.ARRAY_VERTEX] = vertex_array
	_arrays[Mesh.ARRAY_NORMAL] = normal_array
	_arrays[Mesh.ARRAY_TEX_UV] = uv_array
	_arrays[Mesh.ARRAY_INDEX] = index_array
	
	call_deferred("_update_mesh")
	
func BiomePercentFromPoint(pointOnUnitSphere : Vector3) -> float:
	var heightPercent : float = (pointOnUnitSphere.y + 1.0) / 2.0
	heightPercent += (ShapeSource.BiomeNoise.get_noise_3dv(pointOnUnitSphere)-ShapeSource.BiomeNoiseOffset) * ShapeSource.BiomeNoiseAmplitude
	var biomeIndex : float = 0
	var numBiomes : float = ShapeSource.Biomes.size()
	var blendRange : float = ShapeSource.blendAmount / 2.0 + 0.001
	for i in range(numBiomes):
		var dst : float = heightPercent - ShapeSource.Biomes[i].startHeight
		var lerp_val = clamp(inverse_lerp(-blendRange, blendRange, dst), 0.0, 1.0)
		var weight : float = lerp_val
		biomeIndex *= (1 - weight)
		biomeIndex += i * weight
	return biomeIndex / max(1, numBiomes - 1);
	
func _update_mesh():
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	self.mesh = _mesh
	
	self.set("material/0", ShapeSource.Material)
	self.get("material/0").set_shader_param("min_height", min_height*0.95)
	self.get("material/0").set_shader_param("max_height", max_height*1.05)
	var tex = ShapeSource.UpdateBiomeTexture()
	self.get("material/0").set_shader_param("height_color", tex)
	#get_node("../CanvasLayer/TextureRect").texture = tex

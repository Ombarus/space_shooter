tool
extends Spatial

export(Resource) var ShapeSource setget shapeSet, shapeGet
export var localUp : Vector3 setget localUpSet, localUpGet

var _arrays := []
var axisA : Vector3
var axisB : Vector3

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
	for y in range(resolution):
		for x in range(resolution):
			var i : int = x + y * resolution
			var percent := Vector2(x,y) / (resolution-1)
			var pointOnUnitCube = localUp + (percent.x - 0.5) * 2 * axisA + (percent.y - 0.5) * 2 * axisB
			pointOnUnitCube = pointOnUnitCube.normalized()
			pointOnUnitCube = ShapeSource.CalculatePointOnPlanet(pointOnUnitCube)
			vertex_array[i] = pointOnUnitCube
			normal_array[i] = Vector3.ZERO
			
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
		var cross_ab_bc : Vector3 = ab.cross(bc)
		var cross_bc_ca : Vector3 = bc.cross(ca)
		var cross_ca_ab : Vector3 = ca.cross(ab)
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
	#_arrays[Mesh.ARRAY_TEX_UV] = PoolVector2Array(uv_array)
	_arrays[Mesh.ARRAY_INDEX] = index_array
	
	#yield(get_tree(), "idle_frame")
	
	call_deferred("_update_mesh")
	
func _update_mesh():
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	self.mesh = _mesh

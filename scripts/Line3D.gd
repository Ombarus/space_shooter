extends MeshInstance

enum ORIENTATION {
	UP,
	DOWN
}

enum SEGMENT_INTERSECTION_RESULT {
	PARALLEL,
	NO_INTERSECT,
	INTERSECT
}

enum LINE_CAP_MODE {
	CAP_NONE,
	CAP_BOX,
	CAP_ROUND
}

enum LINE_JOINT_MODE {
	SHARP,
	BEVEL,
	ROUND
}

enum LINE_TEXTURE_MODE {
	NONE,
	TILE,
	STRETCH
}

export var UpdateEditor : bool setget set_update_editor
export var ShowWireframe : bool
export var LinePointList := []
export var LineWidth := 100.0
export var LineColor := Color.blue
export var Loop := false
export var SharpLimit := 2.0
export var JointMode := LINE_JOINT_MODE.SHARP
export var CapMode := LINE_CAP_MODE.CAP_BOX
export var RoundPrecision := 8
export var TextureMode := LINE_TEXTURE_MODE.STRETCH

var _vertices := []
var _uvs := []
var _indices := []
var _colors := []
var _last_index := [0, 0]
var _cur_alpha : float = 1.0

func set_update_editor(val):
	update_visual()
	
func _ready():
	update_visual()

func update_visual():
	if LinePointList.size() <= 1 || LineWidth == 0.0:
		return
	
	_vertices.clear()
	_uvs.clear()
	_indices.clear()
	_colors.clear()
	_last_index = [0, 0]
	_cur_alpha = 0.0
	LineColor.a = _cur_alpha
	
	var num_point : int = LinePointList.size()
	var start_i : int = 1
	var end_i : int = num_point - 1
	
	if Loop:
		start_i = -1
		end_i = num_point + 1
		
	var next_i : int = (start_i + 1) % num_point
	var hw : float = LineWidth / 2.0
	var hw_sq : float = hw * hw
	
	var pos0 : Vector2 = to_vec2(LinePointList[0])
	var pos1 : Vector2 = to_vec2(LinePointList[1])
	if Loop:
		pos0 = to_vec2(LinePointList[num_point-1])
		pos1 = to_vec2(LinePointList[0])
		
	var f0 : Vector2 = (pos1-pos0).normalized()
	var u0 : Vector2 = rotate_90(f0)
	var pos_up0 : Vector2 = pos0
	var pos_down0 : Vector2 = pos0
	
	var current_distance0 := 0.0
	var current_distance1 := 0.0
	var total_distance := 0.0
	var width_factor := 1.0
	var sharp_limit := 2.0
	var sharp_limit_sq : float = sharp_limit * sharp_limit
	var distance_required : bool = TextureMode == LINE_TEXTURE_MODE.TILE || TextureMode == LINE_TEXTURE_MODE.STRETCH
	var tile_aspect := 1.0
	
	if distance_required:
		total_distance = calculate_total_distance(LinePointList)
		if CapMode == LINE_CAP_MODE.CAP_BOX || CapMode == LINE_CAP_MODE.CAP_ROUND:
			total_distance += LineWidth
			total_distance += LineWidth * 0.5
	
	var uvx0 := 0.0
	var uvx1 := 0.0
	pos_up0 += u0 * hw * width_factor
	pos_down0 -= u0 * hw * width_factor
	
	if not Loop and CapMode == LINE_CAP_MODE.CAP_BOX:
		pos_up0 -= f0 * hw * width_factor
		pos_down0 -= f0 * hw * width_factor

		current_distance0 += hw * width_factor
		current_distance1 = current_distance0
	elif not Loop and CapMode == LINE_CAP_MODE.CAP_ROUND:
		if TextureMode == LINE_TEXTURE_MODE.TILE:
			uvx0 = width_factor * 0.5 / tile_aspect
		elif TextureMode == LINE_TEXTURE_MODE.STRETCH:
			uvx0 = LineWidth * width_factor / total_distance
		new_arc(pos0, pos_up0 - pos0, -PI, LineColor, Rect2(0.0, 0.0, uvx0 * 2.0, 1.0))
		current_distance0 += hw * width_factor;
		current_distance1 = current_distance0;
		
	if not Loop:
		strip_begin(pos_up0, pos_down0, uvx0)
		
	var pos_up1 : Vector2
	var pos_down1 : Vector2
	
	for i in range(start_i, end_i):
		next_i = (i + 1) % num_point
		if i < 0:
			pos1 = to_vec2(LinePointList[num_point-1])
		else:
			pos1 = to_vec2(LinePointList[i % num_point])
		var pos2 : Vector2 = to_vec2(LinePointList[next_i])
		
		_cur_alpha = 1.0 - clamp((float(end_i) - float(i)) / float(end_i), 0.0, 1.0)
		LineColor.a = _cur_alpha
		
		var f1 : Vector2 = (pos2 - pos1).normalized()
		var u1 : Vector2 = rotate_90(f1)
		
		var dp : float = u0.dot(f1)
		var orientation = ORIENTATION.UP if dp > 0.0 else ORIENTATION.DOWN
		
		if distance_required:
			current_distance1 += pos0.distance_to(pos1)
		
		var inner_normal0 : Vector2
		var inner_normal1 : Vector2
		if orientation == ORIENTATION.UP:
			inner_normal0 = u0 * hw * width_factor
			inner_normal1 = u1 * hw * width_factor
		else:
			inner_normal0 = -u0 * hw * width_factor
			inner_normal1 = -u1 * hw * width_factor
			
		var corner_pos_in : Vector2
		var corner_pos_out : Vector2
		var results = segment_intersection(
			pos0 + inner_normal0, pos1 + inner_normal0,
			pos1 + inner_normal1, pos2 + inner_normal1
		)
		corner_pos_in = results[1]
		var intersection_result = results[0]
		if intersection_result == SEGMENT_INTERSECTION_RESULT.INTERSECT:
			corner_pos_out = 2.0 * pos1 - corner_pos_in
		else:
			corner_pos_in = pos1 + inner_normal0;
			corner_pos_out = pos1 - inner_normal0;
			
		var corner_pos_up : Vector2
		var corner_pos_down : Vector2
		if orientation == ORIENTATION.UP:
			corner_pos_up = corner_pos_in
			corner_pos_down = corner_pos_out
		else:
			corner_pos_up = corner_pos_out
			corner_pos_down = corner_pos_in
		
		var current_joint_mode = JointMode
		if intersection_result == SEGMENT_INTERSECTION_RESULT.INTERSECT:
			var width_factor_sq : float = width_factor * width_factor
			if current_joint_mode == LINE_JOINT_MODE.SHARP and corner_pos_out.distance_squared_to(pos1) / (hw_sq * width_factor_sq) > sharp_limit_sq:
				current_joint_mode = LINE_JOINT_MODE.BEVEL
			if current_joint_mode == LINE_JOINT_MODE.SHARP:
				pos_up1 = corner_pos_up
				pos_down1 = corner_pos_down
			else:
				if orientation == ORIENTATION.UP:
					pos_up1 = corner_pos_up;
					pos_down1 = pos1 - u0 * hw * width_factor
				else:
					pos_up1 = pos1 + u0 * hw * width_factor
					pos_down1 = corner_pos_down
		else:
			if current_joint_mode == LINE_JOINT_MODE.SHARP:
				current_joint_mode = LINE_JOINT_MODE.BEVEL
			pos_up1 = corner_pos_up
			pos_down1 = corner_pos_down
			
		if TextureMode == LINE_TEXTURE_MODE.TILE:
			uvx1 = current_distance1 / (LineWidth * tile_aspect)
		elif TextureMode == LINE_TEXTURE_MODE.STRETCH:
			uvx1 = current_distance1 / total_distance
			
		if i > 0:
			strip_add_quad(pos_up1, pos_down1, uvx1)
			
		u0 = u1
		f0 = f1
		pos0 = pos1
		if intersection_result == SEGMENT_INTERSECTION_RESULT.INTERSECT:
			if current_joint_mode == LINE_JOINT_MODE.SHARP:
				pos_up0 = pos_up1
				pos_down0 = pos_down1
			else:
				if orientation == ORIENTATION.UP:
					pos_up0 = corner_pos_up
					pos_down0 = pos1 - u1 * hw * width_factor
				else:
					pos_up0 = pos1 + u1 * hw * width_factor
					pos_down0 = corner_pos_down
		else:
			pos_up0 = pos1 + u1 * hw * width_factor
			pos_down0 = pos1 - u1 * hw * width_factor
			
		var cbegin : Vector2
		var cend : Vector2
		if orientation == ORIENTATION.UP:
			cbegin = pos_down1
			cend = pos_down0
		else:
			cbegin = pos_up1
			cend = pos_up0
		
		if i > 0 and current_joint_mode == LINE_JOINT_MODE.BEVEL:
			strip_add_tri(cend, orientation)
		elif i > 0 and current_joint_mode == LINE_JOINT_MODE.ROUND:
			var vbegin : Vector2 = cbegin - pos1
			var vend : Vector2 = cend - pos1
			strip_add_arc(pos1, vbegin.angle_to(vend), orientation)
			
		if intersection_result == SEGMENT_INTERSECTION_RESULT.INTERSECT:
			strip_begin(pos_up0, pos_down0, uvx1)
		
	var last_index : int = end_i
	pos1 = to_vec2(LinePointList[last_index % num_point])
	if distance_required:
		current_distance1 += pos0.distance_to(pos1)
		
	pos_up1 = pos1 + u0 * hw * width_factor
	pos_down1 = pos1 - u0 * hw * width_factor
	
	if CapMode == LINE_CAP_MODE.CAP_BOX:
		pos_up1 += f0 * hw * width_factor
		pos_down1 += f0 * hw * width_factor

	if TextureMode == LINE_TEXTURE_MODE.TILE:
		uvx1 = current_distance1 / (LineWidth * tile_aspect)
	elif TextureMode == LINE_TEXTURE_MODE.STRETCH:
		uvx1 = current_distance1 / total_distance

	if not Loop:
		strip_add_quad(pos_up1, pos_down1, uvx1)

	if not Loop and CapMode == LINE_CAP_MODE.CAP_ROUND:
		var dist := 0.0
		if TextureMode == LINE_TEXTURE_MODE.TILE:
			dist = width_factor / tile_aspect
		elif TextureMode == LINE_TEXTURE_MODE.STRETCH:
			dist = LineWidth * width_factor / total_distance
		new_arc(pos1, pos_up1 - pos1, PI, LineColor, Rect2(uvx1 - 0.5 * dist, 0.0, dist, 1.0))
		
	var _arrays := []
	_arrays.resize(Mesh.ARRAY_MAX)
	_arrays[Mesh.ARRAY_VERTEX] = PoolVector3Array(_vertices)
	_arrays[Mesh.ARRAY_TEX_UV] = PoolVector2Array(_uvs)
	_arrays[Mesh.ARRAY_INDEX] = PoolIntArray(_indices)
	_arrays[Mesh.ARRAY_COLOR] = PoolColorArray(_colors)
	
	var _mesh := ArrayMesh.new()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	#_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, _arrays)
	mesh = _mesh

	if ShowWireframe:
		var m := MeshInstance2D.new()
		var wire_mesh := ArrayMesh.new()
		for i in range(len(_colors)):
			_colors[i] = Color.white
		_arrays[Mesh.ARRAY_COLOR] = PoolColorArray(_colors)
		wire_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, _arrays)
		m.mesh = wire_mesh
		add_child(m)
	
	
	
	
	
func rotate_90(var v : Vector2) -> Vector2:
	return Vector2(v.y, -v.x)
	
func calculate_total_distance(var points : Array) -> float:
	var d := 0.0
	for i in range(1, points.size()):
		d += points[i].distance_to(points[i-1])
	return d
	
func new_arc(center : Vector2, vbegin : Vector2, angle_delta : float, color : Color, uv_rect : Rect2):
	var radius : float = vbegin.length()
	var angle_step : float = PI / RoundPrecision
	var steps : float = abs(angle_delta) / angle_step
	if angle_delta < 0.0:
		angle_step = -angle_step
		
	var t : float = Vector2.RIGHT.angle_to(vbegin)
	var end_angle : float = t + angle_delta
	var rpos := Vector2.ZERO
	var tt_begin : float = -PI / 2.0
	var tt : float = tt_begin
	
	var vi : int = _vertices.size()
	print("Adding vertex : " + str(center))
	_vertices.append(to_vec3(center))
	_colors.append(LineColor)
	if TextureMode != LINE_TEXTURE_MODE.NONE:
		_uvs.append(interpolate(uv_rect, Vector2(0.5, 0.5)))
		
	var sc : Vector2
	for ti in range(0, steps, angle_step):
		sc = Vector2(cos(t), sin(t))
		rpos = center + sc * radius
		print("Adding vertex : " + str(rpos))
		_vertices.append(to_vec3(rpos))
		_colors.append(LineColor)
		if TextureMode != LINE_TEXTURE_MODE.NONE:
			var tsc := Vector2(cos(tt), sin(tt))
			_uvs.append(interpolate(uv_rect, 0.5 * (tsc + Vector2.ONE)))
			tt += angle_step
			
	sc = Vector2(cos(end_angle), sin(end_angle))
	rpos = center + sc * radius
	print("Adding vertex : " + str(rpos))
	_vertices.append(to_vec3(rpos))
	_colors.append(LineColor)
	if TextureMode != LINE_TEXTURE_MODE.NONE:
		tt = tt_begin + angle_delta
		var tsc := Vector2(cos(tt), sin(tt))
		_uvs.append(interpolate(uv_rect, 0.5 * (tsc + Vector2.ONE)))
		
	var vi0 : int = vi
	for ti in range(0, steps):
		_indices.append(vi0)
		_indices.append(++vi)
		_indices.append(vi+1)
	
	
func interpolate(var r : Rect2, var v : Vector2) -> Vector2:
	return Vector2(lerp(r.position.x, r.position.x + r.size.x, v.x),
		lerp(r.position.y, r.position.y + r.size.y, v.y))
		
func strip_begin(var up : Vector2, var down : Vector2, var uvx : float):
	var vi : int = _vertices.size()
	print("Adding vertex : " + str(up))
	_vertices.append(to_vec3(up))
	_colors.append(LineColor)
	print("Adding vertex : " + str(down))
	_vertices.append(to_vec3(down))
	_colors.append(LineColor)
	
	if TextureMode != LINE_TEXTURE_MODE.NONE:
		_uvs.append(Vector2(uvx, 0.0))
		_uvs.append(Vector2(uvx, 1.0))

	_indices.append(_last_index[ORIENTATION.UP])
	_indices.append(vi + 1)
	_indices.append(_last_index[ORIENTATION.DOWN])
	_indices.append(_last_index[ORIENTATION.UP])
	_indices.append(vi)
	_indices.append(vi + 1)

	_last_index[ORIENTATION.UP] = vi
	_last_index[ORIENTATION.DOWN] = vi + 1

func segment_intersection(var a : Vector2, var b : Vector2, var c : Vector2, var d : Vector2) -> Array:
	# http://paulbourke.net/geometry/pointlineplane/ <-- Good stuff
	var cd : Vector2 = d - c
	var ab : Vector2 = b - a
	var div : float = cd.y * ab.x - cd.x * ab.y
	var out_intersection := Vector2.ZERO
	if abs(div) > 0.001:
		var ua : float = (cd.x * (a.y - c.y) - cd.y * (a.x - c.x)) / div
		var ub : float = (ab.x * (a.y - c.y) - ab.y * (a.x - c.x)) / div
		out_intersection = a + ua * ab
		if ua >= 0.0 && ua <= 1.0 && ub >= 0.0 && ub <= 1.0:
			return [SEGMENT_INTERSECTION_RESULT.INTERSECT, out_intersection]
		return [SEGMENT_INTERSECTION_RESULT.NO_INTERSECT, out_intersection]
	return [SEGMENT_INTERSECTION_RESULT.PARALLEL, out_intersection]
	
func strip_add_quad(var up : Vector2, var down : Vector2, var uvx : float):
	var vi : int = _vertices.size();
	print("Adding vertex : " + str(up))
	_vertices.append(to_vec3(up))
	_colors.append(LineColor)
	print("Adding vertex : " + str(down))
	_vertices.append(to_vec3(down))
	_colors.append(LineColor)

	if TextureMode != LINE_TEXTURE_MODE.NONE:
		_uvs.append(Vector2(uvx, 0.0))
		_uvs.append(Vector2(uvx, 1.0))

	_indices.append(_last_index[ORIENTATION.UP])
	_indices.append(vi + 1)
	_indices.append(_last_index[ORIENTATION.DOWN])
	_indices.append(_last_index[ORIENTATION.UP])
	_indices.append(vi)
	_indices.append(vi + 1)

	_last_index[ORIENTATION.UP] = vi
	_last_index[ORIENTATION.DOWN] = vi + 1

func strip_add_tri(var up : Vector2, var orientation):
	var vi : int = _vertices.size()
	print("Adding vertex : " + str(up))
	_vertices.append(to_vec3(up))
	_colors.append(LineColor)
	var opposite_orientation = ORIENTATION.DOWN if orientation == ORIENTATION.UP else ORIENTATION.UP

	if TextureMode != LINE_TEXTURE_MODE.NONE:
		_uvs.append(_uvs[_last_index[opposite_orientation]])

	_indices.append(_last_index[opposite_orientation])
	_indices.append(vi)
	_indices.append(_last_index[orientation])
	_last_index[opposite_orientation] = vi

func strip_add_arc(var center : Vector2, var angle_delta : float, var orientation):
	var opposite_orientation = ORIENTATION.DOWN if orientation == ORIENTATION.UP else ORIENTATION.UP
	var vbegin : Vector2 = to_vec2(_vertices[_last_index[opposite_orientation]] - to_vec3(center))
	var radius : float = vbegin.length()
	var angle_step : float = PI / float(RoundPrecision)
	var steps : float = abs(angle_delta) / angle_step

	if angle_delta < 0.0:
		angle_step = -angle_step

	var t : float = Vector2.RIGHT.angle_to(vbegin)
	var end_angle : float = t + angle_delta
	var rpos := Vector2.ZERO

	for ti in range(0, steps):
		rpos = center + Vector2(cos(t), sin(t)) * radius
		strip_add_tri(rpos, orientation)
		t += angle_step

	rpos = center + Vector2(cos(end_angle), sin(end_angle)) * radius
	strip_add_tri(rpos, orientation)

func to_vec3(vec2 : Vector2) -> Vector3:
	return Vector3(vec2.x, 0.0, vec2.y)

func to_vec2(vec3 : Vector3) -> Vector2:
	return Vector2(vec3.x, vec3.z)

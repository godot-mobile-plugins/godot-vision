#
# © 2024-present https://github.com/cengiz-pz
#

class_name FaceMeshInfo extends RefCounted

const POINTS_PROPERTY := &"points"
const TRIANGLES_PROPERTY := &"triangles"
const CONTOURS_PROPERTY := &"contours"

const CONTOUR_FACE_OVAL := &"face_oval"
const CONTOUR_LEFT_EYE := &"left_eye"
const CONTOUR_LEFT_EYEBROW_BOTTOM := &"left_eyebrow_bottom"
const CONTOUR_LEFT_EYEBROW_TOP := &"left_eyebrow_top"
const CONTOUR_LOWER_LIP_BOTTOM := &"lower_lip_bottom"
const CONTOUR_LOWER_LIP_TOP := &"lower_lip_top"
const CONTOUR_NOSE_BRIDGE := &"nose_bridge"
const CONTOUR_RIGHT_EYE := &"right_eye"
const CONTOUR_RIGHT_EYEBROW_BOTTOM := &"right_eyebrow_bottom"
const CONTOUR_RIGHT_EYEBROW_TOP := &"right_eyebrow_top"
const CONTOUR_UPPER_LIP_BOTTOM := &"upper_lip_bottom"
const CONTOUR_UPPER_LIP_TOP := &"upper_lip_top"

var _data: Dictionary


func _init(a_data: Dictionary):
	_data = a_data


# Returns all 468 mesh points as an Array of Vector3.
# x and y are normalised to [0, 1]; z is relative depth.
func get_points() -> Array:
	if not _data.has(POINTS_PROPERTY):
		return []
	var result: Array = []
	for raw in _data[POINTS_PROPERTY]:
		result.append(Vector3(raw[0], raw[1], raw[2]))
	return result


# Returns all mesh triangles as an Array of Vector3i.
# Each component (x, y, z) is an index into the get_points() array.
func get_triangles() -> Array:
	if not _data.has(TRIANGLES_PROPERTY):
		return []
	var result: Array = []
	for raw in _data[TRIANGLES_PROPERTY]:
		result.append(Vector3i(raw[0], raw[1], raw[2]))
	return result


# Returns the raw contours Dictionary keyed by contour name.
# Each value is an Array of [x, y, z] sub-arrays (not yet converted to Vector3).
# Use get_contour() for a ready-to-use Array of Vector3 for a single contour.
func get_contours() -> Dictionary:
	return _data[CONTOURS_PROPERTY] if _data.has(CONTOURS_PROPERTY) else {}


# Returns the points of a named contour as an Array of Vector3.
# Use the CONTOUR_* constants for the contour name, e.g.:
#   face_mesh_info.get_contour(FaceMeshInfo.CONTOUR_FACE_OVAL)
func get_contour(a_contour_name: String) -> Array:
	if not _data.has(CONTOURS_PROPERTY):
		return []
	var contours: Dictionary = _data[CONTOURS_PROPERTY]
	if not contours.has(a_contour_name):
		return []
	var result: Array = []
	for raw in contours[a_contour_name]:
		result.append(Vector3(raw[0], raw[1], raw[2]))
	return result


func is_valid() -> bool:
	return _data.has(POINTS_PROPERTY) and _data.has(TRIANGLES_PROPERTY) and _data.has(CONTOURS_PROPERTY)


func get_raw_data() -> Dictionary:
	return _data

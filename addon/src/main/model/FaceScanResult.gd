#
# © 2024-present https://github.com/cengiz-pz
#

class_name FaceScanResult extends RefCounted

const IMAGE_WIDTH_PROPERTY := &"image_width"
const IMAGE_HEIGHT_PROPERTY := &"image_height"
const FACES_PROPERTY := &"faces"

var _data: Dictionary


func _init(a_data: Dictionary):
	_data = a_data


func get_image_width() -> int:
	return _data[IMAGE_WIDTH_PROPERTY] if _data.has(IMAGE_WIDTH_PROPERTY) else 0


func get_image_height() -> int:
	return _data[IMAGE_HEIGHT_PROPERTY] if _data.has(IMAGE_HEIGHT_PROPERTY) else 0


func get_face_count() -> int:
	return _data[FACES_PROPERTY].size() if _data.has(FACES_PROPERTY) else 0


# Returns the FaceMeshInfo at the given index, or null if out of range.
func get_face(a_index: int) -> FaceMeshInfo:
	if not _data.has(FACES_PROPERTY):
		return null
	var faces: Array = _data[FACES_PROPERTY]
	if a_index < 0 or a_index >= faces.size():
		return null
	return FaceMeshInfo.new(faces[a_index])


# Returns all detected faces as an Array of FaceMeshInfo.
func get_faces() -> Array:
	if not _data.has(FACES_PROPERTY):
		return []
	var result: Array = []
	for raw_face in _data[FACES_PROPERTY]:
		result.append(FaceMeshInfo.new(raw_face))
	return result


func is_valid() -> bool:
	return _data.has(IMAGE_WIDTH_PROPERTY) and _data.has(IMAGE_HEIGHT_PROPERTY) and _data.has(FACES_PROPERTY)


func get_raw_data() -> Dictionary:
	return _data

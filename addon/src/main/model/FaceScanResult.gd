#
# © 2024-present https://github.com/cengiz-pz
#

class_name FaceScanResult extends RefCounted

const IMAGE_PROPERTY := &"image"
const FACES_PROPERTY := &"faces"

var _data: Dictionary


func _init(a_data: Dictionary):
	_data = a_data


## Returns the ImageInfo object for the image that was processed.
## All image properties (width, height, buffer, format, has_mipmaps) are
## available on the returned object via its accessor methods.
func get_image() -> ImageInfo:
	return ImageInfo.new(_data[IMAGE_PROPERTY]) if _data.has(IMAGE_PROPERTY) else null


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
	return _data.has(IMAGE_PROPERTY) and _data.has(FACES_PROPERTY)


func get_raw_data() -> Dictionary:
	return _data

#
# © 2026-present https://github.com/cengiz-pz
#

@tool
@icon("icon.png")
class_name Vision extends Node

signal face_mesh_ready(result: FaceScanResult)
signal face_mesh_failed(error: VisionScanError)

const PLUGIN_SINGLETON_NAME: String = "@pluginName@"

var _plugin_singleton: Object


func _ready() -> void:
	_update_plugin()


func _notification(a_what: int) -> void:
	if a_what == NOTIFICATION_APPLICATION_RESUMED:
		_update_plugin()


func _update_plugin() -> void:
	if _plugin_singleton == null:
		if Engine.has_singleton(PLUGIN_SINGLETON_NAME):
			_plugin_singleton = Engine.get_singleton(PLUGIN_SINGLETON_NAME)
			_connect_signals()
		elif not Engine.is_editor_hint():
			Vision.log_error("%s singleton not found on this platform!" % PLUGIN_SINGLETON_NAME)


func _connect_signals() -> void:
	_plugin_singleton.connect("face_mesh_ready", _on_face_mesh_ready)
	_plugin_singleton.connect("face_mesh_failed", _on_face_mesh_failed)


# ---------------------------------------------------------------------------
# scan_face
# Sends an image to the Android plugin for ML Kit face mesh detection.
# The image is automatically converted to FORMAT_RGBA8 when necessary.
# Listen to the face_mesh_ready / face_mesh_failed signals for results.
# ---------------------------------------------------------------------------
func scan_face(a_image: Image) -> void:
	if _plugin_singleton:
		# ML Kit expects RGBA8 raw bytes (matches Godot's FORMAT_RGBA8 layout).
		var scan_image := a_image
		if scan_image.get_format() != Image.FORMAT_RGBA8:
			scan_image = Image.new()
			scan_image.copy_from(a_image)
			scan_image.convert(Image.FORMAT_RGBA8)

		_plugin_singleton.scan_face(VisionImageInfo.create_from_image(scan_image).get_raw_data())
	else:
		log_error("%s plugin not initialized" % PLUGIN_SINGLETON_NAME)


func _on_face_mesh_ready(a_dict: Dictionary) -> void:
	face_mesh_ready.emit(FaceScanResult.new(a_dict))


func _on_face_mesh_failed(a_dict: Dictionary) -> void:
	face_mesh_failed.emit(VisionScanError.new(a_dict))


# ===========================================================================
# FACE MESH DRAWING UTILITIES
#
# Both methods accept the FaceScanResult emitted by the face_mesh_ready signal.
# Its structure (set by VisionPlugin.java) is:
#
#   FaceScanResult
#     get_image_width()  -> int
#     get_image_height() -> int
#     get_faces()        -> Array[FaceMeshInfo]
#       FaceMeshInfo
#         get_points()    -> Array[Vector3]   # 468 landmarks, x/y ∈ [0,1]
#         get_triangles() -> Array[Vector3i]  # indices into points
# ===========================================================================

# ---------------------------------------------------------------------------
# generate_face_mesh_image
#
# Returns a new Image (FORMAT_RGBA8) of the given dimensions whose background
# is fully transparent and whose pixels show the face mesh wireframe in
# a_color.  The image can then be composited over the original camera frame
# as a separate layer.
#
# Parameters:
#   a_result – FaceScanResult from the face_mesh_ready signal
#   a_width  – pixel width of the output image (should match the source image)
#   a_height – pixel height of the output image
#   a_color  – Color for mesh edges (alpha is respected)
# ---------------------------------------------------------------------------
static func generate_face_mesh_image(
		a_result: FaceScanResult,
		a_width:  int,
		a_height: int,
		a_color:  Color) -> Image:

	var image := Image.create(a_width, a_height, false, Image.FORMAT_RGBA8)
	# fill() with a fully-transparent color gives us a clean canvas.
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	if not a_result.is_valid():
		return image

	for face in a_result.get_faces():
		_draw_face_mesh(image, face, a_width, a_height, a_color)

	return image


# ---------------------------------------------------------------------------
# draw_face_mesh_on_image
#
# Returns a NEW Image (FORMAT_RGBA8) that is a copy of a_original with the
# face mesh wireframe painted on top in a_color.  The original image is not
# modified.
#
# Parameters:
#   a_original – the source Image (any format; converted internally)
#   a_result   – FaceScanResult from the face_mesh_ready signal
#   a_color    – Color for mesh edges
# ---------------------------------------------------------------------------
static func draw_face_mesh_on_image(
		a_original: Image,
		a_result:   FaceScanResult,
		a_color:    Color) -> Image:

	var result := Image.new()
	result.copy_from(a_original)
	if result.get_format() != Image.FORMAT_RGBA8:
		result.convert(Image.FORMAT_RGBA8)

	if not a_result.is_valid():
		return result

	var img_w := result.get_width()
	var img_h := result.get_height()

	for face in a_result.get_faces():
		_draw_face_mesh(result, face, img_w, img_h, a_color)

	return result


# ---------------------------------------------------------------------------
# _draw_face_mesh  (private helper)
#
# Iterates over every triangle in a_face and draws its three edges onto
# a_image using Bresenham's line algorithm so that no external dependencies
# (CanvasItem, RenderingServer, etc.) are needed.
# ---------------------------------------------------------------------------
static func _draw_face_mesh(
		a_image:  Image,
		a_face:   FaceMeshInfo,
		a_width:  int,
		a_height: int,
		a_color:  Color) -> void:

	if not a_face.is_valid():
		return

	var points:    Array = a_face.get_points()    # Array of Vector3, x/y normalised
	var triangles: Array = a_face.get_triangles() # Array of Vector3i, xyz = point indices
	var n_points := points.size()

	for tri in triangles:
		var i0: int = tri.x
		var i1: int = tri.y
		var i2: int = tri.z

		# Guard against out-of-range indices from malformed data.
		if i0 >= n_points or i1 >= n_points or i2 >= n_points:
			continue

		# De-normalise landmark coordinates to pixel space.
		var p0 := Vector2i(
				int(points[i0].x * a_width),
				int(points[i0].y * a_height))
		var p1 := Vector2i(
				int(points[i1].x * a_width),
				int(points[i1].y * a_height))
		var p2 := Vector2i(
				int(points[i2].x * a_width),
				int(points[i2].y * a_height))

		_bresenham_line(a_image, p0, p1, a_width, a_height, a_color)
		_bresenham_line(a_image, p1, p2, a_width, a_height, a_color)
		_bresenham_line(a_image, p2, p0, a_width, a_height, a_color)


# ---------------------------------------------------------------------------
# _bresenham_line  (private helper)
#
# Draws a single-pixel-wide line between two integer pixel coordinates using
# Bresenham's classic algorithm.  Pixels outside the image bounds are silently
# skipped so no clamping is required by the caller.
# ---------------------------------------------------------------------------
static func _bresenham_line(
		a_image:  Image,
		a_from:   Vector2i,
		a_to:     Vector2i,
		a_width:  int,
		a_height: int,
		a_color:  Color) -> void:

	var x0 := a_from.x
	var y0 := a_from.y
	var x1 := a_to.x
	var y1 := a_to.y

	var dx :=  abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err = dx + dy  # Note: dy is already negative

	while true:
		if x0 >= 0 and x0 < a_width and y0 >= 0 and y0 < a_height:
			a_image.set_pixel(x0, y0, a_color)

		if x0 == x1 and y0 == y1:
			break

		var e2 = 2 * err
		if e2 >= dy:
			if x0 == x1:
				break
			err += dy
			x0  += sx
		if e2 <= dx:
			if y0 == y1:
				break
			err += dx
			y0  += sy


# ===========================================================================
# Logging helpers
# ===========================================================================

static func log_error(a_description: String) -> void:
	push_error("%s: %s" % [PLUGIN_SINGLETON_NAME, a_description])


static func log_warn(a_description: String) -> void:
	push_warning("%s: %s" % [PLUGIN_SINGLETON_NAME, a_description])


static func log_info(a_description: String) -> void:
	print_rich("[color=lime]%s: INFO: %s[/color]" % [PLUGIN_SINGLETON_NAME, a_description])

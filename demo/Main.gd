#
# © 2026-present https://github.com/cengiz-pz
#

@tool
extends Node

@export_color_no_alpha var mesh_color: Color = Color.BLUE

@onready var vision_node: Vision = $Vision
@onready var camera_node: NativeCamera = $NativeCamera
@onready var start_button := %StartButton as Button
@onready var stop_button := %StopButton as Button
@onready var scan_texture_rect := %ScanTextureRect as TextureRect
@onready var mesh_texture_rect := %MeshTextureRect as TextureRect
@onready var mesh_color_rect := %MeshColorRect as ColorRect
@onready var mesh_check_box: CheckBox = %MeshCheckBox
@onready var mustache_check_box: CheckBox = %MustacheCheckBox
@onready var glasses_check_box: CheckBox = %GlassesCheckBox
@onready var hat_check_box: CheckBox = %HatCheckBox
@onready var _label := %RichTextLabel as RichTextLabel
@onready var _android_texture_rect := %AndroidTextureRect as TextureRect
@onready var _ios_texture_rect := %iOSTextureRect as TextureRect

var _camera: CameraInfo
var _scan_texture: ImageTexture = null
var _mesh_texture: ImageTexture = null
var _last_image: Image

var _active_texture_rect: TextureRect


func _ready() -> void:
	if OS.has_feature("ios"):
		_android_texture_rect.hide()
		_active_texture_rect = _ios_texture_rect
	else:
		_ios_texture_rect.hide()
		_active_texture_rect = _android_texture_rect

	mesh_color_rect.color = mesh_color

	if not Engine.is_editor_hint():
		if camera_node.has_camera_permission():
			_get_cameras()
		else:
			camera_node.request_camera_permission()


func _on_start_button_pressed() -> void:
	if _camera:
		var __request := camera_node.create_feed_request().set_camera_id(_camera.get_camera_id())
		if OS.has_feature("ios"):
			__request.set_rotation(90)
		else:
			__request.set_rotation(camera_node.frame_rotation)
		camera_node.start(__request)
		start_button.disabled = true
		stop_button.disabled = false
		_print_to_screen("Camera started [id: %s]" % [_camera.get_camera_id()])
	else:
		_print_to_screen("No camera available", true)


func _on_stop_button_pressed() -> void:
	_do_stop()


func _do_stop() -> void:
	camera_node.stop()
	stop_button.disabled = true
	start_button.disabled = false
	# Clear the texture visually so we know it stopped
	scan_texture_rect.texture = null
	_scan_texture = null
	_print_to_screen("Camera stopped")


func _get_cameras() -> void:
	var __cameras: Array[CameraInfo] = camera_node.get_all_cameras()
	if __cameras.is_empty():
		_print_to_screen("No camera found!", true)
	else:
		for __camera: CameraInfo in __cameras:
			if __camera.is_front_facing():
				_camera = __camera
		start_button.disabled = false


func _update_scan_texture(image: Image) -> void:
	if _scan_texture == null:
		_scan_texture = ImageTexture.create_from_image(image)
		scan_texture_rect.texture = _scan_texture
	else:
		_scan_texture.update(image)


func _update_mesh_texture(image: Image) -> void:
	if _mesh_texture == null:
		_mesh_texture = ImageTexture.create_from_image(image)
		mesh_texture_rect.texture = _mesh_texture
	else:
		_mesh_texture.update(image)


func _on_native_camera_frame_available(a_info: FrameInfo) -> void:
	var image: Image = a_info.get_image()
	if image.is_empty():
		_print_to_screen("Received empty image!", true)
		return

	_print_to_screen("Scanning received frame")
	_last_image = image
	vision_node.scan_face(image)

	# Force execution on main thread
	call_deferred("_update_scan_texture", image)


func _on_native_camera_camera_permission_granted() -> void:
	_print_to_screen("Camera permission granted")
	_get_cameras()


func _on_native_camera_camera_permission_denied() -> void:
	_print_to_screen("Camera permission denied")


func _on_vision_face_mesh_ready(a_result: FaceScanResult) -> void:
	# Start from the mesh wireframe overlay or a plain copy of the camera frame.
	var __mesh_image: Image
	if mesh_check_box.button_pressed:
		__mesh_image = Vision.draw_face_mesh_on_image(_last_image, a_result, mesh_color)
	else:
		__mesh_image = Image.new()
		__mesh_image.copy_from(_last_image)
		if __mesh_image.get_format() != Image.FORMAT_RGBA8:
			__mesh_image.convert(Image.FORMAT_RGBA8)

	var __w := __mesh_image.get_width()
	var __h := __mesh_image.get_height()

	for __face: FaceMeshInfo in a_result.get_faces():
		# Draw hat first (sits behind face features in z-order).
		if hat_check_box.button_pressed:
			_draw_cowboy_hat(__mesh_image, __face, __w, __h)
		if glasses_check_box.button_pressed:
			_draw_glasses(__mesh_image, __face, __w, __h)
		if mustache_check_box.button_pressed:
			_draw_mustache(__mesh_image, __face, __w, __h)

	_update_mesh_texture(__mesh_image)


func _on_vision_face_mesh_failed(error: ScanError) -> void:
	_print_to_screen("Face mesh failed [%s] %s" % [ScanError.Code.keys()[error.get_code()], error.get_description()])


# ---------------------------------------------------------------------------
# _draw_mustache
#
# Paints a black droopy mustache on a_image for a single detected face.
# The body follows the upper_lip_top contour shifted just far enough above
# the lip edge to sit in the philtrum gap without touching the lip.
# ---------------------------------------------------------------------------
static func _draw_mustache(a_image: Image, a_face: FaceMeshInfo, a_w: int, a_h: int) -> void:
	var lip_pts: Array = a_face.get_contour(FaceMeshInfo.CONTOUR_UPPER_LIP_TOP)
	if lip_pts.is_empty():
		return

	# Convert normalised Vector3 landmarks to pixel-space Vector2.
	var px: Array = []
	for pt: Vector3 in lip_pts:
		px.append(Vector2(pt.x * a_w, pt.y * a_h))

	# Find the leftmost and rightmost corner points.
	var left: Vector2 = px[0]
	var right: Vector2 = px[0]
	for pt: Vector2 in px:
		if pt.x < left.x:
			left = pt
		if pt.x > right.x:
			right = pt

	var lip_w: float = right.x - left.x
	var shift_up: float = lip_w * 0.14  # just above the upper lip edge
	var extend_x: float = lip_w * 0.28  # how far past each corner the tip travels
	var droop_y: float = lip_w * 0.38  # how far down each tip droops
	var brush_r: int = max(10, int(lip_w * 0.18))  # doubled thickness

	# Build the mustache spine:
	#   droopy left tip -> left shoulder -> lip body (shifted up) -> right shoulder -> droopy right tip
	var spine: Array = []
	spine.append(Vector2(left.x - extend_x, left.y - shift_up + droop_y))  # left tip
	spine.append(Vector2(left.x - extend_x * 0.3, left.y - shift_up))  # left shoulder
	for pt: Vector2 in px:
		spine.append(Vector2(pt.x, pt.y - shift_up))  # lip body, raised
	spine.append(Vector2(right.x + extend_x * 0.3, right.y - shift_up))  # right shoulder
	spine.append(Vector2(right.x + extend_x, right.y - shift_up + droop_y))  # right tip

	# Paint each segment as a thick stroke, with gentle tapering toward the tips.
	var last: int = spine.size() - 2
	for i in range(last + 1):
		var t: float = float(i) / float(last)
		var taper: float = 1.0 - 0.35 * abs(t * 2.0 - 1.0)
		var r: int = max(2, int(brush_r * taper))
		_mustache_stroke(
			a_image,
			Vector2i(int(spine[i].x), int(spine[i].y)),
			Vector2i(int(spine[i + 1].x), int(spine[i + 1].y)),
			r,
			Color.BLACK,
			a_w,
			a_h
		)


# Stamps filled discs along the segment a_from->a_to to produce a thick stroke.
static func _mustache_stroke(
	a_image: Image, a_from: Vector2i, a_to: Vector2i, a_radius: int, a_color: Color, a_w: int, a_h: int
) -> void:
	var steps: int = max(abs(a_to.x - a_from.x), abs(a_to.y - a_from.y))
	if steps == 0:
		_mustache_disc(a_image, a_from, a_radius, a_color, a_w, a_h)
		return
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		_mustache_disc(
			a_image,
			Vector2i(int(lerpf(float(a_from.x), float(a_to.x), t)), int(lerpf(float(a_from.y), float(a_to.y), t))),
			a_radius,
			a_color,
			a_w,
			a_h
		)


# Fills every pixel within a_radius of a_centre with a_color.
static func _mustache_disc(
	a_image: Image, a_centre: Vector2i, a_radius: int, a_color: Color, a_w: int, a_h: int
) -> void:
	var r2: int = a_radius * a_radius
	for dy in range(-a_radius, a_radius + 1):
		for dx in range(-a_radius, a_radius + 1):
			if dx * dx + dy * dy <= r2:
				var px: int = a_centre.x + dx
				var py: int = a_centre.y + dy
				if px >= 0 and px < a_w and py >= 0 and py < a_h:
					a_image.set_pixel(px, py, a_color)


# ===========================================================================
# GLASSES
# ===========================================================================


# ---------------------------------------------------------------------------
# _draw_glasses
#
# Draws black-framed sunglasses anchored to the left_eye and right_eye
# contours. Each lens is a solid black ellipse (frame) with a semi-
# transparent black fill so the eye is faintly visible through the glass.
# The two lenses are joined by a thin bridge and have temples extending
# toward the ears.
# ---------------------------------------------------------------------------
static func _draw_glasses(a_image: Image, a_face: FaceMeshInfo, a_w: int, a_h: int) -> void:
	var l_pts: Array = a_face.get_contour(FaceMeshInfo.CONTOUR_LEFT_EYE)
	var r_pts: Array = a_face.get_contour(FaceMeshInfo.CONTOUR_RIGHT_EYE)
	if l_pts.is_empty() or r_pts.is_empty():
		return

	# Compute bounding boxes in pixel space for each eye contour.
	var l_min := Vector2(INF, INF)
	var l_max := Vector2(-INF, -INF)
	var r_min := Vector2(INF, INF)
	var r_max := Vector2(-INF, -INF)
	for pt: Vector3 in l_pts:
		var p := Vector2(pt.x * a_w, pt.y * a_h)
		l_min = Vector2(minf(l_min.x, p.x), minf(l_min.y, p.y))
		l_max = Vector2(maxf(l_max.x, p.x), maxf(l_max.y, p.y))
	for pt: Vector3 in r_pts:
		var p := Vector2(pt.x * a_w, pt.y * a_h)
		r_min = Vector2(minf(r_min.x, p.x), minf(r_min.y, p.y))
		r_max = Vector2(maxf(r_max.x, p.x), maxf(r_max.y, p.y))

	# Normalise so "left" is the screen-left eye (smaller x).
	if l_min.x > r_min.x:
		var tmp_min := l_min
		var tmp_max := l_max
		l_min = r_min
		l_max = r_max
		r_min = tmp_min
		r_max = tmp_max

	# Lens centres and radii with padding around each eye bounding box.
	var pad_x: float = (l_max.x - l_min.x) * 0.308
	var pad_y: float = (l_max.y - l_min.y) * 0.490

	var l_cx: float = (l_min.x + l_max.x) * 0.5
	var l_cy: float = (l_min.y + l_max.y) * 0.5
	# Multiplied by 1.4 to make the left lens 40% larger
	var l_rx: float = ((l_max.x - l_min.x) * 0.5 + pad_x) * 1.4
	var l_ry: float = ((l_max.y - l_min.y) * 0.5 + pad_y) * 1.4

	var r_cx: float = (r_min.x + r_max.x) * 0.5
	var r_cy: float = (r_min.y + r_max.y) * 0.5
	# Multiplied by 1.4 to make the right lens 40% larger
	var r_rx: float = ((r_max.x - r_min.x) * 0.5 + pad_x) * 1.4
	var r_ry: float = ((r_max.y - r_min.y) * 0.5 + pad_y) * 1.4

	var frame_t: float = maxf(2.0, l_ry * 0.22)  # frame border thickness
	var frame_color := Color.BLACK

	# Decreased the alpha value (0.12) to make the lenses more transparent
	var lens_color := Color(0.0, 0.0, 0.0, 0.12)

	# Left lens: solid frame ring then tinted interior.
	_fill_ellipse(a_image, l_cx, l_cy, l_rx, l_ry, frame_color, a_w, a_h)
	_blend_ellipse(a_image, l_cx, l_cy, l_rx - frame_t, l_ry - frame_t, lens_color, a_w, a_h)

	# Right lens.
	_fill_ellipse(a_image, r_cx, r_cy, r_rx, r_ry, frame_color, a_w, a_h)
	_blend_ellipse(a_image, r_cx, r_cy, r_rx - frame_t, r_ry - frame_t, lens_color, a_w, a_h)

	# Bridge joining the inner edges of the two frames.
	var bridge_y: float = (l_cy + r_cy) * 0.5
	var bridge_r: int = max(2, int(frame_t * 0.75))
	_mustache_stroke(
		a_image,
		Vector2i(int(l_cx + l_rx), int(bridge_y)),
		Vector2i(int(r_cx - r_rx), int(bridge_y)),
		bridge_r,
		frame_color,
		a_w,
		a_h
	)

	# Temples extending from the outer edge of each lens toward the ears.
	var temple_r: int = max(2, int(frame_t * 0.7))
	var temple_len: float = l_rx * 0.9
	_mustache_stroke(
		a_image,
		Vector2i(int(l_cx - l_rx), int(l_cy)),
		Vector2i(int(l_cx - l_rx - temple_len), int(l_cy + l_ry * 0.3)),
		temple_r,
		frame_color,
		a_w,
		a_h
	)
	_mustache_stroke(
		a_image,
		Vector2i(int(r_cx + r_rx), int(r_cy)),
		Vector2i(int(r_cx + r_rx + temple_len), int(r_cy + r_ry * 0.3)),
		temple_r,
		frame_color,
		a_w,
		a_h
	)


# ===========================================================================
# COWBOY HAT
# ===========================================================================


# ---------------------------------------------------------------------------
# _draw_cowboy_hat
#
# Draws a brown cowboy hat above the face using the face_oval contour to
# determine the forehead position and face width.  The hat has a tapered
# crown with a rounded cap, a wide flat brim, a dark hat band, and two
# crease lines pressed into the crown top.
# ---------------------------------------------------------------------------
static func _draw_cowboy_hat(a_image: Image, a_face: FaceMeshInfo, a_w: int, a_h: int) -> void:
	var oval_pts: Array = a_face.get_contour(FaceMeshInfo.CONTOUR_FACE_OVAL)
	if oval_pts.is_empty():
		return

	var o_min_x: float = INF
	var o_max_x: float = -INF
	var o_min_y: float = INF
	for pt: Vector3 in oval_pts:
		var px: float = pt.x * a_w
		var py: float = pt.y * a_h
		if px < o_min_x:
			o_min_x = px
		if px > o_max_x:
			o_max_x = px
		if py < o_min_y:
			o_min_y = py

	var face_w: float = o_max_x - o_min_x
	var cx: float = (o_min_x + o_max_x) * 0.5

	var hat_color := Color(0.40, 0.22, 0.06)  # saddle brown
	var band_color := Color(0.18, 0.09, 0.01)  # dark brown band
	var crease_color := Color(0.28, 0.15, 0.04)  # mid-brown shading

	# Crown geometry: tapers slightly from bottom to top.
	var crown_rx_bot: float = face_w * 0.504  # +80% wider
	var crown_rx_top: float = face_w * 0.396  # +80% wider
	var crown_bot_y: float = o_min_y - face_w * 0.04  # just above forehead
	var crown_top_y: float = crown_bot_y - face_w * 0.55
	var crown_h: float = crown_bot_y - crown_top_y

	# Brim: wide flat ellipse sitting at the base of the crown.
	var brim_rx: float = face_w * 0.936  # +80% wider
	var brim_ry: float = face_w * 0.065
	_fill_ellipse(a_image, cx, crown_bot_y, brim_rx, brim_ry, hat_color, a_w, a_h)

	# Crown body: scan-convert a tapered rectangle.
	for y in range(int(crown_top_y), int(crown_bot_y) + 1):
		var t: float = float(y - crown_top_y) / float(crown_h)
		var rx: float = lerpf(crown_rx_top, crown_rx_bot, t)
		for x in range(int(cx - rx), int(cx + rx) + 1):
			if x >= 0 and x < a_w and y >= 0 and y < a_h:
				a_image.set_pixel(x, y, hat_color)

	# Rounded top cap: top half of a small ellipse.
	var cap_rx: float = crown_rx_top
	var cap_ry: float = face_w * 0.07
	for y in range(int(crown_top_y - cap_ry), int(crown_top_y) + 1):
		for x in range(int(cx - cap_rx), int(cx + cap_rx) + 1):
			var dx: float = float(x) - cx
			var dy: float = float(y) - crown_top_y
			if (dx * dx) / (cap_rx * cap_rx) + (dy * dy) / (cap_ry * cap_ry) <= 1.0:
				if x >= 0 and x < a_w and y >= 0 and y < a_h:
					a_image.set_pixel(x, y, hat_color)

	# Hat band: darker stripe across the lower crown.
	var band_h: float = face_w * 0.07
	var band_top_y: float = crown_bot_y - band_h
	for y in range(int(band_top_y), int(crown_bot_y) + 1):
		var t: float = float(y - crown_top_y) / float(crown_h)
		var rx: float = lerpf(crown_rx_top, crown_rx_bot, t)
		for x in range(int(cx - rx), int(cx + rx) + 1):
			if x >= 0 and x < a_w and y >= 0 and y < a_h:
				a_image.set_pixel(x, y, band_color)

	# Crown crease: two darker lines from the top centre going outward-downward.
	var crease_r: int = max(2, int(face_w * 0.016))
	var crease_depth: float = face_w * 0.16
	_mustache_stroke(
		a_image,
		Vector2i(int(cx), int(crown_top_y)),
		Vector2i(int(cx - crown_rx_top * 0.6), int(crown_top_y + crease_depth)),
		crease_r,
		crease_color,
		a_w,
		a_h
	)
	_mustache_stroke(
		a_image,
		Vector2i(int(cx), int(crown_top_y)),
		Vector2i(int(cx + crown_rx_top * 0.6), int(crown_top_y + crease_depth)),
		crease_r,
		crease_color,
		a_w,
		a_h
	)


# ===========================================================================
# SHARED PIXEL HELPERS
# ===========================================================================


# Fills a solid axis-aligned ellipse with a_color.
static func _fill_ellipse(
	a_image: Image, cx: float, cy: float, rx: float, ry: float, a_color: Color, a_w: int, a_h: int
) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	for y in range(int(cy - ry), int(cy + ry) + 1):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			if (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0:
				if x >= 0 and x < a_w and y >= 0 and y < a_h:
					a_image.set_pixel(x, y, a_color)


# Blends a semi-transparent color over an axis-aligned ellipse region,
# preserving the underlying pixels (used for tinted glass lenses).
static func _blend_ellipse(
	a_image: Image, cx: float, cy: float, rx: float, ry: float, a_color: Color, a_w: int, a_h: int
) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	for y in range(int(cy - ry), int(cy + ry) + 1):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			if (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0:
				if x >= 0 and x < a_w and y >= 0 and y < a_h:
					var existing: Color = a_image.get_pixel(x, y)
					# Blend RGB toward a_color by a_color.a; keep output fully opaque.
					a_image.set_pixel(x, y, existing.lerp(Color(a_color.r, a_color.g, a_color.b, 1.0), a_color.a))


func _print_to_screen(a_message: String, a_is_error: bool = false) -> void:
	if a_is_error:
		_label.push_color(Color.CRIMSON)

	_label.add_text("%s\n\n" % a_message)

	if a_is_error:
		_label.pop()
		printerr("Demo app:: " + a_message)
	else:
		print("Demo app:: " + a_message)

	_label.scroll_to_line(_label.get_line_count() - 1)

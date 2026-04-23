<p align="center">
	<a href="#">
		<img width="128" height="128" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/demo/assets/vision-android.png">
		&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
		<img width="128" height="128" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/demo/assets/vision-ios.png">
	</a>
</p>

<div align="center">
	<a href="https://github.com/godot-mobile-plugins/godot-vision"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-vision?label=Stars&style=plastic" height="40"/></a>
	<img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-vision?label=Latest%20Release&style=plastic" height="40"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-vision/latest/total?label=Downloads&style=plastic" height="40"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-vision/total?label=Total%20Downloads&style=plastic" height="40"/>
</div>

<br>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="24"> Godot Vision Plugin

A Godot plugin that provides a unified GDScript interface for **ML Kit face mesh detection** on **Android** and **iOS**. Pass any `Image` to the `Vision` node and receive rich per-face data including 468 3-D landmark points, triangle mesh indices, and named facial contours — all in a single async call.

**Key Features:**
- Detect one or more faces in any `Image` using ML Kit's Face Mesh API
- Receive **468 normalised 3-D landmark points** per face (`x`/`y` ∈ [0, 1], `z` = relative depth)
- Access the full **triangle mesh** (indices into the landmark array) for each detected face
- Query individual **named contours** — face oval, eyes, eyebrows, lips, and nose bridge — via `FaceMeshInfo` constants
- Built-in **wireframe drawing utilities**: overlay a mesh on an existing image or generate a transparent mesh layer for compositing
- Typed result and error classes (`FaceScanResult`, `FaceMeshInfo`, `ScanError`) for clean, idiomatic GDScript

<br>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Signals](#signals)
- [Methods](#methods)
- [Classes](#classes)
- [Platform-Specific Notes](#platform-specific-notes)
- [Links](#links)
- [All Plugins](#all-plugins)
- [Credits](#credits)
- [Contributing](#contributing)

<br>

<a name="installation"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> Installation
_Before installing this plugin, make sure to uninstall any previous versions of the same plugin._

_If installing both Android and iOS versions of the plugin in the same project, then make sure that both versions use the same addon interface version._

There are 2 ways to install the `Vision` plugin into your project:
- Through the Godot Editor's AssetLib
- Manually by downloading archives from Github

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="18"> Installing via AssetLib
Steps:
- search for and select the `Vision` plugin in Godot Editor
- click `Download` button
- on the installation dialog...
	- keep `Change Install Folder` setting pointing to your project's root directory
	- keep `Ignore asset root` checkbox checked
	- click `Install` button
- enable the plugin via the `Plugins` tab of `Project->Project Settings...` menu, in the Godot Editor

#### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="16"> Installing both Android and iOS versions of the plugin in the same project
When installing via AssetLib, the installer may display a warning that states "_[x number of]_ files conflict with your project and won't be installed." You can ignore this warning since both versions use the same addon code.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="18"> Installing manually
Steps:
- download release archive from Github
- unzip the release archive
- copy to your Godot project's root directory
- enable the plugin via the `Plugins` tab of `Project->Project Settings...` menu, in the Godot Editor

<a name="usage"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> Usage
Add a `Vision` node to your main scene or an autoload global scene.

- connect `Vision` node signals before calling `scan_face()`
	- `face_mesh_ready(result: FaceScanResult)` — emitted when detection succeeds
	- `face_mesh_failed(error: ScanError)` — emitted when detection fails
- call `vision.scan_face(image)` with any `Image`; the image is automatically converted to `FORMAT_RGBA8` if needed
- in the `face_mesh_ready` callback, iterate over `result.get_faces()` to access per-face landmark data
- optionally use the static drawing helpers to render the mesh directly onto an image

**Basic face scan example:**
```gdscript
@onready var vision := $Vision

func _ready() -> void:
	vision.face_mesh_ready.connect(_on_face_mesh_ready)
	vision.face_mesh_failed.connect(_on_face_mesh_failed)

func scan(image: Image) -> void:
	vision.scan_face(image)

func _on_face_mesh_ready(result: FaceScanResult) -> void:
	print("Detected %d face(s)" % result.get_face_count())
	for face in result.get_faces():
		print("  Points: %d, Triangles: %d" % [face.get_points().size(), face.get_triangles().size()])

func _on_face_mesh_failed(error: ScanError) -> void:
	print("Scan failed [%s]: %s" % [error.get_code(), error.get_description()])
```

**Drawing the mesh overlay onto an image:**
```gdscript
func _on_face_mesh_ready(result: FaceScanResult) -> void:
	# Returns a new Image with the wireframe painted on top
	var annotated: Image = Vision.draw_face_mesh_on_image(original_image, result, Color.CYAN)
	$TextureRect.texture = ImageTexture.create_from_image(annotated)
```

**Generating a transparent mesh layer for compositing:**
```gdscript
func _on_face_mesh_ready(result: FaceScanResult) -> void:
	var mesh_layer: Image = Vision.generate_face_mesh_image(
		result, original_image.get_width(), original_image.get_height(), Color.LIME)
	$MeshOverlay.texture = ImageTexture.create_from_image(mesh_layer)
```

**Accessing individual contours:**
```gdscript
func _on_face_mesh_ready(result: FaceScanResult) -> void:
	var face: FaceMeshInfo = result.get_face(0)
	if face:
		var oval: Array = face.get_contour(FaceMeshInfo.CONTOUR_FACE_OVAL)
		for point in oval:
			print("Oval point: ", point)  # Vector3 — x/y normalised, z = depth
```

<a name="signals"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> Signals
Register listeners to the following signals of the `Vision` node:

| Signal | Description |
| :--- | :--- |
| `face_mesh_ready(result: FaceScanResult)` | Emitted when face mesh detection succeeds. `result` contains the image dimensions and an array of `FaceMeshInfo` objects, one per detected face. |
| `face_mesh_failed(error: ScanError)` | Emitted when detection fails. `error` contains a `ScanError.Code` enum value and a human-readable description. |

<a name="methods"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> Methods

### Vision node methods

| Method | Description |
| :--- | :--- |
| `scan_face(a_image: Image) -> void` | Sends `a_image` to the native plugin for ML Kit face mesh detection. The image is automatically converted to `FORMAT_RGBA8` internally. Results are delivered asynchronously via the `face_mesh_ready` or `face_mesh_failed` signals. |

### Static drawing utilities

These are pure-GDScript helpers that operate on a `FaceScanResult` returned by the `face_mesh_ready` signal. They require no scene nodes or rendering server calls.

| Method | Description |
| :--- | :--- |
| `Vision.generate_face_mesh_image(a_result: FaceScanResult, a_width: int, a_height: int, a_color: Color) -> Image` | Creates a new `FORMAT_RGBA8` image of the given dimensions with a fully transparent background, then draws the face mesh wireframe in `a_color`. Use this to composite the mesh as a separate layer on top of your camera frame. |
| `Vision.draw_face_mesh_on_image(a_original: Image, a_result: FaceScanResult, a_color: Color) -> Image` | Returns a new `FORMAT_RGBA8` copy of `a_original` with the face mesh wireframe painted on top in `a_color`. The original image is not modified. |

<a name="classes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> Classes

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="16"> FaceScanResult
Encapsulates the full result of a `scan_face()` call. Received via the `face_mesh_ready` signal.

| Method | Return type | Description |
| :--- | :--- | :--- |
| `get_image_width()` | `int` | Width (px) of the image that was scanned. |
| `get_image_height()` | `int` | Height (px) of the image that was scanned. |
| `get_face_count()` | `int` | Number of faces detected in the image. |
| `get_face(a_index: int)` | `FaceMeshInfo` | Returns the `FaceMeshInfo` at the given index, or `null` if out of range. |
| `get_faces()` | `Array` | Returns all detected faces as an `Array` of `FaceMeshInfo` objects. |
| `is_valid()` | `bool` | Returns `true` when all required fields are present in the result. |
| `get_raw_data()` | `Dictionary` | Returns the underlying raw data dictionary. |

---

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="16"> FaceMeshInfo
Encapsulates the mesh data for a single detected face.

| Method | Return type | Description |
| :--- | :--- | :--- |
| `get_points()` | `Array` | All 468 landmark points as `Vector3`. `x` and `y` are normalised to [0, 1]; `z` is relative depth. |
| `get_triangles()` | `Array` | All mesh triangles as `Vector3i`. Each component (`x`, `y`, `z`) is an index into the `get_points()` array. |
| `get_contours()` | `Dictionary` | Raw contours dictionary keyed by contour name. Values are arrays of `[x, y, z]` sub-arrays. |
| `get_contour(a_contour_name: String)` | `Array` | Points of a named contour as `Array` of `Vector3`. Use the `CONTOUR_*` constants as the name argument. |
| `is_valid()` | `bool` | Returns `true` when points, triangles, and contours are all present. |
| `get_raw_data()` | `Dictionary` | Returns the underlying raw data dictionary. |

**Contour name constants** (pass to `get_contour()`):

| Constant | Facial region |
| :--- | :--- |
| `CONTOUR_FACE_OVAL` | Outer boundary of the face |
| `CONTOUR_LEFT_EYE` | Left eye outline |
| `CONTOUR_LEFT_EYEBROW_BOTTOM` | Bottom edge of the left eyebrow |
| `CONTOUR_LEFT_EYEBROW_TOP` | Top edge of the left eyebrow |
| `CONTOUR_LOWER_LIP_BOTTOM` | Outer bottom edge of the lower lip |
| `CONTOUR_LOWER_LIP_TOP` | Inner top edge of the lower lip |
| `CONTOUR_NOSE_BRIDGE` | Bridge of the nose |
| `CONTOUR_RIGHT_EYE` | Right eye outline |
| `CONTOUR_RIGHT_EYEBROW_BOTTOM` | Bottom edge of the right eyebrow |
| `CONTOUR_RIGHT_EYEBROW_TOP` | Top edge of the right eyebrow |
| `CONTOUR_UPPER_LIP_BOTTOM` | Inner bottom edge of the upper lip |
| `CONTOUR_UPPER_LIP_TOP` | Outer top edge of the upper lip |

---

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="16"> ScanError
Encapsulates error information delivered via the `face_mesh_failed` signal.

| Method | Return type | Description |
| :--- | :--- | :--- |
| `get_code()` | `ScanError.Code` | One of the `Code` enum values below. |
| `get_description()` | `String` | Human-readable description of the error. |

**`ScanError.Code` enum values:**

| Value | Meaning |
| :--- | :--- |
| `NONE` | No error. |
| `INVALID_IMAGE` | The supplied image could not be processed. |
| `NO_CODE_DETECTED` | No face was detected in the image. |
| `SCANNER_FAILURE` | The underlying ML Kit scanner returned a failure. |
| `INTERNAL_ERROR` | An unexpected internal error occurred. |

---

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="16"> ImageInfo
Wraps a Godot `Image` as a serialisable dictionary for transfer to the native plugin. Used internally by `scan_face()` — you do not normally need to use this class directly.

| Method | Return type | Description |
| :--- | :--- | :--- |
| `ImageInfo.create_from_image(a_image: Image)` *(static)* | `ImageInfo` | Creates an `ImageInfo` from a Godot `Image`. |
| `get_buffer()` | `PackedByteArray` | Raw pixel bytes of the image. |
| `get_width()` | `int` | Image width in pixels. |
| `get_height()` | `int` | Image height in pixels. |
| `get_format()` | `Image.Format` | Pixel format of the image. |
| `has_mipmaps()` | `bool` | Whether the image has mipmaps. |
| `is_valid()` | `bool` | Returns `true` when width, height, and buffer are all present. |
| `get_raw_data()` | `Dictionary` | Returns the underlying raw data dictionary. |

<a name="platform-specific-notes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> Platform-Specific Notes

### Android
- Download Android export template and enable gradle build from export settings
- **Troubleshooting:**
- Logs: `adb logcat | grep 'godot'` (Linux), `adb.exe logcat | select-string "godot"` (Windows)
- You may find the following resources helpful:
	- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
	- https://developer.android.com/tools/adb
	- https://developer.android.com/studio/debug
	- https://developer.android.com/courses

### iOS
- Follow instructions on [Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- View XCode logs while running the game for troubleshooting.
- See [Godot iOS Export Troubleshooting](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html#troubleshooting).

<br>

<a name="links"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="24"> Links

- [AssetLib Entry Android](https://godotengine.org/asset-library/asset/9999)
- [AssetLib Entry iOS](https://godotengine.org/asset-library/asset/8888)

<br>

<a name="all-plugins"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="24"> All Plugins

| ✦ | Plugin | Android | iOS | Latest Release | Downloads | Stars |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/godot-sdk-integrations/godot-admob/main/addon/src/main/icon.png" width="20"> | [Admob](https://github.com/godot-sdk-integrations/godot-admob) | ✅ | ✅ | <a href="https://github.com/godot-sdk-integrations/godot-admob/releases"><img src="https://img.shields.io/github/release-date/godot-sdk-integrations/godot-admob?label=%20" /><img src="https://img.shields.io/github/v/release/godot-sdk-integrations/godot-admob?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-sdk-integrations/godot-admob/stargazers"><img src="https://img.shields.io/github/stars/godot-sdk-integrations/godot-admob?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-connection-state/main/addon/src/icon.png" width="20"> | [Connection State](https://github.com/godot-mobile-plugins/godot-connection-state) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-connection-state/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-connection-state?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-connection-state?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-connection-state/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-connection-state?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-deeplink/main/addon/src/icon.png" width="20"> | [Deeplink](https://github.com/godot-mobile-plugins/godot-deeplink) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-deeplink/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-deeplink?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-deeplink?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-deeplink/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-deeplink?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/icon.png" width="20"> | [Firebase](https://github.com/godot-mobile-plugins/godot-firebase) | ⏰  | ⏰  | 🔜 <!-- <a href="https://github.com/godot-mobile-plugins/godot-firebase/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-firebase?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-firebase?label=%20" hspace="4" /></a> --> | - <!-- <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/total?label=total" hspace="4" /></a> --> | <a href="https://github.com/godot-mobile-plugins/godot-firebase/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-firebase?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-inapp-review/main/addon/src/icon.png" width="20"> | [In-App Review](https://github.com/godot-mobile-plugins/godot-inapp-review) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-inapp-review/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-inapp-review?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-inapp-review?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-inapp-review/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-inapp-review?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/main/icon.png" width="20"> | [Native Camera](https://github.com/godot-mobile-plugins/godot-native-camera) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-native-camera/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-native-camera?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-native-camera?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-native-camera/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-native-camera?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> | [Notification Scheduler](https://github.com/godot-mobile-plugins/godot-notification-scheduler) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-notification-scheduler/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-notification-scheduler?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-notification-scheduler?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-notification-scheduler/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-notification-scheduler?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> | [OAuth 2.0](https://github.com/godot-mobile-plugins/godot-oauth2) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-oauth2/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-oauth2?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-oauth2?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-oauth2/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-oauth2?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-qr/main/addon/src/icon.png" width="20"> | [QR](https://github.com/godot-mobile-plugins/godot-qr) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-qr/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-qr?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-qr?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-qr/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-qr?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-share/main/addon/src/icon.png" width="20"> | [Share](https://github.com/godot-mobile-plugins/godot-share) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-share/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-share?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-share?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-share/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-share?style=plastic&label=%20" /></a> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="20"> | [Vision](https://github.com/godot-mobile-plugins/godot-vision) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-vision/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-vision?label=%20" /><img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-vision?label=%20" hspace="4" /></a> | <a href="#"><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-vision/latest/total?label=latest" /><img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-vision/total?label=total" hspace="4" /></a> | <a href="https://github.com/godot-mobile-plugins/godot-vision/stargazers"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-vision?style=plastic&label=%20" /></a> |

<br>

<a name="credits"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="24"> Credits

Developed by [Cengiz](https://github.com/cengiz-pz)

Based on [Godot Mobile Plugin Template v7](https://github.com/godot-mobile-plugins/godot-plugin-template/tree/v7)

Original repository: [Godot Vision Plugin](https://github.com/godot-mobile-plugins/godot-vision)

<br>

<a name="contributing"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-vision/main/addon/src/main/icon.png" width="24"> Contributing

Contributions are welcome. Please see the [contributing guide](https://github.com/godot-mobile-plugins/godot-vision?tab=contributing-ov-file) in the repository for details.

<br>

# 💖 Support the Project

If this plugin has helped you, consider supporting its development! Every bit of support helps keep the plugin updated and bug-free.

| ✦ | Ways to Help | How to do it |
| :--- | :--- | :--- |
|✨⭐| **Spread the Word** | [Star this repo](https://github.com/godot-mobile-plugins/godot-vision/stargazers) to help others find it. |
|💡✨| **Give Feedback** | [Open an issue](https://github.com/godot-mobile-plugins/godot-vision/issues) or [suggest a feature](https://github.com/godot-mobile-plugins/godot-vision/issues/new). |
|🧩| **Contribute** | [Submit a PR](https://github.com/godot-mobile-plugins/godot-vision?tab=contributing-ov-file) to help improve the codebase. |
|❤️| **Buy a Coffee** | Support the maintainers on GitHub Sponsors or other platforms. |

<br>

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=godot-mobile-plugins/godot-vision&type=date&theme=dark&legend=top-left)](https://www.star-history.com/?repos=godot-mobile-plugins%2Fgodot-vision&type=date&theme=dark&legend=top-left)

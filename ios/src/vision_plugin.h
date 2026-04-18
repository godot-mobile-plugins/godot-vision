//
// © 2026-present https://github.com/cengiz-pz
//

#ifndef vision_plugin_h
#define vision_plugin_h

#import <Foundation/Foundation.h>

#include "core/object/class_db.h"
#include "core/object/object.h"
#include "core/variant/dictionary.h"
#include "core/variant/array.h"

// Forward-declare the Swift bridge (exposed to ObjC via vision_plugin-Swift.h)
@class VisionSwiftBridge;

// ---------------------------------------------------------------------------
// Signal name constants
// ---------------------------------------------------------------------------
extern const char *FACE_MESH_READY_SIGNAL_NAME;
extern const char *FACE_MESH_FAILED_SIGNAL_NAME;

// ---------------------------------------------------------------------------
// VisionPlugin
//
// Godot engine singleton (GDScript access via Engine.get_singleton("VisionPlugin"))
// that exposes on-device face mesh detection through MediaPipe Tasks Vision.
//
// Signals
//   face_mesh_ready(result: Dictionary)
//     Emitted when detection succeeds.  The dictionary layout matches the
//     Android counterpart (see FaceScanResult.swift for the full schema):
//       {
//         "image_width":  int,
//         "image_height": int,
//         "faces": [
//           {
//             "points":    [[x,y,z], …],   // 468 normalised landmarks
//             "triangles": [[i,j,k], …],   // canonical mesh triangles
//             "contours":  { "face_oval": [[x,y,z], …], … }
//           },
//           …
//         ]
//       }
//
//   face_mesh_failed(error: Dictionary)
//     Emitted when detection fails.
//       { "code": int, "description": String }
//
// Methods
//   scan_face(image_info: Dictionary)
//     Triggers asynchronous face detection.  The dictionary must contain:
//       { "buffer": PackedByteArray, "width": int, "height": int,
//         "format": int, "has_mipmaps": bool }
//     On completion one of the two signals above is emitted on the main thread.
// ---------------------------------------------------------------------------
class VisionPlugin : public Object {
    GDCLASS(VisionPlugin, Object);

private:
    // Singleton instance – accessed from the ObjC callback shim.
    static VisionPlugin *instance;

    // Retained ObjC/Swift bridge that drives MediaPipe on a background queue.
    VisionSwiftBridge *swiftBridge;

    static void _bind_methods();

    // Helpers used by the ObjC callback shim (vision_plugin.mm) to convert
    // NSDictionary trees coming from Swift into Godot Variant trees and then
    // emit the appropriate signal.
    static Variant ns_to_variant(id obj);
    static Dictionary ns_dict_to_godot(NSDictionary *nsDict);
    static Array     ns_array_to_godot(NSArray     *nsArray);

public:
    // Called from GDScript: plugin.scan_face(image_info_dict)
    void scan_face(Dictionary image_dict);

    // Called by the ObjC callback shim after the Swift bridge resolves.
    void on_face_mesh_ready(NSDictionary *result_ns);
    void on_face_mesh_failed(NSDictionary *error_ns);

    // Singleton accessor used by the ObjC callback shim.
    static VisionPlugin *get_singleton() { return instance; }

    VisionPlugin();
    ~VisionPlugin();
};

#endif /* vision_plugin_h */

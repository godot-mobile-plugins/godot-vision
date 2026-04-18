//
// © 2026-present https://github.com/cengiz-pz
//

#import "vision_plugin.h"

// Auto-generated ObjC header produced by the Swift compiler for every
// @objc-exposed Swift class/protocol in the same module target.
#import "vision_plugin-Swift.h"

#import "vision_logger.h"

#include "core/variant/variant.h"

// ---------------------------------------------------------------------------
// Signal name constants
// ---------------------------------------------------------------------------
const char *FACE_MESH_READY_SIGNAL_NAME  = "face_mesh_ready";
const char *FACE_MESH_FAILED_SIGNAL_NAME = "face_mesh_failed";

// ---------------------------------------------------------------------------
// FaceMeshCallbackHandler
//
// Lightweight ObjC shim that lets the Swift bridge (which cannot directly
// reference the C++ VisionPlugin type) deliver results back on the main
// thread.  It conforms to the VisionSwiftBridgeDelegate protocol declared
// in VisionSwiftBridge.swift and exposed via the auto-generated header.
// ---------------------------------------------------------------------------
@interface FaceMeshCallbackHandler : NSObject <VisionSwiftBridgeDelegate>
@end

@implementation FaceMeshCallbackHandler

- (void)faceMeshReadyWithResult:(NSDictionary *)result {
    os_log_debug(vision_log, "FaceMeshCallbackHandler: faceMeshReady");
    if (VisionPlugin::get_singleton()) {
        VisionPlugin::get_singleton()->on_face_mesh_ready(result);
    }
}

- (void)faceMeshFailedWithError:(NSDictionary *)error {
    os_log_debug(vision_log, "FaceMeshCallbackHandler: faceMeshFailed");
    if (VisionPlugin::get_singleton()) {
        VisionPlugin::get_singleton()->on_face_mesh_failed(error);
    }
}

@end

// ---------------------------------------------------------------------------
// VisionPlugin – static members
// ---------------------------------------------------------------------------
VisionPlugin *VisionPlugin::instance = nullptr;

// ---------------------------------------------------------------------------
// _bind_methods
//
// Registers the GDScript-callable method and the two signals with Godot's
// ClassDB.  Must be kept in sync with the signal/method names used in
// GDScript.
// ---------------------------------------------------------------------------
void VisionPlugin::_bind_methods() {
    // Method
    ClassDB::bind_method(D_METHOD("scan_face", "image_dict"),
                         &VisionPlugin::scan_face);

    // Signals
    ADD_SIGNAL(MethodInfo(
        String(FACE_MESH_READY_SIGNAL_NAME),
        PropertyInfo(Variant::DICTIONARY, "result")));

    ADD_SIGNAL(MethodInfo(
        String(FACE_MESH_FAILED_SIGNAL_NAME),
        PropertyInfo(Variant::DICTIONARY, "error")));
}

// ---------------------------------------------------------------------------
// scan_face
//
// Entry point from GDScript.  Validates the incoming dictionary and
// delegates the actual MediaPipe work to the Swift bridge.
// ---------------------------------------------------------------------------
void VisionPlugin::scan_face(Dictionary image_dict) {
    os_log_debug(vision_log, "VisionPlugin::scan_face()");

    if (swiftBridge == nil) {
        os_log_error(vision_log, "VisionPlugin: swiftBridge is nil – not initialised");
        NSDictionary *err = @{
            @"code": @(4 /* INTERNAL_ERROR */),
            @"description": @"Swift bridge not initialised"
        };
        on_face_mesh_failed(err);
        return;
    }

    // ---- Extract buffer ---------------------------------------------------
    // Godot PackedByteArray is passed through JNI/ObjC bridge as a raw
    // byte array.  On iOS it arrives as a PoolByteArray / PackedByteArray.
    Variant buf_var = image_dict["buffer"];
    if (buf_var.get_type() != Variant::PACKED_BYTE_ARRAY) {
        NSDictionary *err = @{
            @"code": @(1 /* INVALID_IMAGE */),
            @"description": @"buffer key missing or wrong type"
        };
        on_face_mesh_failed(err);
        return;
    }
    PackedByteArray pba = buf_var;
    const uint8_t *bytes = pba.ptr();
    int byte_count = (int)pba.size();

    // ---- Extract width / height -------------------------------------------
    int width  = (int)(int64_t)image_dict["width"];
    int height = (int)(int64_t)image_dict["height"];

    if (width <= 0 || height <= 0 || byte_count <= 0) {
        NSDictionary *err = @{
            @"code": @(1 /* INVALID_IMAGE */),
            @"description": @"Invalid image dimensions or empty buffer"
        };
        on_face_mesh_failed(err);
        return;
    }

    // Wrap the raw bytes in NSData (copy so the PackedByteArray can be freed).
    NSData *bufferData = [NSData dataWithBytes:bytes length:(NSUInteger)byte_count];

    [swiftBridge scanFaceWithBuffer:bufferData
                              width:(NSInteger)width
                             height:(NSInteger)height];
}

// ---------------------------------------------------------------------------
// on_face_mesh_ready / on_face_mesh_failed
//
// Called by FaceMeshCallbackHandler after the Swift bridge resolves.
// Convert the NSDictionary tree → Godot Dictionary tree and emit the
// appropriate signal.
// ---------------------------------------------------------------------------
void VisionPlugin::on_face_mesh_ready(NSDictionary *result_ns) {
    Dictionary result = ns_dict_to_godot(result_ns);
    emit_signal(String(FACE_MESH_READY_SIGNAL_NAME), result);
}

void VisionPlugin::on_face_mesh_failed(NSDictionary *error_ns) {
    Dictionary error = ns_dict_to_godot(error_ns);
    emit_signal(String(FACE_MESH_FAILED_SIGNAL_NAME), error);
}

// ---------------------------------------------------------------------------
// Recursive NSDictionary / NSArray → Godot Variant conversion helpers
// ---------------------------------------------------------------------------

Variant VisionPlugin::ns_to_variant(id obj) {
    if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *num = (NSNumber *)obj;
        // Distinguish float/double from integer types by ObjC encoding.
        const char *enc = num.objCType;
        if (enc[0] == 'f' || enc[0] == 'd') {
            return Variant((double)[num doubleValue]);
        }
        return Variant((int64_t)[num longLongValue]);
    }

    if ([obj isKindOfClass:[NSString class]]) {
        return Variant(String([(NSString *)obj UTF8String]));
    }

    if ([obj isKindOfClass:[NSArray class]]) {
        return Variant(ns_array_to_godot((NSArray *)obj));
    }

    if ([obj isKindOfClass:[NSDictionary class]]) {
        return Variant(ns_dict_to_godot((NSDictionary *)obj));
    }

    if ([obj isKindOfClass:[NSNull class]]) {
        return Variant();
    }

    // Fallback – log and return nil variant.
    os_log_error(vision_log, "ns_to_variant: unsupported type %{public}s",
                 [NSStringFromClass([obj class]) UTF8String]);
    return Variant();
}

Dictionary VisionPlugin::ns_dict_to_godot(NSDictionary *nsDict) {
    Dictionary dict;
    for (NSString *key in nsDict) {
        dict[String([key UTF8String])] = ns_to_variant(nsDict[key]);
    }
    return dict;
}

Array VisionPlugin::ns_array_to_godot(NSArray *nsArray) {
    Array arr;
    for (id item in nsArray) {
        arr.push_back(ns_to_variant(item));
    }
    return arr;
}

// ---------------------------------------------------------------------------
// Constructor / Destructor
// ---------------------------------------------------------------------------
VisionPlugin::VisionPlugin() {
    os_log_debug(vision_log, "VisionPlugin: constructor");

    ERR_FAIL_COND(instance != nullptr);
    instance = this;

    // Create the callback handler (ObjC object, lives until plugin is
    // destroyed; the bridge holds a weak reference to it).
    FaceMeshCallbackHandler *handler = [[FaceMeshCallbackHandler alloc] init];

    // Create and initialise the Swift bridge.
    swiftBridge = [[VisionSwiftBridge alloc] init];
    swiftBridge.delegate = handler;
    [swiftBridge initialize];
}

VisionPlugin::~VisionPlugin() {
    os_log_debug(vision_log, "VisionPlugin: destructor");

    if (swiftBridge != nil) {
        [swiftBridge shutdown];
        swiftBridge = nil;
    }

    if (instance == this) {
        instance = nullptr;
    }
}

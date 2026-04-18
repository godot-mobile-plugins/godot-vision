//
// © 2026-present https://github.com/cengiz-pz
//
// ScanError.swift
//
// iOS counterpart of ScanError.java.
//
// Error codes are kept in the same order as the Android enum so that
// GDScript code can use the same numeric constants on both platforms:
//
//   0 – NONE
//   1 – INVALID_IMAGE
//   2 – NO_FACE_DETECTED   (maps to Android's NO_CODE_DETECTED)
//   3 – SCANNER_FAILURE
//   4 – INTERNAL_ERROR
//

import Foundation

// ---------------------------------------------------------------------------
// ScanError
// ---------------------------------------------------------------------------
struct ScanError: Error {

    // -----------------------------------------------------------------------
    // Error code enum
    //
    // Raw Int values are deliberately fixed and must not be reordered so that
    // GDScript can compare against numeric constants that match Android.
    // -----------------------------------------------------------------------
    enum Code: Int {
        case none           = 0
        case invalidImage   = 1
        case noFaceDetected = 2   // Android: NO_CODE_DETECTED
        case scannerFailure = 3
        case internalError  = 4
    }

    // -----------------------------------------------------------------------
    // Properties
    // -----------------------------------------------------------------------

    let code:        Code
    let description: String

    // -----------------------------------------------------------------------
    // buildNSDictionary
    //
    // Produces the NSDictionary emitted with the face_mesh_failed signal:
    //   { "code": Int, "description": String }
    // -----------------------------------------------------------------------
    func buildNSDictionary() -> NSDictionary {
        return [
            "code":        NSNumber(value: code.rawValue),
            "description": description as NSString
        ]
    }
}

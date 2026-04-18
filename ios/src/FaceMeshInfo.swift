//
// © 2026-present https://github.com/cengiz-pz
//
// FaceMeshInfo.swift
//
// iOS counterpart of FaceMeshInfo.java.
//
// Given the 468 normalised landmarks for a single detected face, this class
// assembles the NSDictionary that will ultimately reach GDScript as a Godot
// Dictionary.  The structure is identical to the Android plugin:
//
//   {
//     "points": [[x,y,z], …],          // 468 entries
//     "triangles": [[i,j,k], …],        // canonical mesh faces
//     "contours": {
//       "face_oval":           [[x,y,z], …],
//       "left_eye":            [[x,y,z], …],
//       "left_eyebrow_bottom": [[x,y,z], …],
//       "left_eyebrow_top":    [[x,y,z], …],
//       "lower_lip_bottom":    [[x,y,z], …],
//       "lower_lip_top":       [[x,y,z], …],
//       "nose_bridge":         [[x,y,z], …],
//       "right_eye":           [[x,y,z], …],
//       "right_eyebrow_bottom":[[x,y,z], …],
//       "right_eyebrow_top":   [[x,y,z], …],
//       "upper_lip_bottom":    [[x,y,z], …],
//       "upper_lip_top":       [[x,y,z], …],
//     }
//   }
//

import Foundation

final class FaceMeshInfo {

    // -----------------------------------------------------------------------
    // Types
    // -----------------------------------------------------------------------

    typealias Landmark = (x: Float, y: Float, z: Float)

    // -----------------------------------------------------------------------
    // Private state
    // -----------------------------------------------------------------------

    private let landmarks: [Landmark]   // exactly 468 entries

    // -----------------------------------------------------------------------
    // Initialiser
    // -----------------------------------------------------------------------

    init(landmarks: [Landmark]) {
        self.landmarks = landmarks
    }

    // -----------------------------------------------------------------------
    // buildNSDictionary
    //
    // Converts the landmark list into the NSDictionary structure described in
    // the header comment above.  All coordinates are already normalised [0,1]
    // by MediaPipe, so no scaling is needed here (unlike the Android code
    // which divides pixel coordinates by image dimensions).
    //
    // The returned object uses only Foundation types (NSArray, NSDictionary,
    // NSNumber) so it can be converted to a Godot Dictionary by the ObjC++
    // conversion helpers in vision_plugin.mm without any MediaPipe dependency.
    // -----------------------------------------------------------------------
    func buildNSDictionary() -> NSDictionary {
        let dict = NSMutableDictionary()

        // ---- points --------------------------------------------------------
        dict["points"] = buildPointsArray(landmarks)

        // ---- triangles -----------------------------------------------------
        dict["triangles"] = buildTrianglesArray()

        // ---- contours ------------------------------------------------------
        dict["contours"] = buildContoursDict()

        return dict.copy() as! NSDictionary
    }

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------

    /// Converts a flat landmark list into NSArray of NSArray([x, y, z]).
    private func buildPointsArray(_ pts: [Landmark]) -> NSArray {
        return pts.map { lm -> NSArray in
            [NSNumber(value: lm.x), NSNumber(value: lm.y), NSNumber(value: lm.z)] as NSArray
        } as NSArray
    }

    /// Builds the triangles array using the canonical MediaPipe tessellation
    /// loaded by FaceMeshConstants.
    private func buildTrianglesArray() -> NSArray {
        return FaceMeshConstants.triangles.map { tri -> NSArray in
            [NSNumber(value: tri[0]),
             NSNumber(value: tri[1]),
             NSNumber(value: tri[2])] as NSArray
        } as NSArray
    }

    /// Builds the contours dictionary by sampling the landmark list at the
    /// pre-defined contour indices from FaceMeshConstants.
    private func buildContoursDict() -> NSDictionary {
        let dict = NSMutableDictionary()

        for (key, indices) in zip(FaceMeshConstants.contourKeys,
                                  FaceMeshConstants.contourIndices) {
            let contourLandmarks: [Landmark] = indices.compactMap { idx in
                guard idx < landmarks.count else { return nil }
                return landmarks[idx]
            }
            dict[key] = buildPointsArray(contourLandmarks)
        }

        return dict.copy() as! NSDictionary
    }
}

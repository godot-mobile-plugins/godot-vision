//
// © 2026-present https://github.com/cengiz-pz
//
// FaceScanResult.swift
//
// iOS counterpart of FaceScanResult.java.
//
// Assembles the top-level result dictionary that is emitted via the
// face_mesh_ready signal:
//
//   {
//     "image_width":  Int,
//     "image_height": Int,
//     "faces": [
//       { "points": …, "triangles": …, "contours": … },
//       …
//     ]
//   }
//

import Foundation

final class FaceScanResult {

    // -----------------------------------------------------------------------
    // Private state
    // -----------------------------------------------------------------------

    private let faces:       [FaceLandmarkerService.DetectedFace]
    private let imageWidth:  Int
    private let imageHeight: Int

    // -----------------------------------------------------------------------
    // Initialiser
    // -----------------------------------------------------------------------

    init(faces: [FaceLandmarkerService.DetectedFace],
         imageWidth: Int,
         imageHeight: Int) {
        self.faces       = faces
        self.imageWidth  = imageWidth
        self.imageHeight = imageHeight
    }

    // -----------------------------------------------------------------------
    // buildNSDictionary
    //
    // Produces the NSDictionary that the ObjC++ layer converts into a Godot
    // Dictionary before emitting the face_mesh_ready signal.
    // -----------------------------------------------------------------------
    func buildNSDictionary() -> NSDictionary {
        let dict = NSMutableDictionary()

        dict["image_width"]  = NSNumber(value: imageWidth)
        dict["image_height"] = NSNumber(value: imageHeight)

        let facesArray: NSArray = faces.map { face -> NSDictionary in
            let info = FaceMeshInfo(landmarks: face.landmarks)
            return info.buildNSDictionary()
        } as NSArray

        dict["faces"] = facesArray

        return dict.copy() as! NSDictionary
    }
}

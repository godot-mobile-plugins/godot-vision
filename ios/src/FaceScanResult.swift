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

	private let faces: [FaceLandmarkerService.DetectedFace]
	private let imageWidth: Int
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
	//
	// Implementation note: all collections are returned directly as their
	// NSMutable* types (implicit upcast to the NS* return type); no copy
	// step is performed.  Copying via NSDictionary(dictionary:), NSArray(array:),
	// or collection.copy() all route through Swift's bridging machinery, which
	// re-boxes stored NSDictionary / NSArray values as Swift value types
	// ([AnyHashable: Any]).  Once re-boxed, `as? NSDictionary` on a retrieved
	// element returns nil even though the data is intact.  Returning the
	// mutable containers directly keeps every stored object as a genuine ObjC
	// reference that survives type-cast assertions.
	// -----------------------------------------------------------------------
	func buildNSDictionary() -> NSDictionary {
		let dict = NSMutableDictionary()

		dict["image_width"]  = NSNumber(value: imageWidth)
		dict["image_height"] = NSNumber(value: imageHeight)

		// Build the faces array using NSMutableArray so each face dictionary
		// is inserted via ObjC addObject: and retains its NSDictionary identity.
		// NSMutableArray is a subclass of NSArray: implicit upcast, no copy.
		let facesArray = NSMutableArray()
		for face in faces {
			facesArray.add(FaceMeshInfo(landmarks: face.landmarks).buildNSDictionary())
		}
		dict["faces"] = facesArray

		// NSMutableDictionary is a subclass of NSDictionary: implicit upcast,
		// no cast operator required, no bridging copy performed.
		return dict
	}
}

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
//     "image": {                  ← full ImageInfo dictionary for the processed image
//       "buffer":     NSData,     ← raw RGBA8 pixel data (maps to PackedByteArray in GDScript)
//       "width":      NSNumber,
//       "height":     NSNumber,
//       "format":     NSNumber,   ← Godot Image.FORMAT_RGBA8 == 4
//       "has_mipmaps": NSNumber   ← 0 or 1
//     },
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
	private let imageInfo: NSDictionary

	// -----------------------------------------------------------------------
	// Initialiser
	//
	// - Parameter faces:     Detected faces from FaceLandmarkerService.
	// - Parameter imageInfo: Full ImageInfo NSDictionary built by the
	//                        VisionSwiftBridge from the incoming image data.
	//                        Stored verbatim and emitted as the "image" key
	//                        in the result so GDScript can reconstruct an
	//                        ImageInfo object from it.
	// -----------------------------------------------------------------------
	init(faces: [FaceLandmarkerService.DetectedFace],
			imageInfo: NSDictionary) {
		self.faces     = faces
		self.imageInfo = imageInfo
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

		// Embed the full ImageInfo dictionary so GDScript can call
		// result.get_image() to obtain an ImageInfo object.
		dict["image"] = imageInfo

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

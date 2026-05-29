//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.model;

import com.google.mlkit.vision.facemesh.FaceMesh;

import java.util.List;

import org.godotengine.godot.Dictionary;


public class FaceScanResult {
	private static final String CLASS_NAME = FaceScanResult.class.getSimpleName();
	private static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final String IMAGE_PROPERTY = "image";
	private static final String FACES_PROPERTY = "faces";

	private List<FaceMesh> faceMeshes;
	private ImageInfo imageInfo;

	public FaceScanResult(List<FaceMesh> faceMeshes, ImageInfo imageInfo) {
		this.faceMeshes = faceMeshes;
		this.imageInfo = imageInfo;
	}

	// -------------------------------------------------------------------------
	// buildRawData
	//
	// Converts a list of FaceMesh objects into a Godot Dictionary with the
	// following structure (all landmark coordinates are NORMALISED to [0, 1]):
	//
	//   {
	//     "image": {                  ← full ImageInfo dictionary for the processed image
	//       "buffer":     byte[],     ← raw RGBA8 pixel data
	//       "width":      long,
	//       "height":     long,
	//       "format":     long,       ← Godot Image.FORMAT_RGBA8 == 4
	//       "has_mipmaps": bool
	//     },
	//     "faces": [                  ← Object[] - one entry per detected face
	//       {
	//         "points": [             ← Object[] of 468 entries, each Object[3]
	//           [x, y, z],            ← double; x,y normalised 0-1; z is relative depth
	//           …
	//         ],
	//         "triangles": [          ← Object[] of triangle entries, each Object[3]
	//           [i, j, k],            ← long indices into the "points" array
	//           …
	//         ],
	//         "contours": {           ← Dictionary keyed by contour name
	//           "face_oval":          ← Object[] of points on this contour, each Object[3]
	//             [[x, y, z], …],
	//           "left_eye":           [[x, y, z], …],
	//           "left_eyebrow_bottom": [[x, y, z], …],
	//           "left_eyebrow_top":   [[x, y, z], …],
	//           "lower_lip_bottom":   [[x, y, z], …],
	//           "lower_lip_top":      [[x, y, z], …],
	//           "nose_bridge":        [[x, y, z], …],
	//           "right_eye":          [[x, y, z], …],
	//           "right_eyebrow_bottom": [[x, y, z], …],
	//           "right_eyebrow_top":  [[x, y, z], …],
	//           "upper_lip_bottom":   [[x, y, z], …],
	//           "upper_lip_top":      [[x, y, z], …],
	//         }
	//       },
	//       …
	//     ]
	//   }
	//
	// Using Object[] here because that is what Godot's JNI bridge maps to
	// GDScript Array at runtime.
	// -------------------------------------------------------------------------
	public Dictionary buildRawData() {
		Dictionary dict = new Dictionary();

		dict.put(IMAGE_PROPERTY, imageInfo.getRawData());

		Object[] facesArray = new Object[faceMeshes.size()];

		for (int f = 0; f < faceMeshes.size(); f++) {
			FaceMeshInfo faceMeshInfo = new FaceMeshInfo(faceMeshes.get(f));
			facesArray[f] = faceMeshInfo.buildRawData(imageInfo.getWidth(), imageInfo.getHeight());
		}

		dict.put(FACES_PROPERTY, facesArray);

		return dict;
	}
}

//
// © 2024-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.model;

import android.util.Log;

import com.google.mlkit.vision.common.PointF3D;
import com.google.mlkit.vision.common.Triangle;
import com.google.mlkit.vision.facemesh.FaceMesh;
import com.google.mlkit.vision.facemesh.FaceMeshPoint;

import java.util.List;

import org.godotengine.godot.Dictionary;


public class FaceMeshInfo {
	private static final String CLASS_NAME = FaceMeshInfo.class.getSimpleName();
	private static final String LOG_TAG = "godot::" + CLASS_NAME;

	private static final String[] CONTOUR_KEYS = {
			"face_oval",
			"left_eye",
			"left_eyebrow_bottom",
			"left_eyebrow_top",
			"lower_lip_bottom",
			"lower_lip_top",
			"nose_bridge",
			"right_eye",
			"right_eyebrow_bottom",
			"right_eyebrow_top",
			"upper_lip_bottom",
			"upper_lip_top",
	};

	private static final int[] CONTOUR_TYPES = {
			FaceMesh.FACE_OVAL,
			FaceMesh.LEFT_EYE,
			FaceMesh.LEFT_EYEBROW_BOTTOM,
			FaceMesh.LEFT_EYEBROW_TOP,
			FaceMesh.LOWER_LIP_BOTTOM,
			FaceMesh.LOWER_LIP_TOP,
			FaceMesh.NOSE_BRIDGE,
			FaceMesh.RIGHT_EYE,
			FaceMesh.RIGHT_EYEBROW_BOTTOM,
			FaceMesh.RIGHT_EYEBROW_TOP,
			FaceMesh.UPPER_LIP_BOTTOM,
			FaceMesh.UPPER_LIP_TOP,
	};

	private static final String POINTS_PROPERTY = "points";
	private static final String TRIANGLES_PROPERTY = "triangles";
	private static final String CONTOURS_PROPERTY = "contours";

	private FaceMesh faceMesh;

	public FaceMeshInfo(FaceMesh faceMesh) {
		this.faceMesh = faceMesh;
	}

	// -------------------------------------------------------------------------
	// buildRawData
	//
	// Converts a FaceMesh object into a Godot Dictionary with the
	// following structure (all coordinates are NORMALISED to [0, 1]):
	//
	// {
	//   "points": [             ← Object[] of 468 entries, each Object[3]
	//     [x, y, z],            ← double; x,y normalised 0–1; z is relative depth
	//     …
	//   ],
	//   "triangles": [          ← Object[] of triangle entries, each Object[3]
	//     [i, j, k],            ← long indices into the "points" array
	//     …
	//   ],
	//   "contours": {           ← Dictionary keyed by contour name
	//     "face_oval":          ← Object[] of points on this contour, each Object[3]
	//       [[x, y, z], …],
	//     "left_eye":           [[x, y, z], …],
	//     "left_eyebrow_bottom": [[x, y, z], …],
	//     "left_eyebrow_top":   [[x, y, z], …],
	//     "lower_lip_bottom":   [[x, y, z], …],
	//     "lower_lip_top":      [[x, y, z], …],
	//     "nose_bridge":        [[x, y, z], …],
	//     "right_eye":          [[x, y, z], …],
	//     "right_eyebrow_bottom": [[x, y, z], …],
	//     "right_eyebrow_top":  [[x, y, z], …],
	//     "upper_lip_bottom":   [[x, y, z], …],
	//     "upper_lip_top":      [[x, y, z], …],
	//   }
	// }
	// -------------------------------------------------------------------------
	public Dictionary buildRawData(int imageWidth, int imageHeight) {
		Dictionary dict = new Dictionary();

		List<FaceMeshPoint> allPoints = faceMesh.getAllPoints();
		List<Triangle<FaceMeshPoint>> triangles = faceMesh.getAllTriangles();

		// --- points ---
		Object[] pointsArray = new Object[allPoints.size()];
		for (int i = 0; i < allPoints.size(); i++) {
			PointF3D pos = allPoints.get(i).getPosition();
			// Normalise pixel-space x/y to [0, 1]; z stays as-is (depth).
			pointsArray[i] = new Object[]{
					(double) (pos.getX() / imageWidth),
					(double) (pos.getY() / imageHeight),
					(double) pos.getZ()
			};
		}

		// --- triangles (as index triples into the points array) ---
		Object[] trianglesArray = new Object[triangles.size()];
		for (int i = 0; i < triangles.size(); i++) {
			List<FaceMeshPoint> tri = triangles.get(i).getAllPoints();
			trianglesArray[i] = new Object[]{
					(long) tri.get(0).getIndex(),
					(long) tri.get(1).getIndex(),
					(long) tri.get(2).getIndex()
			};
		}

		// --- contours ---
		// Each contour is a named subset of the 468 mesh points that traces
		// a specific facial feature (eye, eyebrow, lip edge, etc.).
		// The dictionary lets GDScript do:
		//   var oval = face["contours"]["face_oval"]
		//   var pt   = oval[0]  # [x, y, z] normalised
		Dictionary contoursDict = new Dictionary();
		for (int c = 0; c < CONTOUR_KEYS.length; c++) {
			List<FaceMeshPoint> contourPoints = faceMesh.getPoints(CONTOUR_TYPES[c]);
			Object[] contourArray = new Object[contourPoints.size()];
			for (int i = 0; i < contourPoints.size(); i++) {
				PointF3D pos = contourPoints.get(i).getPosition();
				contourArray[i] = new Object[]{
						(double) (pos.getX() / imageWidth),
						(double) (pos.getY() / imageHeight),
						(double) pos.getZ()
				};
			}
			contoursDict.put(CONTOUR_KEYS[c], contourArray);
		}

		dict.put(POINTS_PROPERTY, pointsArray);
		dict.put(TRIANGLES_PROPERTY, trianglesArray);
		dict.put(CONTOURS_PROPERTY, contoursDict);

		return dict;
	}
}

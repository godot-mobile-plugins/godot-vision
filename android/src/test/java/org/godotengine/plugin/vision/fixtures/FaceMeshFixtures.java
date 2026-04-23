//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.fixtures;

import com.google.mlkit.vision.common.PointF3D;
import com.google.mlkit.vision.common.Triangle;
import com.google.mlkit.vision.facemesh.FaceMesh;
import com.google.mlkit.vision.facemesh.FaceMeshPoint;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Factory helpers for building {@link FaceMesh} test fixtures.
 *
 * <p>All coordinates use a canonical 100 × 100 image so normalised values
 * are trivially computable (pixel ÷ 100 = normalised).
 *
 * <h3>Available fixtures</h3>
 * <ul>
 *   <li>{@link #minimalFace()} – 3 points, 1 triangle, every contour populated
 *       with the first 3 shared points.</li>
 *   <li>{@link #singlePointFace(float, float, float)} – a face reduced to one
 *       landmark, useful for edge-case arithmetic assertions.</li>
 *   <li>{@link #multipleFaces(int)} – builds N cloned minimal faces.</li>
 * </ul>
 */
public final class FaceMeshFixtures {

	// -- Canonical image dimensions used by all fixtures -------------------
	public static final int IMAGE_WIDTH = 100;
	public static final int IMAGE_HEIGHT = 100;

	private FaceMeshFixtures() {
	}

	// -- Public fixtures ----------------------------------------------------

	/**
	* A face with 3 points at known pixel coordinates, one triangle, and every
	* recognised contour populated with the same 3 points.
	*
	* <pre>
	* Point 0: pixel (10, 20, 0.5)  -> normalised (0.10, 0.20, 0.5)
	* Point 1: pixel (50, 60, 1.0)  -> normalised (0.50, 0.60, 1.0)
	* Point 2: pixel (80, 30, 0.0)  -> normalised (0.80, 0.30, 0.0)
	* Triangle: (0, 1, 2)
	* </pre>
	*/
	public static FaceMesh minimalFace() {
		List<FaceMeshPoint> points = new ArrayList<>();
		points.add(new FaceMeshPoint(0, PointF3D.from(10f, 20f, 0.5f)));
		points.add(new FaceMeshPoint(1, PointF3D.from(50f, 60f, 1.0f)));
		points.add(new FaceMeshPoint(2, PointF3D.from(80f, 30f, 0.0f)));

		List<Triangle<FaceMeshPoint>> triangles = new ArrayList<>();
		triangles.add(new Triangle<>(points.get(0), points.get(1), points.get(2)));

		Map<Integer, List<FaceMeshPoint>> contours = allContoursFrom(points);

		return new FaceMesh(points, triangles, contours);
	}

	/**
	* A degenerate face with a single landmark.  Useful for verifying
	* normalisation arithmetic on an isolated coordinate.
	*
	* @param px pixel x
	* @param py pixel y
	* @param pz depth (not normalised)
	*/
	public static FaceMesh singlePointFace(float px, float py, float pz) {
		List<FaceMeshPoint> points = new ArrayList<>();
		points.add(new FaceMeshPoint(0, PointF3D.from(px, py, pz)));

		Map<Integer, List<FaceMeshPoint>> contours = allContoursFrom(points);

		return new FaceMesh(points, new ArrayList<>(), contours);
	}

	/**
	* Returns a list of {@code count} cloned minimal faces.
	* Each face is an independent {@link FaceMesh} instance with the same data.
	*/
	public static List<FaceMesh> multipleFaces(int count) {
		List<FaceMesh> faces = new ArrayList<>();
		for (int i = 0; i < count; i++) {
			faces.add(minimalFace());
		}
		return faces;
	}

	/**
	* Returns a valid 4-byte-per-pixel RGBA8 buffer for the canonical
	* {@value IMAGE_WIDTH}×{@value IMAGE_HEIGHT} image (all pixels white).
	*/
	public static byte[] rgbaBuffer() {
		return rgbaBuffer(IMAGE_WIDTH, IMAGE_HEIGHT);
	}

	/**
	* Returns a valid RGBA8 buffer for an arbitrary image size (all pixels white).
	*/
	public static byte[] rgbaBuffer(int width, int height) {
		byte[] buf = new byte[width * height * 4];
		for (int i = 0; i < buf.length; i += 4) {
			buf[i] = (byte) 0xFF; // R
			buf[i + 1] = (byte) 0xFF; // G
			buf[i + 2] = (byte) 0xFF; // B
			buf[i + 3] = (byte) 0xFF; // A
		}
		return buf;
	}

	// -- Private helpers ----------------------------------------------------

	/**
	* Populates every contour type recognised by {@code FaceMeshInfo} with
	* the supplied point list so that no contour returns an empty array.
	*/
	private static Map<Integer, List<FaceMeshPoint>> allContoursFrom(
			List<FaceMeshPoint> points) {
		int[] allTypes = {
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
		Map<Integer, List<FaceMeshPoint>> contours = new HashMap<>();
		for (int type : allTypes) {
			contours.put(type, new ArrayList<>(points));
		}
		return contours;
	}
}

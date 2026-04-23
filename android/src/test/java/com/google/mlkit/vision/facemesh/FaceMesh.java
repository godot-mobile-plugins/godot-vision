//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.mlkit.vision.facemesh;

import com.google.mlkit.vision.common.Triangle;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Stub for {@code com.google.mlkit.vision.facemesh.FaceMesh}.
 *
 * <p>Exposes the same contour-type integer constants as the real class and
 * allows tests to configure the point / triangle / contour data via the
 * builder or constructor.
 */
public final class FaceMesh {

	// -- Contour type constants (match real ML Kit values) -----------------
	public static final int FACE_OVAL = 1;
	public static final int LEFT_EYE = 2;
	public static final int LEFT_EYEBROW_BOTTOM = 3;
	public static final int LEFT_EYEBROW_TOP = 4;
	public static final int LOWER_LIP_BOTTOM = 5;
	public static final int LOWER_LIP_TOP = 6;
	public static final int NOSE_BRIDGE = 7;
	public static final int RIGHT_EYE = 8;
	public static final int RIGHT_EYEBROW_BOTTOM = 9;
	public static final int RIGHT_EYEBROW_TOP = 10;
	public static final int UPPER_LIP_BOTTOM = 11;
	public static final int UPPER_LIP_TOP = 12;

	// -- State --------------------------------------------------------------
	private final List<FaceMeshPoint>               allPoints;
	private final List<Triangle<FaceMeshPoint>>     allTriangles;
	private final Map<Integer, List<FaceMeshPoint>> contours;

	public FaceMesh(
			List<FaceMeshPoint>           allPoints,
			List<Triangle<FaceMeshPoint>> allTriangles,
			Map<Integer, List<FaceMeshPoint>> contours) {
		this.allPoints = Collections.unmodifiableList(allPoints);
		this.allTriangles = Collections.unmodifiableList(allTriangles);
		this.contours = new HashMap<>(contours);
	}

	// -- Real API surface ---------------------------------------------------

	public List<FaceMeshPoint> getAllPoints() {
		return allPoints;
	}

	public List<Triangle<FaceMeshPoint>> getAllTriangles() {
		return allTriangles;
	}

	/** Returns the contour points for the given {@code contourType}, or empty list. */
	public List<FaceMeshPoint> getPoints(int contourType) {
		return contours.getOrDefault(contourType, Collections.emptyList());
	}
}

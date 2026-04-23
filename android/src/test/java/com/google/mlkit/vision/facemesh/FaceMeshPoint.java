//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.mlkit.vision.facemesh;

import com.google.mlkit.vision.common.PointF3D;

/**
 * Stub for {@code com.google.mlkit.vision.facemesh.FaceMeshPoint}.
 * Each point has a zero-based index into the 468-landmark array and a 3-D position.
 */
public final class FaceMeshPoint {

	private final int index;
	private final PointF3D position;

	public FaceMeshPoint(int index, PointF3D position) {
		this.index = index;
		this.position = position;
	}

	public int getIndex() {
		return index;
	}

	public PointF3D getPosition() {
		return position;
	}

	@Override
	public String toString() {
		return "FaceMeshPoint{index=" + index + ", pos=" + position + "}";
	}
}

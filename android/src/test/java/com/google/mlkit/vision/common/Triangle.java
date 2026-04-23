//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.mlkit.vision.common;

import java.util.Arrays;
import java.util.List;

/**
 * Stub for {@code com.google.mlkit.vision.common.Triangle<T>}.
 * Holds exactly three vertex objects of type T.
 */
public final class Triangle<T> {

	private final List<T> points;

	public Triangle(T v0, T v1, T v2) {
		this.points = Arrays.asList(v0, v1, v2);
	}

	/** Returns an unmodifiable, fixed-size list of the three vertices. */
	public List<T> getAllPoints() {
		return points;
	}
}

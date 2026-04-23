//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.mlkit.vision.common;

/**
 * Stub for {@code com.google.mlkit.vision.common.PointF3D}.
 * Represents a 3-D point with x/y in pixel space and z as relative depth.
 */
public final class PointF3D {

	private final float x;
	private final float y;
	private final float z;

	private PointF3D(float x, float y, float z) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/** Factory matching the real ML Kit API. */
	public static PointF3D from(float x, float y, float z) {
		return new PointF3D(x, y, z);
	}

	public float getX() {
		return x;
	}

	public float getY() {
		return y;
	}

	public float getZ() {
		return z;
	}

	@Override
	public String toString() {
		return "PointF3D{x=" + x + ", y=" + y + ", z=" + z + "}";
	}
}

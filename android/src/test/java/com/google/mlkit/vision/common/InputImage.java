//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.mlkit.vision.common;

import android.graphics.Bitmap;

/**
 * Stub for {@code com.google.mlkit.vision.common.InputImage}.
 * Only the factory method used by the plugin is implemented.
 */
public final class InputImage {

	private InputImage() {
	}

	/**
	* Returns a non-null stub instance; the image data is not inspected
	* by the test infrastructure.
	*/
	public static InputImage fromBitmap(Bitmap bitmap, int rotationDegrees) {
		return new InputImage();
	}
}

//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.fixtures;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.vision.model.ImageInfo;

/**
 * Factory helpers for {@link ImageInfo} / image-dict test fixtures.
 *
 * <p>All helpers return a {@link Dictionary} with the exact keys the plugin
 * reads so tests can construct valid (and deliberately invalid) image payloads
 * without coupling to the key-string constants buried in {@code ImageInfo}.
 */
public final class ImageInfoFixtures {

	private ImageInfoFixtures() {
	}

	// -- Valid payloads -----------------------------------------------------

	/**
	* A fully-populated, valid image dictionary for the canonical
	* {@value FaceMeshFixtures#IMAGE_WIDTH}×{@value FaceMeshFixtures#IMAGE_HEIGHT}
	* image.
	*/
	public static Dictionary validImageDict() {
		return validImageDict(
				FaceMeshFixtures.IMAGE_WIDTH,
				FaceMeshFixtures.IMAGE_HEIGHT);
	}

	/**
	* A fully-populated, valid image dictionary for a custom size.
	* The pixel buffer is filled with opaque white RGBA8 values.
	*/
	public static Dictionary validImageDict(int width, int height) {
		ImageInfo info = new ImageInfo();
		info.setBuffer(FaceMeshFixtures.rgbaBuffer(width, height));
		info.setWidth(width);
		info.setHeight(height);
		info.setFormat(4);           // Godot Image.FORMAT_RGBA8
		info.setHasMipmaps(false);
		return info.getRawData();
	}

	// -- Invalid / edge-case payloads ---------------------------------------

	/** A dictionary where the pixel buffer is {@code null}. */
	public static Dictionary nullBufferDict() {
		ImageInfo info = new ImageInfo();
		// buffer intentionally not set -> getBuffer() returns null
		info.setWidth(FaceMeshFixtures.IMAGE_WIDTH);
		info.setHeight(FaceMeshFixtures.IMAGE_HEIGHT);
		info.setFormat(4);
		return info.getRawData();
	}

	/** A dictionary with width = 0 (invalid dimensions). */
	public static Dictionary zeroDimensionDict() {
		ImageInfo info = new ImageInfo();
		info.setBuffer(new byte[0]);
		info.setWidth(0);
		info.setHeight(0);
		info.setFormat(4);
		return info.getRawData();
	}

	/** A completely empty dictionary – simulates a caller bug. */
	public static Dictionary emptyDict() {
		return new Dictionary();
	}

	/** A dictionary with negative width – triggers validation path. */
	public static Dictionary negativeDimensionDict() {
		ImageInfo info = new ImageInfo();
		info.setBuffer(new byte[4]);
		info.setWidth(-1);
		info.setHeight(100);
		info.setFormat(4);
		return info.getRawData();
	}
}

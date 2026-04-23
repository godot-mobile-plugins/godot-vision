//
// © 2026-present https://github.com/cengiz-pz
//

package android.graphics;

import java.nio.Buffer;

/**
 * Bitmap stub – stands in for the real Android Bitmap in JVM unit tests.
 * {@code createBitmap} returns a live (non-null) stub instance so that the
 * production code path that calls {@code copyPixelsFromBuffer} does not NPE.
 */
public class Bitmap {

	public enum Config { ARGB_8888, RGB_565, ALPHA_8
	}

	private final int width;
	private final int height;

	private Bitmap(int width, int height) {
		this.width = width;
		this.height = height;
	}

	// -- Factory ------------------------------------------------------------

	public static Bitmap createBitmap(int width, int height, Config config) {
		return new Bitmap(width, height);
	}

	// -- Stub methods -------------------------------------------------------

	/** No-op – the buffer is ignored in tests; the bitmap data is irrelevant. */
	public void copyPixelsFromBuffer(Buffer src) { /* no-op */
	}

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}
}

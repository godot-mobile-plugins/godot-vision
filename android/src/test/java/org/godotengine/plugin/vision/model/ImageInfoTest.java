//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.model;

import org.godotengine.godot.Dictionary;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests for {@link ImageInfo}.
 *
 * Covers:
 *  – default sentinel values when constructed from an empty dictionary
 *  – round-trip fidelity for every setter / getter pair
 *  – type coercion: Godot stores integers as {@code long}; {@code toInt()} must
 *    convert transparently
 *  – {@code getRawData()} returns the same backing dictionary, not a copy
 */
@DisplayName("ImageInfo")
class ImageInfoTest {

	// -- Default values -----------------------------------------------------

	@Nested
	@DisplayName("defaults when constructed from empty dict")
	class Defaults {

		private final ImageInfo info = new ImageInfo(new Dictionary());

		@Test
		@DisplayName("getBuffer() returns null")
		void bufferIsNull() {
			assertNull(info.getBuffer());
		}

		@Test
		@DisplayName("getWidth() returns -1")
		void widthIsMinusOne() {
			assertEquals(-1, info.getWidth());
		}

		@Test
		@DisplayName("getHeight() returns -1")
		void heightIsMinusOne() {
			assertEquals(-1, info.getHeight());
		}

		@Test
		@DisplayName("getFormat() returns 3 (FORMAT_RGB8 fallback)")
		void formatIsFallback() {
			assertEquals(3, info.getFormat());
		}

		@Test
		@DisplayName("hasMipmaps() returns false")
		void mipmapsAreFalse() {
			assertFalse(info.hasMipmaps());
		}
	}

	// -- No-arg constructor -------------------------------------------------

	@Nested
	@DisplayName("no-arg constructor produces same defaults")
	class NoArgConstructor {

		private final ImageInfo info = new ImageInfo();

		@Test
		void bufferIsNull() {
			assertNull(info.getBuffer());
		}

		@Test
		void widthIsMinusOne() {
			assertEquals(-1, info.getWidth());
		}

		@Test
		void heightIsMinusOne() {
			assertEquals(-1, info.getHeight());
		}
	}

	// -- Round-trip ---------------------------------------------------------

	@Nested
	@DisplayName("setter / getter round-trips")
	class RoundTrip {

		private final ImageInfo info = new ImageInfo();

		@Test
		@DisplayName("buffer survives set -> get")
		void buffer() {
			byte[] buf = {1, 2, 3, 4};
			info.setBuffer(buf);
			assertArrayEquals(buf, info.getBuffer());
		}

		@Test
		@DisplayName("width survives set -> get (stored as long, read as int)")
		void width() {
			info.setWidth(640);
			assertEquals(640, info.getWidth());
		}

		@Test
		@DisplayName("height survives set -> get")
		void height() {
			info.setHeight(480);
			assertEquals(480, info.getHeight());
		}

		@Test
		@DisplayName("format survives set -> get")
		void format() {
			info.setFormat(4);
			assertEquals(4, info.getFormat());
		}

		@Test
		@DisplayName("hasMipmaps survives set(true) -> get")
		void hasMipmaps() {
			info.setHasMipmaps(true);
			assertTrue(info.hasMipmaps());
		}
	}

	// -- Dictionary backing -------------------------------------------------

	@Nested
	@DisplayName("getRawData()")
	class RawData {

		@Test
		@DisplayName("returns the same object passed to the dictionary constructor")
		void returnsSameInstance() {
			Dictionary original = new Dictionary();
			ImageInfo info = new ImageInfo(original);
			assertSame(original, info.getRawData());
		}

		@Test
		@DisplayName("mutations via setters are visible in the returned dictionary")
		void settersMutateBackingDict() {
			ImageInfo info = new ImageInfo();
			info.setWidth(320);
			// width is stored as long in the dict
			assertEquals(320L, info.getRawData().get("width"));
		}

		@Test
		@DisplayName("format stored as long in backing dictionary")
		void formatStoredAsLong() {
			ImageInfo info = new ImageInfo();
			info.setFormat(4);
			Object stored = info.getRawData().get("format");
			assertInstanceOf(Long.class, stored);
			assertEquals(4L, stored);
		}
	}

	// -- Type-coercion edge cases -------------------------------------------

	@Nested
	@DisplayName("long -> int coercion")
	class Coercion {

		@Test
		@DisplayName("width stored as Long.MAX_VALUE truncates gracefully via intValue()")
		void widthCoercionOverflow() {
			Dictionary dict = new Dictionary();
			dict.put("width", Long.MAX_VALUE);
			ImageInfo info = new ImageInfo(dict);
			// Just confirm no exception is thrown; the value wraps per Java spec.
			assertDoesNotThrow(info::getWidth);
		}

		@Test
		@DisplayName("height of exactly Integer.MAX_VALUE round-trips correctly")
		void heightMaxInt() {
			ImageInfo info = new ImageInfo();
			info.setHeight(Integer.MAX_VALUE);
			assertEquals(Integer.MAX_VALUE, info.getHeight());
		}
	}
}

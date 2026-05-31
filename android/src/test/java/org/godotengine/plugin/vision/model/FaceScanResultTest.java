//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.model;

import com.google.mlkit.vision.facemesh.FaceMesh;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.vision.fixtures.FaceMeshFixtures;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests for {@link FaceScanResult}.
 *
 * Covers:
 *  - top-level keys: "image", "faces"
 *  - "image" sub-dictionary contains all ImageInfo fields
 *    (buffer, width, height, format, has_mipmaps)
 *  - width / height values round-trip through the ImageInfo sub-dictionary
 *  - "faces" length matches the number of supplied FaceMesh objects
 *  - each face entry is a Dictionary with "points", "triangles", "contours"
 *  - empty face list produces an empty "faces" array (not null)
 *  - multiple faces are each serialised independently
 */
@DisplayName("FaceScanResult")
class FaceScanResultTest {

	private static final int W = FaceMeshFixtures.IMAGE_WIDTH;   // 100
	private static final int H = FaceMeshFixtures.IMAGE_HEIGHT;  // 100

	// -- Helpers ------------------------------------------------------------

	/**
	 * Builds a minimal ImageInfo Dictionary that mirrors what Vision.gd passes
	 * to the plugin after converting the image to FORMAT_RGBA8.
	 * An empty buffer is sufficient for structural tests; FaceScanResult only
	 * stores and re-emits the dictionary without inspecting pixel data.
	 */
	private static Dictionary buildImageInfoDict(int width, int height) {
		Dictionary d = new Dictionary();
		d.put("buffer", new byte[0]);   // empty — not inspected by FaceScanResult
		d.put("width", (long) width);
		d.put("height", (long) height);
		d.put("format", 4L);            // Godot Image.FORMAT_RGBA8
		d.put("has_mipmaps", false);
		return d;
	}

	/** Returns a result built from a single minimal FaceMesh and the default dimensions. */
	private static Dictionary buildSingle() {
		List<FaceMesh> faces = List.of(FaceMeshFixtures.minimalFace());
		return new FaceScanResult(faces, new ImageInfo(buildImageInfoDict(W, H))).buildRawData();
	}

	/** Extracts the "faces" Object[] from a result dictionary. */
	private static Object[] facesArray(Dictionary dict) {
		return (Object[]) dict.get("faces");
	}

	/** Extracts and casts the "image" sub-dictionary from a result dictionary. */
	private static Dictionary imageDict(Dictionary dict) {
		return (Dictionary) dict.get("image");
	}

	// -- Top-level keys -----------------------------------------------------

	@Nested
	@DisplayName("top-level dictionary keys")
	class TopLevel {

		@Test
		@DisplayName("contains 'image'")
		void hasImage() {
			assertTrue(buildSingle().containsKey("image"));
		}

		@Test
		@DisplayName("contains 'faces'")
		void hasFaces() {
			assertTrue(buildSingle().containsKey("faces"));
		}

		@Test
		@DisplayName("does not contain legacy 'image_width' key")
		void doesNotHaveImageWidth() {
			// image_width was promoted into the "image" sub-dictionary.
			assertTrue(!buildSingle().containsKey("image_width"),
					"'image_width' should no longer be a top-level key");
		}

		@Test
		@DisplayName("does not contain legacy 'image_height' key")
		void doesNotHaveImageHeight() {
			// image_height was promoted into the "image" sub-dictionary.
			assertTrue(!buildSingle().containsKey("image_height"),
					"'image_height' should no longer be a top-level key");
		}
	}

	// -- Image sub-dictionary structure -------------------------------------

	@Nested
	@DisplayName("image sub-dictionary")
	class ImageSubDictionary {

		@Test
		@DisplayName("'image' value is a Dictionary")
		void imageIsDictionary() {
			assertInstanceOf(Dictionary.class, buildSingle().get("image"));
		}

		@Test
		@DisplayName("'image' contains 'buffer'")
		void hasBuffer() {
			assertTrue(imageDict(buildSingle()).containsKey("buffer"));
		}

		@Test
		@DisplayName("'image' contains 'width'")
		void hasWidth() {
			assertTrue(imageDict(buildSingle()).containsKey("width"));
		}

		@Test
		@DisplayName("'image' contains 'height'")
		void hasHeight() {
			assertTrue(imageDict(buildSingle()).containsKey("height"));
		}

		@Test
		@DisplayName("'image' contains 'format'")
		void hasFormat() {
			assertTrue(imageDict(buildSingle()).containsKey("format"));
		}

		@Test
		@DisplayName("'image' contains 'has_mipmaps'")
		void hasHasMipmaps() {
			assertTrue(imageDict(buildSingle()).containsKey("has_mipmaps"));
		}
	}

	// -- Image dimensions ---------------------------------------------------

	@Nested
	@DisplayName("image dimensions (inside 'image' sub-dictionary)")
	class Dimensions {

		@Test
		@DisplayName("width is stored as Long")
		void widthIsLong() {
			assertInstanceOf(Long.class, imageDict(buildSingle()).get("width"));
		}

		@Test
		@DisplayName("height is stored as Long")
		void heightIsLong() {
			assertInstanceOf(Long.class, imageDict(buildSingle()).get("height"));
		}

		@Test
		@DisplayName("width value matches ImageInfo argument")
		void widthValue() {
			assertEquals((long) W, imageDict(buildSingle()).get("width"));
		}

		@Test
		@DisplayName("height value matches ImageInfo argument")
		void heightValue() {
			assertEquals((long) H, imageDict(buildSingle()).get("height"));
		}

		@Test
		@DisplayName("non-standard dimensions are preserved exactly")
		void nonStandardDimensions() {
			List<FaceMesh> faces = List.of(FaceMeshFixtures.minimalFace());
			Dictionary dict = new FaceScanResult(
					faces, new ImageInfo(buildImageInfoDict(1920, 1080))).buildRawData();
			assertEquals(1920L, imageDict(dict).get("width"));
			assertEquals(1080L, imageDict(dict).get("height"));
		}

		@Test
		@DisplayName("format value is preserved (FORMAT_RGBA8 == 4)")
		void formatValue() {
			assertEquals(4L, imageDict(buildSingle()).get("format"));
		}

		@Test
		@DisplayName("has_mipmaps value is preserved")
		void hasMipmapsValue() {
			assertEquals(false, imageDict(buildSingle()).get("has_mipmaps"));
		}
	}

	// -- Faces array --------------------------------------------------------

	@Nested
	@DisplayName("faces array")
	class FacesArray {

		@Test
		@DisplayName("single face list -> faces array of length 1")
		void singleFace() {
			assertEquals(1, facesArray(buildSingle()).length);
		}

		@Test
		@DisplayName("two-face list -> faces array of length 2")
		void twoFaces() {
			List<FaceMesh> faces = FaceMeshFixtures.multipleFaces(2);
			Dictionary dict = new FaceScanResult(
					faces, new ImageInfo(buildImageInfoDict(W, H))).buildRawData();
			assertEquals(2, facesArray(dict).length);
		}

		@Test
		@DisplayName("five-face list -> faces array of length 5")
		void fiveFaces() {
			List<FaceMesh> faces = FaceMeshFixtures.multipleFaces(5);
			Dictionary dict = new FaceScanResult(
					faces, new ImageInfo(buildImageInfoDict(W, H))).buildRawData();
			assertEquals(5, facesArray(dict).length);
		}

		@Test
		@DisplayName("empty face list -> non-null faces array of length 0")
		void emptyFaceList() {
			Dictionary dict = new FaceScanResult(
					Collections.emptyList(),
					new ImageInfo(buildImageInfoDict(W, H))).buildRawData();
			Object[] faces = facesArray(dict);
			assertNotNull(faces);
			assertEquals(0, faces.length);
		}

		@Test
		@DisplayName("each face entry is a Dictionary")
		void eachFaceIsDictionary() {
			Dictionary dict = buildSingle();
			for (Object face : facesArray(dict)) {
				assertInstanceOf(Dictionary.class, face,
						"Every face entry must be a Dictionary");
			}
		}

		@Test
		@DisplayName("each face Dictionary contains 'points', 'triangles', 'contours'")
		void eachFaceHasRequiredKeys() {
			Dictionary dict = buildSingle();
			Dictionary face = (Dictionary) facesArray(dict)[0];
			assertTrue(face.containsKey("points"), "face must have 'points'");
			assertTrue(face.containsKey("triangles"), "face must have 'triangles'");
			assertTrue(face.containsKey("contours"), "face must have 'contours'");
		}

		@Test
		@DisplayName("faces are serialised independently (not the same Object reference)")
		void facesAreIndependent() {
			List<FaceMesh> faces = FaceMeshFixtures.multipleFaces(2);
			Dictionary dict = new FaceScanResult(
					faces, new ImageInfo(buildImageInfoDict(W, H))).buildRawData();
			Object[] arr = facesArray(dict);
			assertNotSame(arr[0], arr[1],
					"Each face must be a separate Dictionary instance");
		}
	}
}

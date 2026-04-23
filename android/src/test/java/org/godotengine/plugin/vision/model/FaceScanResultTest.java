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
 *  – top-level keys: "image_width", "image_height", "faces"
 *  – image dimensions stored as {@code long}
 *  – "faces" length matches the number of supplied FaceMesh objects
 *  – each face entry is a Dictionary with "points", "triangles", "contours"
 *  – empty face list produces an empty "faces" array (not null)
 *  – multiple faces are each serialised independently
 */
@DisplayName("FaceScanResult")
class FaceScanResultTest {

	private static final int W = FaceMeshFixtures.IMAGE_WIDTH;   // 100
	private static final int H = FaceMeshFixtures.IMAGE_HEIGHT;  // 100

	// -- Helpers ------------------------------------------------------------

	private static Dictionary buildSingle() {
		List<FaceMesh> faces = List.of(FaceMeshFixtures.minimalFace());
		return new FaceScanResult(faces, W, H).buildRawData();
	}

	private static Object[] facesArray(Dictionary dict) {
		return (Object[]) dict.get("faces");
	}

	// -- Top-level keys -----------------------------------------------------

	@Nested
	@DisplayName("top-level dictionary keys")
	class TopLevel {

		@Test
		@DisplayName("contains 'image_width'")
		void hasImageWidth() {
			assertTrue(buildSingle().containsKey("image_width"));
		}

		@Test
		@DisplayName("contains 'image_height'")
		void hasImageHeight() {
			assertTrue(buildSingle().containsKey("image_height"));
		}

		@Test
		@DisplayName("contains 'faces'")
		void hasFaces() {
			assertTrue(buildSingle().containsKey("faces"));
		}
	}

	// -- Image dimensions ---------------------------------------------------

	@Nested
	@DisplayName("image dimensions")
	class Dimensions {

		@Test
		@DisplayName("image_width is stored as Long")
		void imageWidthIsLong() {
			assertInstanceOf(Long.class, buildSingle().get("image_width"));
		}

		@Test
		@DisplayName("image_height is stored as Long")
		void imageHeightIsLong() {
			assertInstanceOf(Long.class, buildSingle().get("image_height"));
		}

		@Test
		@DisplayName("image_width value matches constructor argument")
		void imageWidthValue() {
			assertEquals((long) W, buildSingle().get("image_width"));
		}

		@Test
		@DisplayName("image_height value matches constructor argument")
		void imageHeightValue() {
			assertEquals((long) H, buildSingle().get("image_height"));
		}

		@Test
		@DisplayName("non-standard dimensions are preserved exactly")
		void nonStandardDimensions() {
			List<FaceMesh> faces = List.of(FaceMeshFixtures.minimalFace());
			Dictionary dict = new FaceScanResult(faces, 1920, 1080).buildRawData();
			assertEquals(1920L, dict.get("image_width"));
			assertEquals(1080L, dict.get("image_height"));
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
			Dictionary dict = new FaceScanResult(faces, W, H).buildRawData();
			assertEquals(2, facesArray(dict).length);
		}

		@Test
		@DisplayName("five-face list -> faces array of length 5")
		void fiveFaces() {
			List<FaceMesh> faces = FaceMeshFixtures.multipleFaces(5);
			Dictionary dict = new FaceScanResult(faces, W, H).buildRawData();
			assertEquals(5, facesArray(dict).length);
		}

		@Test
		@DisplayName("empty face list -> non-null faces array of length 0")
		void emptyFaceList() {
			Dictionary dict = new FaceScanResult(Collections.emptyList(), W, H).buildRawData();
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
			Dictionary dict = new FaceScanResult(faces, W, H).buildRawData();
			Object[] arr = facesArray(dict);
			assertNotSame(arr[0], arr[1],
					"Each face must be a separate Dictionary instance");
		}
	}
}

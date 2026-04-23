//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.model;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.vision.fixtures.FaceMeshFixtures;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests for {@link FaceMeshInfo}.
 *
 * Covers:
 *  – {@code buildRawData()} top-level key presence ("points", "triangles", "contours")
 *  – correct array lengths for points and triangles
 *  – x/y normalisation: pixel coord ÷ image dimension = [0, 1] double
 *  – z depth is passed through unchanged
 *  – triangle vertex indices map to the correct landmark indices
 *  – all 12 contour keys are present in the contours dictionary
 *  – each contour array contains the expected normalised coordinates
 */
@DisplayName("FaceMeshInfo")
class FaceMeshInfoTest {

	private static final int W = FaceMeshFixtures.IMAGE_WIDTH;   // 100
	private static final int H = FaceMeshFixtures.IMAGE_HEIGHT;  // 100
	private static final double DELTA = 1e-9;

	// -- Helpers ------------------------------------------------------------

	/** Builds a FaceMeshInfo from the canonical minimal fixture. */
	private FaceMeshInfo minimalInfo() {
		return new FaceMeshInfo(FaceMeshFixtures.minimalFace());
	}

	/** Extracts the "points" Object[] from the result dictionary. */
	private static Object[] points(Dictionary dict) {
		return (Object[]) dict.get("points");
	}

	/** Extracts the "triangles" Object[] from the result dictionary. */
	private static Object[] triangles(Dictionary dict) {
		return (Object[]) dict.get("triangles");
	}

	/** Extracts the "contours" Dictionary from the result dictionary. */
	private static Dictionary contours(Dictionary dict) {
		return (Dictionary) dict.get("contours");
	}

	/** Reads one normalised point as Object[]{x, y, z}. */
	private static Object[] point(Object[] pointsArray, int idx) {
		return (Object[]) pointsArray[idx];
	}

	// -- Top-level structure ------------------------------------------------

	@Nested
	@DisplayName("top-level dictionary keys")
	class TopLevel {

		private Dictionary dict;

		@BeforeEach
		void build() {
			dict = minimalInfo().buildRawData(W, H);
		}

		@Test
		@DisplayName("contains 'points'")
		void hasPoints() {
			assertTrue(dict.containsKey("points"));
		}

		@Test
		@DisplayName("contains 'triangles'")
		void hasTriangles() {
			assertTrue(dict.containsKey("triangles"));
		}

		@Test
		@DisplayName("contains 'contours'")
		void hasContours() {
			assertTrue(dict.containsKey("contours"));
		}
	}

	// -- Points array -------------------------------------------------------

	@Nested
	@DisplayName("points array")
	class Points {

		@Test
		@DisplayName("length matches number of FaceMeshPoints")
		void correctLength() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			assertEquals(3, points(dict).length);
		}

		@Test
		@DisplayName("each entry is Object[3]")
		void eachEntryIsTriple() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			for (Object p : points(dict)) {
				Object[] triple = (Object[]) p;
				assertEquals(3, triple.length, "Each point must have [x, y, z]");
			}
		}

		@Test
		@DisplayName("x is normalised: pixel(10) / width(100) == 0.10")
		void xNormalised() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			double x = (double) point(points(dict), 0)[0];
			assertEquals(10.0 / 100.0, x, DELTA);
		}

		@Test
		@DisplayName("y is normalised: pixel(20) / height(100) == 0.20")
		void yNormalised() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			double y = (double) point(points(dict), 0)[1];
			assertEquals(20.0 / 100.0, y, DELTA);
		}

		@Test
		@DisplayName("z is passed through unchanged (depth 0.5)")
		void zPassedThrough() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			double z = (double) point(points(dict), 0)[2];
			assertEquals(0.5, z, DELTA);
		}

		@Test
		@DisplayName("second point normalised correctly: pixel(50,60) -> (0.50, 0.60)")
		void secondPointNormalised() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			Object[] p1 = point(points(dict), 1);
			assertEquals(0.50, (double) p1[0], DELTA);
			assertEquals(0.60, (double) p1[1], DELTA);
		}

		@Test
		@DisplayName("all coordinate components are Double instances")
		void coordinatesAreDoubles() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			for (Object rawPoint : points(dict)) {
				Object[] triple = (Object[]) rawPoint;
				assertInstanceOf(Double.class, triple[0], "x must be Double");
				assertInstanceOf(Double.class, triple[1], "y must be Double");
				assertInstanceOf(Double.class, triple[2], "z must be Double");
			}
		}

		@Test
		@DisplayName("single-point face with pixel(0,0) -> normalised (0.0, 0.0)")
		void originPointNormalisesToZero() {
			FaceMeshInfo info = new FaceMeshInfo(FaceMeshFixtures.singlePointFace(0f, 0f, 0f));
			Dictionary dict = info.buildRawData(W, H);
			Object[] p = point(points(dict), 0);
			assertEquals(0.0, (double) p[0], DELTA);
			assertEquals(0.0, (double) p[1], DELTA);
		}

		@Test
		@DisplayName("pixel at image edge normalises to exactly 1.0")
		void edgePointNormalisesToOne() {
			// pixel (100, 100) on a 100×100 image
			FaceMeshInfo info = new FaceMeshInfo(
					FaceMeshFixtures.singlePointFace(100f, 100f, 0f));
			Dictionary dict = info.buildRawData(W, H);
			Object[] p = point(points(dict), 0);
			assertEquals(1.0, (double) p[0], DELTA);
			assertEquals(1.0, (double) p[1], DELTA);
		}
	}

	// -- Triangles array ----------------------------------------------------

	@Nested
	@DisplayName("triangles array")
	class Triangles {

		@Test
		@DisplayName("length matches number of triangles in the mesh")
		void correctLength() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			assertEquals(1, triangles(dict).length);
		}

		@Test
		@DisplayName("each triangle is Object[3]")
		void eachEntryIsTriple() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			Object[] tri = (Object[]) triangles(dict)[0];
			assertEquals(3, tri.length);
		}

		@Test
		@DisplayName("triangle indices are Long values")
		void indicesAreLong() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			Object[] tri = (Object[]) triangles(dict)[0];
			assertInstanceOf(Long.class, tri[0]);
			assertInstanceOf(Long.class, tri[1]);
			assertInstanceOf(Long.class, tri[2]);
		}

		@Test
		@DisplayName("triangle (0,1,2) indices match source FaceMeshPoint indices")
		void indicesMatchSourcePoints() {
			Dictionary dict = minimalInfo().buildRawData(W, H);
			Object[] tri = (Object[]) triangles(dict)[0];
			assertEquals(0L, tri[0]);
			assertEquals(1L, tri[1]);
			assertEquals(2L, tri[2]);
		}

		@Test
		@DisplayName("face with no triangles produces an empty triangles array")
		void emptyTrianglesArray() {
			FaceMeshInfo info = new FaceMeshInfo(
					FaceMeshFixtures.singlePointFace(10f, 10f, 0f));
			Dictionary dict = info.buildRawData(W, H);
			assertEquals(0, triangles(dict).length);
		}
	}

	// -- Contours -----------------------------------------------------------

	@Nested
	@DisplayName("contours dictionary")
	class Contours {

		private static final String[] EXPECTED_KEYS = {
				"face_oval",
				"left_eye",
				"left_eyebrow_bottom",
				"left_eyebrow_top",
				"lower_lip_bottom",
				"lower_lip_top",
				"nose_bridge",
				"right_eye",
				"right_eyebrow_bottom",
				"right_eyebrow_top",
				"upper_lip_bottom",
				"upper_lip_top",
		};

		private Dictionary contoursDict;

		@BeforeEach
		void build() {
			contoursDict = contours(minimalInfo().buildRawData(W, H));
		}

		@Test
		@DisplayName("all 12 contour keys are present")
		void allKeysPresent() {
			for (String key : EXPECTED_KEYS) {
				assertTrue(contoursDict.containsKey(key),
						"Missing contour key: " + key);
			}
		}

		@Test
		@DisplayName("each contour value is an Object[]")
		void eachValueIsArray() {
			for (String key : EXPECTED_KEYS) {
				assertInstanceOf(Object[].class, contoursDict.get(key),
						key + " must be Object[]");
			}
		}

		@Test
		@DisplayName("face_oval contour has the same point count as the fixture provides")
		void faceOvalLength() {
			Object[] oval = (Object[]) contoursDict.get("face_oval");
			// minimalFace() populates each contour with the 3 shared points
			assertEquals(3, oval.length);
		}

		@Test
		@DisplayName("contour point coordinates are normalised doubles")
		void contourPointsAreNormalised() {
			Object[] leftEye = (Object[]) contoursDict.get("left_eye");
			Object[] first = (Object[]) leftEye[0];
			// point 0 is at pixel (10, 20) on a 100×100 image
			assertEquals(0.10, (double) first[0], DELTA, "x");
			assertEquals(0.20, (double) first[1], DELTA, "y");
		}

		@Test
		@DisplayName("nose_bridge contour is not null")
		void noseBridgeNotNull() {
			assertNotNull(contoursDict.get("nose_bridge"));
		}
	}

	// -- Different image dimensions -----------------------------------------

	@Nested
	@DisplayName("normalisation with non-square image dimensions")
	class NonSquareDimensions {

		@Test
		@DisplayName("x and y normalised against their respective axis dimensions")
		void differentWidthAndHeight() {
			// Point at pixel (40, 30), image 200×150
			FaceMeshInfo info = new FaceMeshInfo(
					FaceMeshFixtures.singlePointFace(40f, 30f, 2.5f));
			Dictionary dict = info.buildRawData(200, 150);
			Object[] p = point(points(dict), 0);

			assertEquals(40.0 / 200.0, (double) p[0], DELTA, "x normalisation");
			assertEquals(30.0 / 150.0, (double) p[1], DELTA, "y normalisation");
			assertEquals(2.5, (double) p[2], DELTA, "z passthrough");
		}
	}
}

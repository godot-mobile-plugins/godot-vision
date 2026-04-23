//
// © 2026-present https://github.com/cengiz-pz
//
// FaceMeshInfoTests.swift
//
// Validates FaceMeshInfo.buildNSDictionary() across a range of inputs:
//   • Correct top-level structure and key presence
//   • "points" array length and coordinate values
//   • "triangles" array length and vertex types
//   • "contours" dictionary keys and sub-array structure
//   • Edge case: landmark list shorter than the maximum contour index
//     (exercises the compactMap guard inside buildContoursDict)
//

@testable import vision_plugin
import XCTest

final class FaceMeshInfoTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: - Helpers
	// -----------------------------------------------------------------------

	private func buildDict(landmarks: [(x: Float, y: Float, z: Float)])
		-> NSDictionary {
		FaceMeshInfo(landmarks: landmarks).buildNSDictionary()
	}

	/// Convenience: build with the standard 468-point uniform fixture.
	private func buildStandardDict() -> NSDictionary {
		buildDict(landmarks: TestFixtures.uniformLandmarks())
	}

	// -----------------------------------------------------------------------
	// MARK: - Top-level structure
	// -----------------------------------------------------------------------

	func testTopLevelDictionaryContainsPointsKey() {
		XCTAssertNotNil(buildStandardDict()["points"])
	}

	func testTopLevelDictionaryContainsTrianglesKey() {
		XCTAssertNotNil(buildStandardDict()["triangles"])
	}

	func testTopLevelDictionaryContainsContoursKey() {
		XCTAssertNotNil(buildStandardDict()["contours"])
	}

	func testTopLevelDictionaryHasExactlyThreeKeys() {
		XCTAssertEqual(buildStandardDict().count, 3)
	}

	// -----------------------------------------------------------------------
	// MARK: - "points" array
	// -----------------------------------------------------------------------

	func testPointsArrayHas468Entries() {
		let points = buildStandardDict()["points"] as? NSArray
		XCTAssertEqual(points?.count, 468)
	}

	func testEachPointIsAnArrayOfThree() throws {
		let points = try XCTUnwrap(buildStandardDict()["points"] as? NSArray)
		for i in 0 ..< points.count {
			let pt = points[i] as? NSArray
			XCTAssertEqual(pt?.count, 3, "Point \(i) should have 3 components")
		}
	}

	func testPointCoordinatesAreNSNumbers() throws {
		let points = try XCTUnwrap(buildStandardDict()["points"] as? NSArray)
		let first = try XCTUnwrap(points[0] as? NSArray)
		XCTAssertTrue(first[0] is NSNumber, "x should be NSNumber")
		XCTAssertTrue(first[1] is NSNumber, "y should be NSNumber")
		XCTAssertTrue(first[2] is NSNumber, "z should be NSNumber")
	}

	func testPointCoordinatesMatchInputLandmark() throws {
		let lm: [(x: Float, y: Float, z: Float)] = TestFixtures.indexedLandmarks
		let points = try XCTUnwrap(buildDict(landmarks: lm)["points"] as? NSArray)

		// Sample landmark at index 42
		let pt42 = try XCTUnwrap(points[42] as? NSArray)
		XCTAssertEqual((try XCTUnwrap(pt42[0] as? NSNumber)).floatValue, lm[42].x, accuracy: 1e-6)
		XCTAssertEqual((try XCTUnwrap(pt42[1] as? NSNumber)).floatValue, lm[42].y, accuracy: 1e-6)
		XCTAssertEqual((try XCTUnwrap(pt42[2] as? NSNumber)).floatValue, lm[42].z, accuracy: 1e-6)
	}

	func testPointAtIndexZeroMatchesFirstLandmark() throws {
		let lm = TestFixtures.indexedLandmarks
		let points = try XCTUnwrap(buildDict(landmarks: lm)["points"] as? NSArray)
		let pt0 = try XCTUnwrap(points[0] as? NSArray)
		XCTAssertEqual((try XCTUnwrap(pt0[0] as? NSNumber)).floatValue, lm[0].x, accuracy: 1e-6)
	}

	func testPointAtIndexLastMatchesFinalLandmark() throws {
		let lm = TestFixtures.indexedLandmarks
		let points = try XCTUnwrap(buildDict(landmarks: lm)["points"] as? NSArray)
		let ptLast = try XCTUnwrap(points[467] as? NSArray)
		XCTAssertEqual((try XCTUnwrap(ptLast[0] as? NSNumber)).floatValue, lm[467].x, accuracy: 1e-6)
	}

	func testUniformLandmarksAllReturnSameCoordinates() throws {
		let x: Float = 0.25, y: Float = 0.75, z: Float = -0.1
		let lm = TestFixtures.uniformLandmarks(x: x, y: y, z: z)
		let points = try XCTUnwrap(buildDict(landmarks: lm)["points"] as? NSArray)
		for i in 0 ..< points.count {
			let pt = try XCTUnwrap(points[i] as? NSArray)
			XCTAssertEqual((try XCTUnwrap(pt[0] as? NSNumber)).floatValue, x, accuracy: 1e-6)
			XCTAssertEqual((try XCTUnwrap(pt[1] as? NSNumber)).floatValue, y, accuracy: 1e-6)
			XCTAssertEqual((try XCTUnwrap(pt[2] as? NSNumber)).floatValue, z, accuracy: 1e-6)
		}
	}

	// -----------------------------------------------------------------------
	// MARK: - "triangles" array
	// -----------------------------------------------------------------------

	func testTrianglesArrayCountMatches852() {
		let triangles = buildStandardDict()["triangles"] as? NSArray
		XCTAssertEqual(triangles?.count, 852)
	}

	func testEachTriangleHasThreeElements() throws {
		let triangles = try XCTUnwrap(buildStandardDict()["triangles"] as? NSArray)
		for i in 0 ..< triangles.count {
			let tri = try XCTUnwrap(triangles[i] as? NSArray)
			XCTAssertEqual(tri.count, 3, "Triangle \(i) should have 3 vertices")
		}
	}

	func testTriangleVerticesAreNSNumbers() throws {
		let triangles = try XCTUnwrap(buildStandardDict()["triangles"] as? NSArray)
		let first = try XCTUnwrap(triangles[0] as? NSArray)
		XCTAssertTrue(first[0] is NSNumber)
		XCTAssertTrue(first[1] is NSNumber)
		XCTAssertTrue(first[2] is NSNumber)
	}

	func testFirstTriangleMatchesFaceMeshConstants() throws {
		let triangles = try XCTUnwrap(buildStandardDict()["triangles"] as? NSArray)
		let first = try XCTUnwrap(triangles[0] as? NSArray)
		let expected = FaceMeshConstants.triangles[0]
		XCTAssertEqual((try XCTUnwrap(first[0] as? NSNumber)).intValue, expected[0])
		XCTAssertEqual((try XCTUnwrap(first[1] as? NSNumber)).intValue, expected[1])
		XCTAssertEqual((try XCTUnwrap(first[2] as? NSNumber)).intValue, expected[2])
	}

	// -----------------------------------------------------------------------
	// MARK: - "contours" dictionary
	// -----------------------------------------------------------------------

	func testContoursIsNSDictionary() {
		XCTAssertTrue(buildStandardDict()["contours"] is NSDictionary)
	}

	func testContoursHas12Keys() throws {
		let contours = try XCTUnwrap(buildStandardDict()["contours"] as? NSDictionary)
		XCTAssertEqual(contours.count, 12)
	}

	func testContoursContainAllExpectedKeys() throws {
		let contours = try XCTUnwrap(buildStandardDict()["contours"] as? NSDictionary)
		for key in FaceMeshConstants.contourKeys {
			XCTAssertNotNil(contours[key], "Missing contour key: \(key)")
		}
	}

	func testEachContourValueIsNSArray() throws {
		let contours = try XCTUnwrap(buildStandardDict()["contours"] as? NSDictionary)
		for key in FaceMeshConstants.contourKeys {
			XCTAssertTrue(contours[key] is NSArray, "Contour '\(key)' should be NSArray")
		}
	}

	func testContourPointCountsMatchConstantIndexCounts() throws {
		let contours = try XCTUnwrap(buildStandardDict()["contours"] as? NSDictionary)
		for (key, indices) in zip(FaceMeshConstants.contourKeys,
								FaceMeshConstants.contourIndices) {
			let arr = try XCTUnwrap(contours[key] as? NSArray)
			XCTAssertEqual(arr.count, indices.count,
						"Contour '\(key)' point count mismatch")
		}
	}

	func testEachContourPointHasThreeComponents() throws {
		let contours = try XCTUnwrap(buildStandardDict()["contours"] as? NSDictionary)
		for key in FaceMeshConstants.contourKeys {
			let arr = try XCTUnwrap(contours[key] as? NSArray)
			for i in 0 ..< arr.count {
				let pt = try XCTUnwrap(arr[i] as? NSArray)
				XCTAssertEqual(pt.count, 3,
							"Contour '\(key)' point \(i) should have 3 components")
			}
		}
	}

	func testFaceOvalContourCoordinatesMatchLandmarks() throws {
		let lm = TestFixtures.indexedLandmarks
		let contours = try XCTUnwrap(buildDict(landmarks: lm)["contours"] as? NSDictionary)
		let faceOvalArr = try XCTUnwrap(contours["face_oval"] as? NSArray)

		guard let ovalIdx = FaceMeshConstants.contourKeys.firstIndex(of: "face_oval") else {
			return XCTFail("face_oval not found")
		}
		let indices = FaceMeshConstants.contourIndices[ovalIdx]

		for (arrayPos, landmarkIdx) in indices.enumerated() {
			let pt = try XCTUnwrap(faceOvalArr[arrayPos] as? NSArray)
			XCTAssertEqual((try XCTUnwrap(pt[0] as? NSNumber)).floatValue, lm[landmarkIdx].x, accuracy: 1e-6)
			XCTAssertEqual((try XCTUnwrap(pt[1] as? NSNumber)).floatValue, lm[landmarkIdx].y, accuracy: 1e-6)
		}
	}

	// -----------------------------------------------------------------------
	// MARK: - Short landmark list edge-case
	// -----------------------------------------------------------------------

	/// When the landmark list is shorter than the maximum contour index (467),
	/// buildContoursDict() must silently skip out-of-range indices via compactMap.
	/// The returned contour arrays will be shorter but must not crash.
	func testShortLandmarkListDoesNotCrash() {
		// 10 landmarks; most contour indices are ≥ 10 and will be skipped.
		let dict = buildDict(landmarks: TestFixtures.shortLandmarks)
		XCTAssertNotNil(dict)
	}

	func testShortLandmarkListContourArrayIsShorterThanNormal() throws {
		let shortDict    = buildDict(landmarks: TestFixtures.shortLandmarks)
		let standardDict = buildStandardDict()

		let shortContours    = try XCTUnwrap(shortDict["contours"] as? NSDictionary)
		let standardContours = try XCTUnwrap(standardDict["contours"] as? NSDictionary)

		// At least one contour in the short case must have fewer points.
		var foundDifference = false
		for key in FaceMeshConstants.contourKeys {
			let shortCount    = (try XCTUnwrap(shortContours[key] as? NSArray)).count
			let standardCount = (try XCTUnwrap(standardContours[key] as? NSArray)).count
			if shortCount < standardCount {
				foundDifference = true
				break
			}
		}
		XCTAssertTrue(foundDifference,
					"Short landmark list should produce at least one smaller contour array")
	}

	func testShortLandmarkListPointsArrayReflectsActualCount() throws {
		let count = TestFixtures.shortLandmarks.count   // 10
		let dict  = buildDict(landmarks: TestFixtures.shortLandmarks)
		let points = try XCTUnwrap(dict["points"] as? NSArray)
		XCTAssertEqual(points.count, count)
	}
}

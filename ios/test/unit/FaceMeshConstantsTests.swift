//
// © 2026-present https://github.com/cengiz-pz
//
// FaceMeshConstantsTests.swift
//
// Validates the static data in FaceMeshConstants.  These tests catch any
// accidental editing of the constant arrays that would break the mesh.
// They also enforce the cross-platform parity contract (key names and counts
// must match the Android plugin).
//

@testable import vision_plugin
import XCTest

final class FaceMeshConstantsTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: - contourKeys
	// -----------------------------------------------------------------------

	func testContourKeyCountIsExpected() {
		XCTAssertEqual(FaceMeshConstants.contourKeys.count, 12)
	}

	func testContourKeysContainFaceOval() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("face_oval"))
	}

	func testContourKeysContainLeftEye() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("left_eye"))
	}

	func testContourKeysContainRightEye() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("right_eye"))
	}

	func testContourKeysContainLeftEyebrowBottom() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("left_eyebrow_bottom"))
	}

	func testContourKeysContainLeftEyebrowTop() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("left_eyebrow_top"))
	}

	func testContourKeysContainRightEyebrowBottom() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("right_eyebrow_bottom"))
	}

	func testContourKeysContainRightEyebrowTop() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("right_eyebrow_top"))
	}

	func testContourKeysContainLowerLipBottom() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("lower_lip_bottom"))
	}

	func testContourKeysContainLowerLipTop() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("lower_lip_top"))
	}

	func testContourKeysContainUpperLipBottom() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("upper_lip_bottom"))
	}

	func testContourKeysContainUpperLipTop() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("upper_lip_top"))
	}

	func testContourKeysContainNoseBridge() {
		XCTAssertTrue(FaceMeshConstants.contourKeys.contains("nose_bridge"))
	}

	func testContourKeysAreUnique() {
		let keys = FaceMeshConstants.contourKeys
		XCTAssertEqual(keys.count, Set(keys).count, "Contour keys must be unique")
	}

	func testContourKeysContainNoEmptyStrings() {
		XCTAssertFalse(FaceMeshConstants.contourKeys.contains(""))
	}

	// -----------------------------------------------------------------------
	// MARK: - contourIndices – parallel-array contract
	// -----------------------------------------------------------------------

	func testContourIndicesCountMatchesKeyCount() {
		XCTAssertEqual(
			FaceMeshConstants.contourIndices.count,
			FaceMeshConstants.contourKeys.count,
			"contourIndices must be parallel to contourKeys"
		)
	}

	func testAllContourIndicesAreInLandmarkRange() {
		let maxIdx = 467 // 0 …< 468
		for (key, indices) in zip(FaceMeshConstants.contourKeys,
				FaceMeshConstants.contourIndices) {
			for idx in indices {
				XCTAssertGreaterThanOrEqual(
					idx, 0,
					"Contour '\(key)' contains negative index \(idx)")
				XCTAssertLessThanOrEqual(
					idx, maxIdx,
					"Contour '\(key)' contains out-of-range index \(idx)")
			}
		}
	}

	func testEachContourHasAtLeastOneIndex() {
		for (key, indices) in zip(FaceMeshConstants.contourKeys,
				FaceMeshConstants.contourIndices) {
			XCTAssertFalse(indices.isEmpty, "Contour '\(key)' must not be empty")
		}
	}

	func testNoseBridgeHasFivePoints() {
		// nose_bridge = [168, 6, 197, 195, 5] – verify explicitly
		guard let idx = FaceMeshConstants.contourKeys.firstIndex(of: "nose_bridge") else {
			return XCTFail("nose_bridge contour not found")
		}
		XCTAssertEqual(FaceMeshConstants.contourIndices[idx].count, 5)
	}

	func testFaceOvalHas36Points() {
		guard let idx = FaceMeshConstants.contourKeys.firstIndex(of: "face_oval") else {
			return XCTFail("face_oval contour not found")
		}
		XCTAssertEqual(FaceMeshConstants.contourIndices[idx].count, 36)
	}

	func testLeftEyeHas16Points() {
		guard let idx = FaceMeshConstants.contourKeys.firstIndex(of: "left_eye") else {
			return XCTFail("left_eye contour not found")
		}
		XCTAssertEqual(FaceMeshConstants.contourIndices[idx].count, 16)
	}

	func testRightEyeHas16Points() {
		guard let idx = FaceMeshConstants.contourKeys.firstIndex(of: "right_eye") else {
			return XCTFail("right_eye contour not found")
		}
		XCTAssertEqual(FaceMeshConstants.contourIndices[idx].count, 16)
	}

	// -----------------------------------------------------------------------
	// MARK: - triangles – count and structure
	// -----------------------------------------------------------------------

	func testTriangleCountIs852() {
		XCTAssertEqual(FaceMeshConstants.triangles.count, 852)
	}

	func testEveryTriangleHasExactlyThreeVertices() {
		for (i, tri) in FaceMeshConstants.triangles.enumerated() {
			XCTAssertEqual(tri.count, 3, "Triangle \(i) has \(tri.count) vertices instead of 3")
		}
	}

	func testAllTriangleIndicesAreInLandmarkRange() {
		let maxIdx = 467
		for (i, tri) in FaceMeshConstants.triangles.enumerated() {
			for v in tri {
				XCTAssertGreaterThanOrEqual(v, 0, "Triangle \(i) has negative vertex \(v)")
				XCTAssertLessThanOrEqual(v, maxIdx, "Triangle \(i) has out-of-range vertex \(v)")
			}
		}
	}

	func testNoTriangleHasRepeatedVertices() {
		for (i, tri) in FaceMeshConstants.triangles.enumerated() {
			XCTAssertNotEqual(tri[0], tri[1], "Triangle \(i): vertex 0 == vertex 1")
			XCTAssertNotEqual(tri[1], tri[2], "Triangle \(i): vertex 1 == vertex 2")
			XCTAssertNotEqual(tri[0], tri[2], "Triangle \(i): vertex 0 == vertex 2")
		}
	}

	/// Spot-check the first triangle from the source: [127, 34, 139].
	func testFirstTriangleMatchesExpected() {
		let first = FaceMeshConstants.triangles[0]
		XCTAssertEqual(first, [127, 34, 139])
	}

	/// Spot-check the last triangle: [339, 448, 255].
	func testLastTriangleMatchesExpected() {
		let last = FaceMeshConstants.triangles.last
		XCTAssertEqual(last, [339, 448, 255])
	}
}

//
// © 2026-present https://github.com/cengiz-pz
//
// FaceScanResultTests.swift
//
// Validates FaceScanResult.buildNSDictionary(), which is the top-level
// dictionary emitted by the face_mesh_ready signal.
//

@testable import vision_plugin
import XCTest

final class FaceScanResultTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: - Helpers
	// -----------------------------------------------------------------------

	/// Builds a minimal imageInfo NSDictionary that mirrors the layout
	/// produced by vision_plugin.mm before it is handed to the Swift bridge.
	/// An empty NSData buffer is sufficient for structural tests; no actual
	/// pixel data is needed since FaceScanResult only stores and re-emits the
	/// dictionary without inspecting the buffer contents.
	private func makeImageInfo(width: Int = 640, height: Int = 480) -> NSDictionary {
		[
			"buffer": NSData(),
			"width": NSNumber(value: width),
			"height": NSNumber(value: height),
			"format": NSNumber(value: 4),   // Image.FORMAT_RGBA8
			"has_mipmaps": NSNumber(value: 0)
		]
	}

	private func buildResult(
		faces: [FaceLandmarkerService.DetectedFace] = [],
		width: Int = 640, height: Int = 480
	) -> NSDictionary {
		FaceScanResult(faces: faces, imageInfo: makeImageInfo(width: width, height: height))
			.buildNSDictionary()
	}

	/// Returns the "image" sub-dictionary from a result, failing the test if
	/// it is absent or has the wrong type.
	private func imageInfo(from dict: NSDictionary, file: StaticString = #file,
			line: UInt = #line) throws -> NSDictionary {
		try XCTUnwrap(dict["image"] as? NSDictionary,
					"result must contain an 'image' NSDictionary",
					file: file, line: line)
	}

	// -----------------------------------------------------------------------
	// MARK: - Top-level structure
	// -----------------------------------------------------------------------

	func testTopLevelDictionaryContainsImageKey() {
		XCTAssertNotNil(buildResult()["image"])
	}

	func testTopLevelDictionaryContainsFacesKey() {
		XCTAssertNotNil(buildResult()["faces"])
	}

	func testTopLevelDictionaryHasExactlyTwoKeys() {
		// Only "image" and "faces" — image_width / image_height have been
		// folded into the "image" sub-dictionary.
		XCTAssertEqual(buildResult().count, 2)
	}

	// -----------------------------------------------------------------------
	// MARK: - Image sub-dictionary structure
	// -----------------------------------------------------------------------

	func testImageValueIsNSDictionary() {
		XCTAssertTrue(buildResult()["image"] is NSDictionary)
	}

	func testImageDictionaryContainsBufferKey() throws {
		XCTAssertNotNil(try imageInfo(from: buildResult())["buffer"])
	}

	func testImageDictionaryContainsWidthKey() throws {
		XCTAssertNotNil(try imageInfo(from: buildResult())["width"])
	}

	func testImageDictionaryContainsHeightKey() throws {
		XCTAssertNotNil(try imageInfo(from: buildResult())["height"])
	}

	func testImageDictionaryContainsFormatKey() throws {
		XCTAssertNotNil(try imageInfo(from: buildResult())["format"])
	}

	func testImageDictionaryContainsHasMipmapsKey() throws {
		XCTAssertNotNil(try imageInfo(from: buildResult())["has_mipmaps"])
	}

	// -----------------------------------------------------------------------
	// MARK: - Image dimensions
	// -----------------------------------------------------------------------

	func testImageWidthValueIsPreserved() throws {
		let info = try imageInfo(from: buildResult(width: 1280, height: 720))
		XCTAssertEqual((info["width"] as? NSNumber)?.intValue, 1280)
	}

	func testImageHeightValueIsPreserved() throws {
		let info = try imageInfo(from: buildResult(width: 1280, height: 720))
		XCTAssertEqual((info["height"] as? NSNumber)?.intValue, 720)
	}

	func testImageWidthIsNSNumber() throws {
		XCTAssertTrue(try imageInfo(from: buildResult())["width"] is NSNumber)
	}

	func testImageHeightIsNSNumber() throws {
		XCTAssertTrue(try imageInfo(from: buildResult())["height"] is NSNumber)
	}

	func testZeroDimensionsAreStoredWithoutModification() throws {
		// Unusual but must not crash or alter the value.
		let info = try imageInfo(from: buildResult(width: 0, height: 0))
		XCTAssertEqual((info["width"]  as? NSNumber)?.intValue, 0)
		XCTAssertEqual((info["height"] as? NSNumber)?.intValue, 0)
	}

	func testLargeDimensionsAreStoredCorrectly() throws {
		let info = try imageInfo(from: buildResult(width: 4096, height: 3072))
		XCTAssertEqual((info["width"]  as? NSNumber)?.intValue, 4096)
		XCTAssertEqual((info["height"] as? NSNumber)?.intValue, 3072)
	}

	func testFormatValueIsPreserved() throws {
		// Vision.gd always passes FORMAT_RGBA8 (== 4).
		let info = try imageInfo(from: buildResult())
		XCTAssertEqual((info["format"] as? NSNumber)?.intValue, 4)
	}

	func testHasMipmapsValueIsPreserved() throws {
		// Vision.gd converts to FORMAT_RGBA8 (no mipmaps) before calling the plugin.
		let info = try imageInfo(from: buildResult())
		XCTAssertEqual((info["has_mipmaps"] as? NSNumber)?.intValue, 0)
	}

	// -----------------------------------------------------------------------
	// MARK: - Faces array - count
	// -----------------------------------------------------------------------

	func testFacesArrayIsNSArray() {
		XCTAssertTrue(buildResult()["faces"] is NSArray)
	}

	func testFacesArrayIsEmptyWhenNoFacesProvided() throws {
		let faces = try XCTUnwrap(buildResult()["faces"] as? NSArray)
		XCTAssertEqual(faces.count, 0)
	}

	func testFacesArrayHasOneFaceWhenOneFaceProvided() throws {
		let dict = buildResult(faces: [TestFixtures.makeDetectedFace()])
		let faces = try XCTUnwrap(dict["faces"] as? NSArray)
		XCTAssertEqual(faces.count, 1)
	}

	func testFacesArrayHasTwoFacesWhenTwoFacesProvided() throws {
		let dict = buildResult(faces: TestFixtures.twoDetectedFaces)
		let faces = try XCTUnwrap(dict["faces"] as? NSArray)
		XCTAssertEqual(faces.count, 2)
	}

	func testFacesArrayCountMatchesInputCount() throws {
		for count in [0, 1, 3, 5] {
			let detected = (0..<count).map { _ in TestFixtures.makeDetectedFace() }
			let faces = try XCTUnwrap(buildResult(faces: detected)["faces"] as? NSArray)
			XCTAssertEqual(faces.count, count, "count=\(count)")
		}
	}

	// -----------------------------------------------------------------------
	// MARK: - Per-face structure
	// -----------------------------------------------------------------------

	func testEachFaceIsNSDictionary() throws {
		let dict = buildResult(faces: TestFixtures.twoDetectedFaces)
		let faces = try XCTUnwrap(dict["faces"] as? NSArray)
		for i in 0 ..< faces.count {
			XCTAssertTrue(faces[i] is NSDictionary, "Face \(i) should be NSDictionary")
		}
	}

	private func getFirstFace(from dict: NSDictionary) throws -> [String: Any] {
		// 1. Safely cast the "faces" key to a Swift array
		let faces = try XCTUnwrap(dict["faces"] as? [[String: Any]], "Faces array missing or wrong type")

		// 2. Safely get the first element
		let face = try XCTUnwrap(faces.first, "Faces array is empty")

		return face
	}

	func testEachFaceContainsPointsKey() throws {
		let dict = buildResult(faces: [TestFixtures.makeDetectedFace()])
		let face = try getFirstFace(from: dict)
		XCTAssertNotNil(face["points"])
	}

	func testEachFaceContainsTrianglesKey() throws {
		let dict = buildResult(faces: [TestFixtures.makeDetectedFace()])
		let face = try getFirstFace(from: dict)
		XCTAssertNotNil(face["triangles"])
	}

	func testEachFaceContainsContoursKey() throws {
		let dict = buildResult(faces: [TestFixtures.makeDetectedFace()])
		let face = try getFirstFace(from: dict)
		XCTAssertNotNil(face["contours"])
	}

	func testFacePointsHas468Entries() throws {
		let dict  = buildResult(faces: [TestFixtures.makeDetectedFace()])
		let face  = try getFirstFace(from: dict)
		let points = try XCTUnwrap(face["points"] as? NSArray)
		XCTAssertEqual(points.count, 468)
	}

	func testSecondFaceHasItsOwnLandmarkValues() throws {
		let face1 = TestFixtures.makeDetectedFace(landmarks: TestFixtures.uniformLandmarks(x: 0.0, y: 0.0, z: 0.0))
		let face2 = TestFixtures.makeDetectedFace(landmarks: TestFixtures.uniformLandmarks(x: 1.0, y: 1.0, z: 1.0))

		let dict   = buildResult(faces: [face1, face2])
		let faces  = try XCTUnwrap(dict["faces"] as? NSArray)

		let face0     = try XCTUnwrap(faces[0] as? NSDictionary)
		let face1Dict = try XCTUnwrap(faces[1] as? NSDictionary)

		let pts1 = try XCTUnwrap(face0["points"]     as? NSArray)
		let pts2 = try XCTUnwrap(face1Dict["points"] as? NSArray)

		let pt1 = try XCTUnwrap(pts1[0] as? NSArray)
		let pt2 = try XCTUnwrap(pts2[0] as? NSArray)

		let x1 = try XCTUnwrap(pt1[0] as? NSNumber).floatValue
		let x2 = try XCTUnwrap(pt2[0] as? NSNumber).floatValue

		XCTAssertNotEqual(x1, x2, "Two faces with different landmarks must have different x values")
	}

	// -----------------------------------------------------------------------
	// MARK: - Immutability / repeatability
	// -----------------------------------------------------------------------

	func testCallingBuildNSDictionaryTwiceGivesSameResult() {
		let result = FaceScanResult(
			faces: [TestFixtures.makeDetectedFace()],
			imageInfo: makeImageInfo(width: 640, height: 480))
		let d1 = result.buildNSDictionary()
		let d2 = result.buildNSDictionary()
		XCTAssertEqual(d1, d2)
	}
}

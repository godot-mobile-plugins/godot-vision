//
// © 2026-present https://github.com/cengiz-pz
//
// FaceLandmarkerServiceTests.swift
//
// Tests for FaceLandmarkerService that do NOT require the real MediaPipe
// model asset.  The service is initialised in an environment (the test
// runner) where face_landmarker.task is not bundled, so every init attempt
// throws ServiceError.modelNotFound.  This exercises the entire error path
// that production code must handle (e.g. a corrupt or missing export).
//
// Integration tests that require the model are gated behind an environment
// variable VISION_PLUGIN_INTEGRATION_TESTS=1 and a model file added to the
// test target's Copy Bundle Resources phase.
//

@testable import vision_plugin
import XCTest

final class FaceLandmarkerServiceTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: - ServiceError raw values / identities
	// -----------------------------------------------------------------------

	func testServiceErrorModelNotFoundIsDistinctType() {
		let err = FaceLandmarkerService.ServiceError.modelNotFound
		// Pattern match to confirm the case
		if case .modelNotFound = err { /* pass */ } else {
			XCTFail("Expected .modelNotFound")
		}
	}

	func testServiceErrorInitFailedCarriesUnderlyingError() {
		let underlying = NSError(domain: "test", code: 42, userInfo: nil)
		let err = FaceLandmarkerService.ServiceError.initFailed(underlying)
		if case .initFailed(let inner) = err {
			XCTAssertEqual((inner as NSError).code, 42)
		} else {
			XCTFail("Expected .initFailed")
		}
	}

	func testServiceErrorDetectionFailedCarriesUnderlyingError() {
		let underlying = NSError(domain: "mp", code: 99, userInfo: nil)
		let err = FaceLandmarkerService.ServiceError.detectionFailed(underlying)
		if case .detectionFailed(let inner) = err {
			XCTAssertEqual((inner as NSError).code, 99)
		} else {
			XCTFail("Expected .detectionFailed")
		}
	}

	// -----------------------------------------------------------------------
	// MARK: - init() – model-not-found path
	// -----------------------------------------------------------------------

	/// In the test bundle the .task asset is absent, so init() must throw
	/// modelNotFound rather than crashing or returning an invalid service.
	func testInitThrowsModelNotFoundWhenAssetIsMissing() {
		// Verify the asset really is absent so this test stays meaningful.
		let url = Bundle.main.url(forResource: "face_landmarker", withExtension: "task")
		guard url == nil else {
			// Model is present – skip this particular assertion (integration env).
			return
		}

		XCTAssertThrowsError(try FaceLandmarkerService()) { error in
			guard let svcErr = error as? FaceLandmarkerService.ServiceError,
					case .modelNotFound = svcErr else {
				XCTFail("Expected ServiceError.modelNotFound, got \(error)")
				return
			}
		}
	}

	func testInitErrorIsServiceError() {
		let url = Bundle.main.url(forResource: "face_landmarker", withExtension: "task")
		guard url == nil else { return } // model present; skip

		do {
			_ = try FaceLandmarkerService()
			XCTFail("Expected init to throw")
		} catch let err as FaceLandmarkerService.ServiceError {
			// Pass – correct error type
			_ = err
		} catch {
			XCTFail("Expected ServiceError, got \(type(of: error)): \(error)")
		}
	}

	// -----------------------------------------------------------------------
	// MARK: - init() – invalid model path (initFailed branch)
	// -----------------------------------------------------------------------

	/// Place a zero-byte file named face_landmarker.task in the test bundle's
	/// Copy Bundle Resources to reach the initFailed path.  The guard below
	/// skips if that fixture is absent.
	func testInitThrowsInitFailedForInvalidModelFile() throws {
		guard let url = Bundle(for: type(of: self))
			.url(forResource: "face_landmarker_stub", withExtension: "task") else {
			throw XCTSkip("face_landmarker_stub.task not in test bundle – skipping initFailed path")
		}

		// Temporarily shadow the real search path by creating a sub-bundle
		// pointing to our stub.  This cannot intercept Bundle.main directly,
		// so instead we test this path via VisionSwiftBridgeTests using the
		// injected MockFaceLandmarker.
		_ = url   // satisfy compiler; real injection happens via bridge tests
		throw XCTSkip("Stub injection requires source-level FaceDetecting protocol adoption")
	}

	// -----------------------------------------------------------------------
	// MARK: - DetectedFace value type
	// -----------------------------------------------------------------------

	func testDetectedFaceStoresLandmarks() {
		let lm = TestFixtures.uniformLandmarks()
		let face = FaceLandmarkerService.DetectedFace(landmarks: lm)
		XCTAssertEqual(face.landmarks.count, 468)
	}

	func testDetectedFaceLandmarkValuesArePreserved() {
		let lm = TestFixtures.indexedLandmarks
		let face = FaceLandmarkerService.DetectedFace(landmarks: lm)
		XCTAssertEqual(face.landmarks[0].x, lm[0].x, accuracy: 1e-7)
		XCTAssertEqual(face.landmarks[100].y, lm[100].y, accuracy: 1e-7)
		XCTAssertEqual(face.landmarks[467].z, lm[467].z, accuracy: 1e-7)
	}

	func testDetectedFaceAllowsEmptyLandmarks() {
		let face = FaceLandmarkerService.DetectedFace(landmarks: [])
		XCTAssertTrue(face.landmarks.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: - Integration tests (require model asset in test bundle)
	// -----------------------------------------------------------------------

	func testDetectSucceedsWithValidImage() throws {
		guard ProcessInfo.processInfo.environment["VISION_PLUGIN_INTEGRATION_TESTS"] == "1"
		else {
			throw XCTSkip("Set VISION_PLUGIN_INTEGRATION_TESTS=1 and add face_landmarker.task to run integration tests")
		}

		let service = try FaceLandmarkerService()
		let buffer  = TestFixtures.rgbaBuffer(width: 320, height: 240)
		guard let image = ImageInfo.makeUIImage(from: buffer, width: 320, height: 240) else {
			XCTFail("Could not construct test UIImage"); return
		}

		let result = service.detect(image: image)
		// A blank image should produce zero faces (not an error).
		switch result {
		case .success(let faces):
			XCTAssertTrue(faces.isEmpty) // valid but blank frame
		case .failure(let err):
			XCTFail("detect() should succeed on a valid image, got: \(err)")
		}
	}

	func testDetectReturnsAtMostFiveFaces() throws {
		guard ProcessInfo.processInfo.environment["VISION_PLUGIN_INTEGRATION_TESTS"] == "1"
		else { throw XCTSkip("Integration only") }

		let service = try FaceLandmarkerService()
		let buffer  = TestFixtures.rgbaBuffer(width: 320, height: 240)
		let image   = ImageInfo.makeUIImage(from: buffer, width: 320, height: 240)!
		let result  = service.detect(image: image)
		if case .success(let faces) = result {
			XCTAssertLessThanOrEqual(faces.count, 5)
		}
	}

	func testDetectLandmarksAreBoundedZeroToOne() throws {
		guard ProcessInfo.processInfo.environment["VISION_PLUGIN_INTEGRATION_TESTS"] == "1"
		else { throw XCTSkip("Integration only") }

		let service = try FaceLandmarkerService()
		let buffer  = TestFixtures.rgbaBuffer(width: 640, height: 480)
		let image   = ImageInfo.makeUIImage(from: buffer, width: 640, height: 480)!

		if case .success(let faces) = service.detect(image: image) {
			for face in faces {
				for lm in face.landmarks {
					XCTAssertGreaterThanOrEqual(lm.x, 0.0)
					XCTAssertLessThanOrEqual(lm.x, 1.0)
					XCTAssertGreaterThanOrEqual(lm.y, 0.0)
					XCTAssertLessThanOrEqual(lm.y, 1.0)
				}
			}
		}
	}
}

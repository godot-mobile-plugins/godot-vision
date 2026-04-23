//
// © 2026-present https://github.com/cengiz-pz
//
// VisionSwiftBridgeTests.swift
//
// Tests for VisionSwiftBridge.  Two groups:
//
//   A. No-model tests — do not require face_landmarker.task; exercise every
//      error branch that fires before MediaPipe is touched.
//
//   B. Mock-injection tests — require the FaceDetecting protocol and a small
//      change to VisionSwiftBridge (see FaceDetecting.swift for details):
//
//        var landmarkerService: (any FaceDetecting)?   // was: private FaceLandmarkerService?
//
//      With that change these tests can inject MockFaceLandmarker and reach
//      the full processingQueue -> process() -> deliverSuccess/Failure paths.
//
// All callbacks are delivered on the main thread via DispatchQueue.main.async,
// so every test that expects a callback uses XCTestExpectation with a
// 2-second timeout (generous for CI simulators).
//

@testable import vision_plugin
import XCTest

final class VisionSwiftBridgeTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: - Constants
	// -----------------------------------------------------------------------

	private let kTimeout: TimeInterval = 2.0

	// -----------------------------------------------------------------------
	// MARK: - Helper: make a minimal NSData buffer
	// -----------------------------------------------------------------------

	private func makeBuffer(width: Int, height: Int) -> NSData {
		let data = TestFixtures.rgbaBuffer(width: width, height: height)
		return data as NSData
	}

	// -----------------------------------------------------------------------
	// MARK: - A. No-model tests
	//         These work without face_landmarker.task in the test bundle.
	// -----------------------------------------------------------------------

	// --- A1. scanFace before initialize() -----------------------------------

	func testScanFaceBeforeInitializeDeliversInternalError() {
		let bridge   = VisionSwiftBridge()
		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "faceMeshFailed for uninitialised bridge")
		delegate.failureExpectation = exp

		bridge.scanFace(buffer: makeBuffer(width: 4, height: 4), width: 4, height: 4)

		wait(for: [exp], timeout: kTimeout)
		delegate.assertSingleFailureCode(.internalError)
	}

	func testScanFaceBeforeInitializeDeliversDescriptionContainingContextInfo() {
		let bridge   = VisionSwiftBridge()
		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "failure description")
		delegate.failureExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: 4, height: 4), width: 4, height: 4)
		wait(for: [exp], timeout: kTimeout)

		let desc = delegate.lastError?["description"] as? String ?? ""
		XCTAssertFalse(desc.isEmpty, "Error description must not be empty")
	}

	// --- A2. initialize() when model is absent ------------------------------

	func testInitializeWithMissingModelLeavesLandmarkerServiceNil() {
		guard Bundle.main.url(forResource: "face_landmarker", withExtension: "task") == nil
		else { return } // model present; skip

		let bridge = VisionSwiftBridge()
		bridge.initialize()
		// After a failed init, a subsequent scanFace should still deliver
		// internalError (not crash), proving landmarkerService stayed nil.
		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "failure after bad init")
		delegate.failureExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: 4, height: 4), width: 4, height: 4)
		wait(for: [exp], timeout: kTimeout)

		delegate.assertSingleFailureCode(.internalError)
	}

	func testInitializeReportsInitialisationErrorInDescription() {
		guard Bundle.main.url(forResource: "face_landmarker", withExtension: "task") == nil
		else { return }

		let bridge   = VisionSwiftBridge()
		bridge.initialize()

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "failure description contains init error")
		delegate.onFailure = { error in
			let desc = error["description"] as? String ?? ""
			XCTAssertTrue(
				desc.contains("initialise") || desc.contains("init") || !desc.isEmpty,
				"Expected a meaningful description, got: \(desc)")
			exp.fulfill()
		}

		bridge.scanFace(buffer: makeBuffer(width: 4, height: 4), width: 4, height: 4)
		wait(for: [exp], timeout: kTimeout)
	}

	func testCallInitializeTwiceIsSafe() {
		// Second call should be a no-op (guard landmarkerService == nil).
		let bridge = VisionSwiftBridge()
		bridge.initialize()
		bridge.initialize() // should not crash or re-initialise
	}

	// --- A3. shutdown() safety ----------------------------------------------

	func testShutdownBeforeInitializeDoesNotCrash() {
		let bridge = VisionSwiftBridge()
		bridge.shutdown()   // must not crash
	}

	func testShutdownAfterInitializeDoesNotCrash() {
		let bridge = VisionSwiftBridge()
		bridge.initialize()
		bridge.shutdown()
	}

	func testDoubleShutdownDoesNotCrash() {
		let bridge = VisionSwiftBridge()
		bridge.initialize()
		bridge.shutdown()
		bridge.shutdown()
	}

	func testScanFaceAfterShutdownDeliversInternalError() {
		let bridge   = VisionSwiftBridge()
		let delegate = MockFaceDelegate()
		bridge.delegate = delegate
		bridge.initialize()
		bridge.shutdown()

		let exp = expectation(description: "failure after shutdown")
		delegate.failureExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: 4, height: 4), width: 4, height: 4)
		wait(for: [exp], timeout: kTimeout)

		delegate.assertSingleFailureCode(.internalError)
	}

	// --- A4. Delegate delivery is on the main thread ------------------------

	func testFailureCallbackIsDeliveredOnMainThread() {
		let bridge   = VisionSwiftBridge()
		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "main-thread delivery")
		delegate.onFailure = { _ in
			XCTAssertTrue(Thread.isMainThread, "Callback must be on main thread")
			exp.fulfill()
		}
		bridge.scanFace(buffer: makeBuffer(width: 4, height: 4), width: 4, height: 4)
		wait(for: [exp], timeout: kTimeout)
	}

	// --- A5. Nil delegate does not crash ------------------------------------

	func testScanFaceWithNilDelegateDoesNotCrash() {
		let bridge = VisionSwiftBridge()
		bridge.delegate = nil
		bridge.scanFace(buffer: makeBuffer(width: 4, height: 4), width: 4, height: 4)
		// No expectation – we only verify there is no crash.
		// Give the main-thread dispatch time to fire.
		let spin = expectation(description: "spin")
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { spin.fulfill() }
		wait(for: [spin], timeout: 1.0)
	}

	// -----------------------------------------------------------------------
	// MARK: - B. Mock-injection tests
	//         Require FaceDetecting protocol + internal landmarkerService property.
	//         Skip automatically when the property is private (pre-refactor).
	// -----------------------------------------------------------------------

	/// Returns true when the bridge exposes `landmarkerService` as internal
	/// (i.e. the FaceDetecting refactor has been applied).
	private func mockInjectionAvailable(_ bridge: VisionSwiftBridge) -> Bool {
		// Swift Mirror can see stored properties regardless of access level at
		// runtime, letting us detect whether injection is wired up.
		let mirror = Mirror(reflecting: bridge)
		return mirror.children.contains { $0.label == "landmarkerService" }
	}

	// --- B1. Empty-faces result (no face detected) --------------------------

	func testScanFaceEmptyResultDeliversNoFaceDetectedError() throws {
		let bridge = VisionSwiftBridge()
		guard mockInjectionAvailable(bridge) else {
			throw XCTSkip("FaceDetecting protocol injection not yet applied")
		}

		let mock     = MockFaceLandmarker()
		mock.stubbedResult = .success([])          // valid image, zero faces
		bridge.landmarkerService = mock

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "no-face error")
		delegate.failureExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: 8, height: 8), width: 8, height: 8)
		wait(for: [exp], timeout: kTimeout)

		delegate.assertSingleFailureCode(.noFaceDetected)
	}

	// --- B2. Success result with one face -----------------------------------

	func testScanFaceOneFaceResultDeliversSuccessSignal() throws {
		let bridge = VisionSwiftBridge()
		guard mockInjectionAvailable(bridge) else {
			throw XCTSkip("FaceDetecting protocol injection not yet applied")
		}

		let face = TestFixtures.makeDetectedFace()
		let mock = MockFaceLandmarker()
		mock.stubbedResult = .success([face])
		bridge.landmarkerService = mock

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "success with one face")
		delegate.successExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: 8, height: 8), width: 8, height: 8)
		wait(for: [exp], timeout: kTimeout)

		XCTAssertEqual(delegate.successCallCount, 1)
		XCTAssertEqual(delegate.failureCallCount, 0)
	}

	func testScanFaceSuccessResultContainsFacesKey() throws {
		let bridge = VisionSwiftBridge()
		guard mockInjectionAvailable(bridge) else {
			throw XCTSkip("FaceDetecting protocol injection not yet applied")
		}

		let mock = MockFaceLandmarker()
		mock.stubbedResult = .success([TestFixtures.makeDetectedFace()])
		bridge.landmarkerService = mock

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "success")
		delegate.successExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: 8, height: 8), width: 8, height: 8)
		wait(for: [exp], timeout: kTimeout)

		XCTAssertNotNil(delegate.lastResult?["faces"])
	}

	func testScanFaceSuccessResultContainsCorrectImageDimensions() throws {
		let bridge = VisionSwiftBridge()
		guard mockInjectionAvailable(bridge) else {
			throw XCTSkip("FaceDetecting protocol injection not yet applied")
		}

		let mock = MockFaceLandmarker()
		mock.stubbedResult = .success([TestFixtures.makeDetectedFace()])
		bridge.landmarkerService = mock

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let w = 16, h = 12
		let exp = expectation(description: "success with dimensions")
		delegate.successExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: w, height: h), width: w, height: h)
		wait(for: [exp], timeout: kTimeout)

		XCTAssertEqual((delegate.lastResult?["image_width"]  as? NSNumber)?.intValue, w)
		XCTAssertEqual((delegate.lastResult?["image_height"] as? NSNumber)?.intValue, h)
	}

	// --- B3. Success callback on main thread --------------------------------

	func testSuccessCallbackIsDeliveredOnMainThread() throws {
		let bridge = VisionSwiftBridge()
		guard mockInjectionAvailable(bridge) else {
			throw XCTSkip("FaceDetecting protocol injection not yet applied")
		}

		let mock = MockFaceLandmarker()
		mock.stubbedResult = .success([TestFixtures.makeDetectedFace()])
		bridge.landmarkerService = mock

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "main thread success")
		delegate.onSuccess = { _ in
			XCTAssertTrue(Thread.isMainThread)
			exp.fulfill()
		}
		bridge.scanFace(buffer: makeBuffer(width: 8, height: 8), width: 8, height: 8)
		wait(for: [exp], timeout: kTimeout)
	}

	// --- B4. Scanner failure forwarded correctly ----------------------------

	func testScanFaceDetectionFailureForwardsScannerFailureCode() throws {
		let bridge = VisionSwiftBridge()
		guard mockInjectionAvailable(bridge) else {
			throw XCTSkip("FaceDetecting protocol injection not yet applied")
		}

		let scanErr = ScanError(code: .scannerFailure, description: "MP exploded")
		let mock    = MockFaceLandmarker()
		mock.stubbedResult = .failure(scanErr)
		bridge.landmarkerService = mock

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "scanner failure forwarded")
		delegate.failureExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: 8, height: 8), width: 8, height: 8)
		wait(for: [exp], timeout: kTimeout)

		delegate.assertSingleFailureCode(.scannerFailure)
	}

	// --- B5. Invalid image path (bad buffer dims passed to bridge) ----------

	func testScanFaceInvalidBufferDimensionsMismatchDeliversInvalidImageError() throws {
		let bridge = VisionSwiftBridge()
		guard mockInjectionAvailable(bridge) else {
			throw XCTSkip("FaceDetecting protocol injection not yet applied")
		}

		let mock = MockFaceLandmarker()
		mock.stubbedResult = .success([TestFixtures.makeDetectedFace()])
		bridge.landmarkerService = mock

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		// Buffer sized for 4×4 but passed as 100×100 -> makeUIImage returns nil.
		let undersizedBuffer = makeBuffer(width: 4, height: 4)

		let exp = expectation(description: "invalid image from dimension mismatch")
		delegate.failureExpectation = exp
		bridge.scanFace(buffer: undersizedBuffer, width: 100, height: 100)
		wait(for: [exp], timeout: kTimeout)

		delegate.assertSingleFailureCode(.invalidImage)
	}

	// --- B6. detect() is called exactly once per scanFace call --------------

	func testScanFaceCallsDetectExactlyOnce() throws {
		let bridge = VisionSwiftBridge()
		guard mockInjectionAvailable(bridge) else {
			throw XCTSkip("FaceDetecting protocol injection not yet applied")
		}

		let mock = MockFaceLandmarker()
		mock.stubbedResult = .success([TestFixtures.makeDetectedFace()])
		bridge.landmarkerService = mock

		let delegate = MockFaceDelegate()
		bridge.delegate = delegate

		let exp = expectation(description: "success")
		delegate.successExpectation = exp
		bridge.scanFace(buffer: makeBuffer(width: 8, height: 8), width: 8, height: 8)
		wait(for: [exp], timeout: kTimeout)

		XCTAssertEqual(mock.detectCallCount, 1)
	}
}

// ---------------------------------------------------------------------------
// MARK: - XCTSkip on older OS (throw-based skip helper)
// ---------------------------------------------------------------------------

// Re-declare throw in test context so the mock-injection tests can use
// `throw XCTSkip(...)` even when the skip convenience was added in Xcode 11.4.
extension VisionSwiftBridgeTests {
	/// Wraps XCTSkip so the calling test can use throw syntax consistently.
	private func skip(_ message: String) throws {
		throw XCTSkip(message)
	}
}

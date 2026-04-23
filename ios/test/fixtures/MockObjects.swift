//
// © 2026-present https://github.com/cengiz-pz
//
// Test doubles used by VisionSwiftBridgeTests (and optionally other suites).
//
// MockFaceDelegate  – records every callback delivered by the bridge so tests
//                     can assert on them with XCTestExpectation.
//
// MockFaceLandmarker – implements FaceDetecting and lets each test configure
//                      the exact result that detect(image:) should return.
//                      Optionally records which UIImages were passed in.
//

import Foundation
import UIKit
@testable import vision_plugin
import XCTest

// ---------------------------------------------------------------------------
// MARK: - MockFaceDelegate
// ---------------------------------------------------------------------------

/// ObjC-compatible delegate that captures the most-recent success/failure
/// dictionaries and can signal an XCTestExpectation on each delivery.
final class MockFaceDelegate: NSObject, VisionSwiftBridgeDelegate {

	// Storage
	private(set) var lastResult: NSDictionary?
	private(set) var lastError: NSDictionary?
	private(set) var successCallCount = 0
	private(set) var failureCallCount = 0

	// Optionally fulfilled after the first delivery of the respective callback.
	var successExpectation: XCTestExpectation?
	var failureExpectation: XCTestExpectation?

	// Closures for inline assertions inside callbacks.
	var onSuccess: ((NSDictionary) -> Void)?
	var onFailure: ((NSDictionary) -> Void)?

	func faceMeshReady(result: NSDictionary) {
		lastResult = result
		successCallCount += 1
		onSuccess?(result)
		successExpectation?.fulfill()
	}

	func faceMeshFailed(error: NSDictionary) {
		lastError = error
		failureCallCount += 1
		onFailure?(error)
		failureExpectation?.fulfill()
	}

	// Convenience: assert that exactly one failure was received and return the
	// error code as an Int.
	func assertSingleFailureCode(
		_ expectedCode: ScanError.Code,
		file: StaticString = #file, line: UInt = #line
	) {
		XCTAssertEqual(failureCallCount, 1, "Expected exactly 1 failure", file: file, line: line)
		XCTAssertEqual(successCallCount, 0, "Expected no successes", file: file, line: line)
		let code = lastError?["code"] as? Int
		XCTAssertEqual(code, expectedCode.rawValue, file: file, line: line)
	}
}

// ---------------------------------------------------------------------------
// MARK: - MockFaceLandmarker
// ---------------------------------------------------------------------------

/// Configurable stub for FaceDetecting.  Each test sets `stubbedResult` before
/// calling the bridge; `detect(image:)` returns that value immediately.
final class MockFaceLandmarker: FaceDetecting {

	/// The value that will be returned from the next `detect(image:)` call.
	var stubbedResult: Result<[FaceLandmarkerService.DetectedFace], ScanError>
		= .success([])

	/// Records every UIImage passed to detect(image:) so tests can inspect them.
	private(set) var receivedImages: [UIImage] = []

	/// Number of times detect(image:) has been called.
	private(set) var detectCallCount = 0

	func detect(image uiImage: UIImage) -> Result<[FaceLandmarkerService.DetectedFace], ScanError> {
		detectCallCount += 1
		receivedImages.append(uiImage)
		return stubbedResult
	}
}

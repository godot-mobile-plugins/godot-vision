//
// © 2026-present https://github.com/cengiz-pz
//
// ScanErrorTests.swift
//
// Full coverage of ScanError: enum raw values, buildNSDictionary(), and
// cross-platform parity guarantees (raw values must stay fixed so GDScript
// can use the same numeric constants on Android and iOS).
//

@testable import vision_plugin
import XCTest

final class ScanErrorTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: - Raw value parity (must not change — GDScript depends on these)
	// -----------------------------------------------------------------------

	func testNoneRawValueIsZero() {
		XCTAssertEqual(ScanError.Code.none.rawValue, 0)
	}

	func testInvalidImageRawValueIsOne() {
		XCTAssertEqual(ScanError.Code.invalidImage.rawValue, 1)
	}

	func testNoFaceDetectedRawValueIsTwo() {
		XCTAssertEqual(ScanError.Code.noFaceDetected.rawValue, 2)
	}

	func testScannerFailureRawValueIsThree() {
		XCTAssertEqual(ScanError.Code.scannerFailure.rawValue, 3)
	}

	func testInternalErrorRawValueIsFour() {
		XCTAssertEqual(ScanError.Code.internalError.rawValue, 4)
	}

	/// Guarantees no gaps or duplicates in the raw value sequence.
	func testRawValuesAreContiguousZeroToFour() {
		let allCodes: [ScanError.Code] = [.none, .invalidImage, .noFaceDetected,
										.scannerFailure, .internalError]
		let rawValues = allCodes.map(\.rawValue).sorted()
		XCTAssertEqual(rawValues, Array(0...4))
	}

	// -----------------------------------------------------------------------
	// MARK: - buildNSDictionary – structure
	// -----------------------------------------------------------------------

	func testBuildNSDictionaryContainsCodeKey() {
		let error = ScanError(code: .invalidImage, description: "bad image")
		let dict = error.buildNSDictionary()
		XCTAssertNotNil(dict["code"])
	}

	func testBuildNSDictionaryContainsDescriptionKey() {
		let error = ScanError(code: .invalidImage, description: "bad image")
		let dict = error.buildNSDictionary()
		XCTAssertNotNil(dict["description"])
	}

	func testBuildNSDictionaryHasExactlyTwoKeys() {
		let error = ScanError(code: .none, description: "")
		let dict = error.buildNSDictionary()
		XCTAssertEqual(dict.count, 2)
	}

	// -----------------------------------------------------------------------
	// MARK: - buildNSDictionary – code values
	// -----------------------------------------------------------------------

	func testBuildNSDictionaryCodeMatchesRawValue_none() {
		assertCode(.none)
	}

	func testBuildNSDictionaryCodeMatchesRawValue_invalidImage() {
		assertCode(.invalidImage)
	}

	func testBuildNSDictionaryCodeMatchesRawValue_noFaceDetected() {
		assertCode(.noFaceDetected)
	}

	func testBuildNSDictionaryCodeMatchesRawValue_scannerFailure() {
		assertCode(.scannerFailure)
	}

	func testBuildNSDictionaryCodeMatchesRawValue_internalError() {
		assertCode(.internalError)
	}

	// -----------------------------------------------------------------------
	// MARK: - buildNSDictionary – description values
	// -----------------------------------------------------------------------

	func testBuildNSDictionaryDescriptionIsPreservedVerbatim() {
		let message = "MediaPipe detection failed: some reason"
		let error = ScanError(code: .scannerFailure, description: message)
		let dict = error.buildNSDictionary()
		XCTAssertEqual(dict["description"] as? String, message)
	}

	func testBuildNSDictionaryAllowsEmptyDescription() {
		let error = ScanError(code: .none, description: "")
		let dict = error.buildNSDictionary()
		XCTAssertEqual(dict["description"] as? String, "")
	}

	func testBuildNSDictionaryPreservesUnicodeDescription() {
		let message = "Échec de détection 🙁"
		let error = ScanError(code: .internalError, description: message)
		let dict = error.buildNSDictionary()
		XCTAssertEqual(dict["description"] as? String, message)
	}

	// -----------------------------------------------------------------------
	// MARK: - buildNSDictionary – type safety
	// -----------------------------------------------------------------------

	func testBuildNSDictionaryCodeIsNSNumber() {
		let dict = ScanError(code: .invalidImage, description: "").buildNSDictionary()
		XCTAssertTrue(dict["code"] is NSNumber)
	}

	func testBuildNSDictionaryDescriptionIsNSString() {
		let dict = ScanError(code: .invalidImage, description: "x").buildNSDictionary()
		XCTAssertTrue(dict["description"] is NSString)
	}

	// -----------------------------------------------------------------------
	// MARK: - Private helpers
	// -----------------------------------------------------------------------

	private func assertCode(
		_ code: ScanError.Code,
		file: StaticString = #file, line: UInt = #line
	) {
		let dict = ScanError(code: code, description: "test").buildNSDictionary()
		let dictCode = (dict["code"] as? NSNumber)?.intValue
		XCTAssertEqual(dictCode, code.rawValue, file: file, line: line)
	}
}

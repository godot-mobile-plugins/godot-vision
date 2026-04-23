//
// © 2026-present https://github.com/cengiz-pz
//
// ImageInfoTests.swift
//
// Exercises every execution path in ImageInfo.makeUIImage(from:width:height:).
// All tests are self-contained: no MediaPipe dependency.
//

@testable import vision_plugin
import XCTest

final class ImageInfoTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: - Happy paths
	// -----------------------------------------------------------------------

	func testSinglePixelBufferProducesNonNilImage() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.singlePixelBuffer, width: 1, height: 1)
		XCTAssertNotNil(image)
	}

	func testSmallSquareBufferProducesNonNilImage() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.smallSquareBuffer, width: 8, height: 8)
		XCTAssertNotNil(image)
	}

	func testRectangularBufferProducesNonNilImage() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.rectangularBuffer, width: 16, height: 4)
		XCTAssertNotNil(image)
	}

	func testProducedImageHasCorrectWidthInPoints() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.rgbaBuffer(width: 20, height: 10), width: 20, height: 10)
		XCTAssertEqual(Int(image!.size.width), 20)
	}

	func testProducedImageHasCorrectHeightInPoints() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.rgbaBuffer(width: 20, height: 10), width: 20, height: 10)
		XCTAssertEqual(Int(image!.size.height), 10)
	}

	/// CGImage should be present (i.e. not a CIImage-backed UIImage).
	func testProducedImageHasCGImage() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.smallSquareBuffer, width: 8, height: 8)
		XCTAssertNotNil(image?.cgImage)
	}

	/// A buffer larger than required is accepted; only the first `w * h * 4`
	/// bytes are consumed.
	func testOversizedBufferProducesValidImage() {
		var buffer = TestFixtures.rgbaBuffer(width: 4, height: 4)
		buffer.append(contentsOf: [UInt8](repeating: 0, count: 100)) // extra bytes
		let image = ImageInfo.makeUIImage(from: buffer, width: 4, height: 4)
		XCTAssertNotNil(image)
	}

	// -----------------------------------------------------------------------
	// MARK: - Dimension edge-cases
	// -----------------------------------------------------------------------

	func testWidthZeroReturnsNil() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.smallSquareBuffer, width: 0, height: 8)
		XCTAssertNil(image)
	}

	func testHeightZeroReturnsNil() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.smallSquareBuffer, width: 8, height: 0)
		XCTAssertNil(image)
	}

	func testNegativeWidthReturnsNil() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.smallSquareBuffer, width: -1, height: 8)
		XCTAssertNil(image)
	}

	func testNegativeHeightReturnsNil() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.smallSquareBuffer, width: 8, height: -1)
		XCTAssertNil(image)
	}

	func testBothDimensionsZeroReturnsNil() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.emptyBuffer, width: 0, height: 0)
		XCTAssertNil(image)
	}

	// -----------------------------------------------------------------------
	// MARK: - Buffer size edge-cases
	// -----------------------------------------------------------------------

	func testEmptyBufferReturnsNil() {
		let image = ImageInfo.makeUIImage(
			from: TestFixtures.emptyBuffer, width: 4, height: 4)
		XCTAssertNil(image)
	}

	func testUndersizedBufferByOneByteReturnsNil() {
		let buffer = TestFixtures.undersizedBuffer(width: 4, height: 4)
		let image = ImageInfo.makeUIImage(from: buffer, width: 4, height: 4)
		XCTAssertNil(image)
	}

	func testBufferExactlyRightSizeSucceeds() {
		// 3 × 3 × 4 = 36 bytes exactly
		let buffer = TestFixtures.rgbaBuffer(width: 3, height: 3)
		XCTAssertEqual(buffer.count, 36)
		let image = ImageInfo.makeUIImage(from: buffer, width: 3, height: 3)
		XCTAssertNotNil(image)
	}

	// -----------------------------------------------------------------------
	// MARK: - FORMAT_RGBA8 constant
	// -----------------------------------------------------------------------

	func testFormatRGBA8ConstantEqualsGodotValue() {
		// Godot Image.FORMAT_RGBA8 == 4 – must stay in sync with the Android plugin.
		XCTAssertEqual(ImageInfo.formatRGBA8, 4)
	}

	// -----------------------------------------------------------------------
	// MARK: - Extreme dimensions (stress)
	// -----------------------------------------------------------------------

	/// 1920 × 1080 – representative HD camera frame.
	func testLargeHDFrameSucceeds() {
		let w = 1920, h = 1080
		let buffer = TestFixtures.rgbaBuffer(width: w, height: h)
		let image = ImageInfo.makeUIImage(from: buffer, width: w, height: h)
		XCTAssertNotNil(image, "HD-sized buffer should produce a valid UIImage")
	}

	/// Very tall, very narrow (1 × 512) – non-square boundary condition.
	func testTallNarrowImageSucceeds() {
		let buffer = TestFixtures.rgbaBuffer(width: 1, height: 512)
		let image = ImageInfo.makeUIImage(from: buffer, width: 1, height: 512)
		XCTAssertNotNil(image)
	}
}

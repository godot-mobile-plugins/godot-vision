//
// © 2026-present https://github.com/cengiz-pz
//
// TestFixtures.swift
//
// Centralised factory helpers used across all VisionPlugin test suites.
// Nothing in this file imports XCTest so it can be shared freely.
//

import Foundation
import UIKit
@testable import vision_plugin
import XCTest

// ---------------------------------------------------------------------------
// MARK: - Landmark helpers
// ---------------------------------------------------------------------------

enum TestFixtures {

	// -----------------------------------------------------------------------
	// Landmark factories
	// -----------------------------------------------------------------------

	/// Returns `count` landmarks all set to the same (x, y, z) value.
	static func uniformLandmarks(
		count: Int = 468,
		x: Float = 0.5, y: Float = 0.5, z: Float = 0.0
	) -> [(x: Float, y: Float, z: Float)] {
		Array(repeating: (x: x, y: y, z: z), count: count)
	}

	/// Returns exactly 468 landmarks with distinct, predictable values so
	/// individual entries can be asserted on.
	///
	/// landmark[i] = (x: Float(i) / 467, y: Float(i) / 467, z: Float(-i) / 467)
	static var indexedLandmarks: [(x: Float, y: Float, z: Float)] {
		(0..<468).map { i in
			let t = Float(i) / 467.0
			return (x: t, y: t, z: -t)
		}
	}

	/// Returns a landmark list that is intentionally shorter than 468 points,
	/// used to exercise `compactMap { idx in guard idx < landmarks.count }` in
	/// FaceMeshInfo.buildContoursDict().
	static var shortLandmarks: [(x: Float, y: Float, z: Float)] {
		uniformLandmarks(count: 10)
	}

	// -----------------------------------------------------------------------
	// FaceLandmarkerService.DetectedFace factories
	// -----------------------------------------------------------------------

	static func makeDetectedFace(
		landmarks: [(x: Float, y: Float, z: Float)] = TestFixtures.uniformLandmarks()
	) -> FaceLandmarkerService.DetectedFace {
		FaceLandmarkerService.DetectedFace(landmarks: landmarks)
	}

	static var twoDetectedFaces: [FaceLandmarkerService.DetectedFace] {
		[makeDetectedFace(), makeDetectedFace(landmarks: indexedLandmarks)]
	}

	// -----------------------------------------------------------------------
	// Raw RGBA8 pixel buffer factories
	// -----------------------------------------------------------------------

	/// Returns a packed RGBA8 buffer for a solid-colour `width × height` image.
	static func rgbaBuffer(
		width: Int, height: Int,
		r: UInt8 = 200, g: UInt8 = 100, b: UInt8 = 50, a: UInt8 = 255
	) -> Data {
		var bytes = [UInt8]()
		bytes.reserveCapacity(width * height * 4)
		for _ in 0 ..< (width * height) {
			bytes.append(r); bytes.append(g); bytes.append(b); bytes.append(a)
		}
		return Data(bytes)
	}

	/// Minimum valid square buffer (1 × 1 pixel).
	static var singlePixelBuffer: Data { rgbaBuffer(width: 1, height: 1) }

	/// Typical small test image (8 × 8 pixels).
	static var smallSquareBuffer: Data { rgbaBuffer(width: 8, height: 8) }

	/// Non-square buffer (16 wide × 4 high).
	static var rectangularBuffer: Data { rgbaBuffer(width: 16, height: 4) }

	/// Buffer whose byte count is one byte too short for the declared dimensions.
	static func undersizedBuffer(width: Int, height: Int) -> Data {
		let full = rgbaBuffer(width: width, height: height)
		return full.dropLast()
	}

	/// Completely empty buffer.
	static var emptyBuffer: Data { Data() }
}

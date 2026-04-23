//
// © 2026-present https://github.com/cengiz-pz
//
// FaceDetecting.swift
//
// Protocol that abstracts FaceLandmarkerService so the VisionSwiftBridge can
// be unit-tested without a real MediaPipe model on disk.
//
// Production code path: FaceLandmarkerService (the only concrete type).
// Test code path:       MockFaceLandmarker (lives in the test target only).
//
// Adding this protocol requires one matching change in VisionSwiftBridge.swift:
//
//   Before:  private var landmarkerService: FaceLandmarkerService?
//   After:   var landmarkerService: (any FaceDetecting)?     // internal for @testable
//
// FaceLandmarkerService.init() is unchanged.  The stored property is widened to
// the protocol so the test target can inject a mock without a model file.
//

import UIKit

/// Abstracts the face-landmark detection operation.
protocol FaceDetecting {
	/// Synchronously detect faces in `image`.
	/// Called on the processingQueue; must be thread-safe.
	func detect(image uiImage: UIImage) -> Result<[FaceLandmarkerService.DetectedFace], ScanError>
}

// ---------------------------------------------------------------------------
// Retroactive conformance – no behaviour change, just adoption.
// ---------------------------------------------------------------------------
extension FaceLandmarkerService: FaceDetecting {}

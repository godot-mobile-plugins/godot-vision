//
// © 2026-present https://github.com/cengiz-pz
//
// FaceLandmarker.swift
//
// Wraps MediaPipe Tasks Vision's FaceLandmarker to provide the same 468-point
// face-mesh output as the Android ML Kit implementation.
//
// MediaPipe Tasks Vision (iOS) returns 478 normalised landmarks per face
// (468 mesh points + 10 iris landmarks).  Only the first 468 are used here
// to maintain API parity with the Android plugin.
//

import Foundation
import MediaPipeTasksVision
import UIKit

// Private type alias to prevent collision with this file's own class names.
private typealias MPFaceLandmarker         = MediaPipeTasksVision.FaceLandmarker
private typealias MPFaceLandmarkerOptions  = MediaPipeTasksVision.FaceLandmarkerOptions
private typealias MPFaceLandmarkerResult   = MediaPipeTasksVision.FaceLandmarkerResult
private typealias MPRunningMode            = MediaPipeTasksVision.RunningMode

// ---------------------------------------------------------------------------
// FaceLandmarkerService
//
// Owns the MediaPipe FaceLandmarker instance and exposes a single
// synchronous detect(image:) call.  Results are expressed as an array of
// DetectedFace value types so that callers (FaceScanResult) are decoupled
// from the MediaPipe SDK.
// ---------------------------------------------------------------------------
final class FaceLandmarkerService {

	// -----------------------------------------------------------------------
	// Public result type
	// -----------------------------------------------------------------------

	/// One detected face, carrying the 468 mesh landmarks and their derived
	/// contour subsets.
	struct DetectedFace {
		/// 468 landmarks with (x, y, z) normalised to [0, 1] for x/y and
		/// relative depth for z – matches the Android plugin's layout exactly.
		let landmarks: [(x: Float, y: Float, z: Float)]
	}

	// -----------------------------------------------------------------------
	// Errors
	// -----------------------------------------------------------------------

	enum ServiceError: Error {
		case modelNotFound
		case initFailed(Error)
		case detectionFailed(Error)
	}

	// -----------------------------------------------------------------------
	// Constants
	// -----------------------------------------------------------------------

	/// Maximum number of faces the detector will report.
	private static let maxFaces = 5

	/// The bundled MediaPipe model asset name (without extension).
	private static let modelAssetName = "face_landmarker"
	private static let modelAssetExtension = "task"

	// -----------------------------------------------------------------------
	// Private state
	// -----------------------------------------------------------------------

	private let landmarker: MPFaceLandmarker

	// -----------------------------------------------------------------------
	// Initialiser
	//
	// Throws ServiceError if the model asset is missing or MediaPipe fails to
	// initialise.
	// -----------------------------------------------------------------------
	init() throws {
		guard let modelURL = Bundle.main.url(
				forResource: Self.modelAssetName,
				withExtension: Self.modelAssetExtension) else {
			throw ServiceError.modelNotFound
		}

		let options = MPFaceLandmarkerOptions()
		options.baseOptions.modelAssetPath = modelURL.path
		options.runningMode           = .image
		options.numFaces              = Self.maxFaces
		// Blendshapes and transformation matrices are not needed for this
		// plugin's feature set; keep them off to save compute.
		options.outputFaceBlendshapes              = false
		options.outputFacialTransformationMatrixes = false

		do {
			landmarker = try MPFaceLandmarker(options: options)
		} catch {
			throw ServiceError.initFailed(error)
		}
	}

	// -----------------------------------------------------------------------
	// detect(image:)
	//
	// Runs face landmark detection synchronously on the calling thread.
	// Call this from a background queue (VisionSwiftBridge does this).
	//
	// Returns an array of DetectedFace (one per face found, may be empty),
	// or a failure wrapping the underlying MediaPipe error.
	// -----------------------------------------------------------------------
	func detect(image uiImage: UIImage) -> Result<[DetectedFace], ScanError> {
		let mpImage: MPImage
		do {
			mpImage = try MPImage(uiImage: uiImage)
		} catch {
			return .failure(ScanError(code: .invalidImage,
									description: "MPImage construction failed: \(error.localizedDescription)"))
		}

		let result: MPFaceLandmarkerResult
		do {
			result = try landmarker.detect(image: mpImage)
		} catch {
			return .failure(ScanError(code: .scannerFailure,
									description: "MediaPipe detection failed: \(error.localizedDescription)"))
		}

		// Convert MediaPipe landmarks -> plugin DetectedFace types.
		// MediaPipe returns 478 landmarks (468 mesh + 10 iris).
		// We keep only the first 468 for Android parity.
		let meshLandmarkCount = 468
		let faces: [DetectedFace] = result.faceLandmarks.map { landmarkList in
			let landmarks: [(x: Float, y: Float, z: Float)] =
				landmarkList
					.prefix(meshLandmarkCount)
					.map { lm in (x: lm.x, y: lm.y, z: lm.z) }
			return DetectedFace(landmarks: landmarks)
		}

		return .success(faces)
	}
}

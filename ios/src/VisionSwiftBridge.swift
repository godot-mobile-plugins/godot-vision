//
// © 2026-present https://github.com/cengiz-pz
//

//
// Acts as the seam between the ObjC++ VisionPlugin and the pure-Swift
// FaceLandmarkerService.  All public symbols are annotated @objc so that
// the auto-generated "vision_plugin-Swift.h" header exposes them to the
// .mm file.
//
// Thread model
// -----------
//   • scan_face / set_max_faces are called on the Godot main thread.
//   • All MediaPipe work is dispatched to a private serial background queue
//     so the game loop is never blocked.
//   • Delegate callbacks are delivered back on the main thread via
//     DispatchQueue.main.async so that Godot signal emission is safe.
//

import Foundation
import UIKit        // UIImage – needed for image construction

// ---------------------------------------------------------------------------
// VisionSwiftBridgeDelegate
//
// The ObjC callback shim (FaceMeshCallbackHandler in vision_plugin.mm)
// conforms to this protocol so results can travel back to C++ without
// Swift needing to know about Godot or C++ types.
// ---------------------------------------------------------------------------
@objc public protocol VisionSwiftBridgeDelegate: AnyObject {
	/// Called when face-mesh detection succeeds.  The dictionary layout
	/// matches FaceScanResult.buildNSDictionary() – see that class for the
	/// full schema.
	func faceMeshReady(result: NSDictionary)

	/// Called when face-mesh detection fails.  The dictionary contains
	///   { "code": Int, "description": String }
	func faceMeshFailed(error: NSDictionary)
}

// ---------------------------------------------------------------------------
// VisionSwiftBridge
// ---------------------------------------------------------------------------
@objc(VisionSwiftBridge)
public class VisionSwiftBridge: NSObject {

	// Strong reference – the handler is a local in the C++ constructor so nothing
	// else owns it.  weak would zero this property the moment the constructor
	// returns, silently dropping every callback.  There is no retain cycle:
	// FaceMeshCallbackHandler holds no reference back to VisionSwiftBridge.
	@objc public var delegate: VisionSwiftBridgeDelegate?

	var landmarkerService: (any FaceDetecting)?

	// Maximum number of faces passed to FaceLandmarkerService on (re-)init.
	// Defaults to FaceLandmarkerService.defaultMaxFaces (5).
	// GDScript callers use set_max_faces() in VisionPlugin to change this.
	private var maxFaces: Int = FaceLandmarkerService.defaultMaxFaces

	// Stores the error thrown by FaceLandmarkerService.init() so it can be
	// forwarded in full to GDScript rather than replaced with the generic
	// "Landmarker service not initialised" message.
	private var initializationError: Error?
	private let processingQueue = DispatchQueue(
		label: "org.godotengine.plugin.vision.facemesh",
		qos: .userInitiated)

	// -----------------------------------------------------------------------
	// initialize
	//
	// Called from the VisionPlugin constructor.  Safe to call multiple times
	// (subsequent calls are no-ops when the service is already running).
	// -----------------------------------------------------------------------
	@objc public func initialize() {
		guard landmarkerService == nil else { return }
		do {
			landmarkerService = try FaceLandmarkerService(numFaces: maxFaces)
			initializationError = nil
		} catch {
			initializationError = error
			NSLog("[VisionSwiftBridge] Failed to initialise FaceLandmarkerService: \(error)")
		}
	}

	// -----------------------------------------------------------------------
	// setMaxFaces(_:)
	//
	// Updates the maximum number of faces the detector will report and
	// re-initialises the underlying FaceLandmarkerService with the new limit.
	//
	// Call this from GDScript via VisionPlugin.set_max_faces(n) before or
	// after the first scan_face(); the service is restarted transparently.
	//
	// The value is clamped to [1, FaceLandmarkerService.absoluteMaxFaces] here
	// so that the stored maxFaces always reflects the effective limit.
	// -----------------------------------------------------------------------
	@objc public func setMaxFaces(_ value: Int) {
		let clamped = max(1, min(value, FaceLandmarkerService.absoluteMaxFaces))
		guard clamped != maxFaces else { return }   // no-op if unchanged

		maxFaces = clamped

		// Tear down the existing service so initialize() will rebuild it with
		// the updated numFaces parameter.
		landmarkerService = nil
		initializationError = nil

		initialize()
	}

	// -----------------------------------------------------------------------
	// shutdown
	//
	// Called from the VisionPlugin destructor.  Releases MediaPipe resources.
	// -----------------------------------------------------------------------
	@objc public func shutdown() {
		landmarkerService = nil
	}

	// -----------------------------------------------------------------------
	// scanFace(buffer:width:height:)
	//
	// Entry point from VisionPlugin::scan_face().
	// Dispatches detection to the background queue; delegates back on main.
	//
	// Parameters
	//   buffer   Raw RGBA8 pixel data (Godot Image.FORMAT_RGBA8 layout).
	//   width    Image width in pixels.
	//   height   Image height in pixels.
	// -----------------------------------------------------------------------
	@objc public func scanFace(buffer: NSData, width: Int, height: Int) {
		guard let service = landmarkerService else {
			// Surface the actual error that caused initialisation to fail rather
			// than the generic "not initialised" message that swallows the cause.
			let description: String
			if let err = initializationError {
				description = "Landmarker service failed to initialise: \(err)"
			} else {
				description = "Landmarker service not initialised"
			}
			deliverFailure(ScanError(code: .internalError,
									description: description).buildNSDictionary())
			return
		}

		// Copy NSData to a Swift-owned value before hopping threads.
		let data = Data(referencing: buffer)

		processingQueue.async { [weak self] in
			guard let self = self else { return }
			self.process(imageData: data, width: width, height: height,
						service: service)
		}
	}

	// -----------------------------------------------------------------------
	// Private – image processing
	// -----------------------------------------------------------------------
	private func process(imageData: Data,
						width: Int,
						height: Int,
						service: any FaceDetecting) {
		// Build a UIImage from the raw RGBA8 buffer.
		guard let image = ImageInfo.makeUIImage(from: imageData,
												width: width,
												height: height) else {
			let error = ScanError(code: .invalidImage,
								description: "Could not construct UIImage from buffer")
			deliverFailure(error.buildNSDictionary())
			return
		}

		// Run MediaPipe detection.
		switch service.detect(image: image) {
		case .success(let faces) where faces.isEmpty:
			let error = ScanError(code: .noFaceDetected,
								description: "No faces detected in image")
			deliverFailure(error.buildNSDictionary())

		case .success(let faces):
			let result = FaceScanResult(faces: faces,
										imageWidth: width,
										imageHeight: height)
			deliverSuccess(result.buildNSDictionary())

		case .failure(let scanError):
			deliverFailure(scanError.buildNSDictionary())
		}
	}

	// -----------------------------------------------------------------------
	// Private – threaded delivery helpers
	// -----------------------------------------------------------------------
	private func deliverSuccess(_ result: NSDictionary) {
		DispatchQueue.main.async { [weak self] in
			self?.delegate?.faceMeshReady(result: result)
		}
	}

	private func deliverFailure(_ error: NSDictionary) {
		DispatchQueue.main.async { [weak self] in
			self?.delegate?.faceMeshFailed(error: error)
		}
	}
}

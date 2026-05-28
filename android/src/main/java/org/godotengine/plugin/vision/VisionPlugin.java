//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision;

import android.app.Activity;
import android.graphics.Bitmap;
import android.util.Log;
import android.view.View;

import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.facemesh.FaceMeshDetection;
import com.google.mlkit.vision.facemesh.FaceMeshDetector;
import com.google.mlkit.vision.facemesh.FaceMeshDetectorOptions;

import java.io.Closeable;
import java.nio.ByteBuffer;
import java.util.HashSet;
import java.util.Set;

import org.godotengine.godot.Godot;
import org.godotengine.godot.Dictionary;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import org.godotengine.plugin.vision.model.FaceScanResult;
import org.godotengine.plugin.vision.model.ImageInfo;
import org.godotengine.plugin.vision.model.ScanError;
import static org.godotengine.plugin.vision.model.ScanError.Code;

public class VisionPlugin extends GodotPlugin {
	public static final String CLASS_NAME = VisionPlugin.class.getSimpleName();
	static final String LOG_TAG = "godot::" + CLASS_NAME;

	static final String FACE_MESH_READY_SIGNAL = "face_mesh_ready";
	static final String FACE_MESH_FAILED_SIGNAL = "face_mesh_failed";

	/** Detector is held as a field so it can be closed and recreated. */
	private FaceMeshDetector faceMeshDetector;

	public VisionPlugin(Godot godot) {
		super(godot);
	}

	@Override
	public String getPluginName() {
		return CLASS_NAME;
	}

	@Override
	public Set<SignalInfo> getPluginSignals() {
		Set<SignalInfo> signals = new HashSet<>();
		signals.add(new SignalInfo(FACE_MESH_READY_SIGNAL, Dictionary.class));
		signals.add(new SignalInfo(FACE_MESH_FAILED_SIGNAL, Dictionary.class));
		return signals;
	}

	@Override
	public View onMainCreate(Activity activity) {
		return super.onMainCreate(activity);
	}

	@Override
	public void onGodotSetupCompleted() {
		super.onGodotSetupCompleted();
		initDetector();
	}

	// -------------------------------------------------------------------------
	// set_max_faces
	// Called from GDScript: _plugin_singleton.set_max_faces(n)
	//
	// NOTE: ML Kit's FaceMeshDetectorOptions.Builder does not expose a
	// setMaxNumFaces() method — the face limit is fixed internally by the SDK
	// (default 5).  This method exists solely to keep the GDScript API
	// consistent with the iOS plugin, which does support a configurable limit
	// via MediaPipe.  Calls on Android are silently accepted and logged so
	// cross-platform GDScript code that calls set_max_faces() does not error.
	// -------------------------------------------------------------------------
	@UsedByGodot
	public void set_max_faces(int aMaxFaces) {
		Log.d(LOG_TAG, "set_max_faces(" + aMaxFaces + ") called – "
				+ "ML Kit FaceMeshDetector does not support a configurable face limit; "
				+ "the SDK default (5) is used on Android.");
	}

	// -------------------------------------------------------------------------
	// scan_face
	// Called from GDScript via: _plugin_singleton.scan_face(image_info_dict)
	//
	// The dictionary is expected to contain the fields produced by
	// ImageInfo.create_from_image() on the GDScript side:
	//   buffer  – byte[]  raw RGBA8 pixels
	//   width   – long
	//   height  – long
	//   format  – long    (Godot Image.FORMAT_RGBA8 == 4)
	//
	// On success emits face_mesh_ready with a result dictionary (see below).
	// On failure emits face_mesh_failed with a ScanError dictionary.
	// -------------------------------------------------------------------------
	@UsedByGodot
	public void scan_face(Dictionary imageDict) {
		Log.d(LOG_TAG, "scan_face() invoked");

		if (faceMeshDetector == null) {
			emitSignal(FACE_MESH_FAILED_SIGNAL,
					new ScanError(Code.INTERNAL_ERROR, "Detector not initialised").buildRawData());
			return;
		}

		ImageInfo imageInfo = new ImageInfo(imageDict);
		byte[] buffer = imageInfo.getBuffer();
		int width = imageInfo.getWidth();
		int height = imageInfo.getHeight();

		if (buffer == null || width <= 0 || height <= 0) {
			emitSignal(FACE_MESH_FAILED_SIGNAL,
					new ScanError(Code.INVALID_IMAGE, "Invalid image data").buildRawData());
			return;
		}

		try {
			// Godot Image.get_data() with FORMAT_RGBA8 gives packed RGBA bytes.
			// Android Bitmap.Config.ARGB_8888 stores pixels as 0xAARRGGBB in
			// native byte order, so we must swap R↔B channels when copying.
			Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
			// copyPixelsFromBuffer interprets the buffer as RGBA in the buffer's
			// byte order – which matches Godot's FORMAT_RGBA8 layout directly.
			bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(buffer));

			InputImage mlImage = InputImage.fromBitmap(bitmap, 0 /* rotationDegrees */);

			faceMeshDetector.process(mlImage)
					.addOnSuccessListener(faceMeshes -> {
						if (faceMeshes == null || faceMeshes.isEmpty()) {
							emitSignal(FACE_MESH_FAILED_SIGNAL,
									new ScanError(Code.NO_CODE_DETECTED, "No faces detected")
											.buildRawData());
							return;
						}
						FaceScanResult result = new FaceScanResult(faceMeshes, width, height);
						emitSignal(FACE_MESH_READY_SIGNAL, result.buildRawData());
					})
					.addOnFailureListener(e -> {
						Log.e(LOG_TAG, "Face mesh detection failed", e);
						emitSignal(FACE_MESH_FAILED_SIGNAL,
								new ScanError(Code.SCANNER_FAILURE, e.getMessage()).buildRawData());
					});

		} catch (Exception e) {
			Log.e(LOG_TAG, "Error processing image", e);
			emitSignal(FACE_MESH_FAILED_SIGNAL,
					new ScanError(Code.INTERNAL_ERROR, e.getMessage()).buildRawData());
		}
	}

	@Override
	public void onMainDestroy() {
		closeDetector();
	}

	// -------------------------------------------------------------------------
	// Private helpers
	// -------------------------------------------------------------------------

	/**
	 * Creates (or recreates) the FaceMeshDetector using the current maxFaces
	 * value.  Any previously open detector is closed first to release resources.
	 */
	private void initDetector() {
		closeDetector();
		FaceMeshDetectorOptions options = new FaceMeshDetectorOptions.Builder().build();
		faceMeshDetector = FaceMeshDetection.getClient(options);
		Log.d(LOG_TAG, "FaceMeshDetector initialised");
	}

	/** Closes and nulls the current detector, suppressing any IOException. */
	private void closeDetector() {
		if (faceMeshDetector != null) {
			try {
				((Closeable) faceMeshDetector).close();
			} catch (java.io.IOException e) {
				Log.e(LOG_TAG, "Error closing FaceMeshDetector", e);
			}
			faceMeshDetector = null;
			Log.d(LOG_TAG, "FaceMeshDetector closed");
		}
	}
}

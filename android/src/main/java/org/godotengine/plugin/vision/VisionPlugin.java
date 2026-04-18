//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision;

import android.app.Activity;
import android.graphics.Bitmap;
import android.util.Log;
import android.view.View;

import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.common.PointF3D;
import com.google.mlkit.vision.common.Triangle;
import com.google.mlkit.vision.facemesh.FaceMesh;
import com.google.mlkit.vision.facemesh.FaceMeshDetection;
import com.google.mlkit.vision.facemesh.FaceMeshDetector;
import com.google.mlkit.vision.facemesh.FaceMeshDetectorOptions;
import com.google.mlkit.vision.facemesh.FaceMeshPoint;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
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

	// Detector is held as a field so it can be closed on destroy.
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

		// Build the detector once and reuse it across calls.
		FaceMeshDetectorOptions options = new FaceMeshDetectorOptions.Builder()
				// USE_FACE_KEY_POINTS gives 468 landmarks + triangles.
				// BOUNDING_BOX_ONLY is faster but returns no mesh – keep default.
				.build();
		faceMeshDetector = FaceMeshDetection.getClient(options);
		Log.d(LOG_TAG, "FaceMeshDetector initialised");
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
		int width  = imageInfo.getWidth();
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
							// Successful run but no faces found – emit failure with a
							// distinct code so the caller can distinguish from errors.
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
		if (faceMeshDetector != null) {
			faceMeshDetector.close();
			faceMeshDetector = null;
			Log.d(LOG_TAG, "FaceMeshDetector closed");
		}
	}
}

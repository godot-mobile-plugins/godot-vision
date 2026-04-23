//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision;

import com.google.mlkit.vision.facemesh.FaceMesh;
import com.google.mlkit.vision.facemesh.FaceMeshDetector;

import org.godotengine.godot.Dictionary;
import org.godotengine.plugin.vision.fixtures.FaceMeshFixtures;
import org.godotengine.plugin.vision.fixtures.FakeTask;
import org.godotengine.plugin.vision.fixtures.ImageInfoFixtures;
import org.godotengine.plugin.vision.fixtures.VisionPluginTestHelper;
import org.godotengine.plugin.vision.model.ScanError;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Integration-level unit tests for {@link VisionPlugin}.
 *
 * The ML Kit {@link FaceMeshDetector} is replaced with a Mockito mock that
 * returns a {@link FakeTask} so all signal emissions happen synchronously on
 * the test thread — no CountDownLatch, no background threads.
 *
 * <h3>Signal recording</h3>
 * The {@link org.godotengine.godot.plugin.GodotPlugin} stub captures every
 * {@code emitSignal(name, args…)} call in {@code plugin.emittedSignals}.
 * Helper methods {@code lastSignalName()} and {@code lastSignalArg()} make
 * assertions concise.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("VisionPlugin")
class VisionPluginTest {

	@Mock
	private FaceMeshDetector mockDetector;

	private VisionPlugin plugin;

	@BeforeEach
	void setUp() {
		plugin = VisionPluginTestHelper.createWithMockDetector(mockDetector);
	}

	// -- Plugin metadata ----------------------------------------------------

	@Nested
	@DisplayName("plugin metadata")
	class Metadata {

		@Test
		@DisplayName("getPluginName() returns 'VisionPlugin'")
		void pluginName() {
			assertEquals("VisionPlugin", plugin.getPluginName());
		}

		@Test
		@DisplayName("getPluginSignals() declares 'face_mesh_ready'")
		void declaresReadySignal() {
			Set<?> signals = plugin.getPluginSignals();
			boolean found = signals.stream()
					.anyMatch(s -> s.toString().contains("face_mesh_ready"));
			assertTrue(found, "face_mesh_ready signal must be declared");
		}

		@Test
		@DisplayName("getPluginSignals() declares 'face_mesh_failed'")
		void declaresFailedSignal() {
			Set<?> signals = plugin.getPluginSignals();
			boolean found = signals.stream()
					.anyMatch(s -> s.toString().contains("face_mesh_failed"));
			assertTrue(found, "face_mesh_failed signal must be declared");
		}

		@Test
		@DisplayName("exactly two signals are declared")
		void exactlyTwoSignals() {
			assertEquals(2, plugin.getPluginSignals().size());
		}
	}

	// -- scan_face – valid image, faces detected ---------------------------

	@Nested
	@DisplayName("scan_face() – success path")
	class ScanFaceSuccess {

		@BeforeEach
		void configureDetectorSuccess() {
			List<FaceMesh> faces = List.of(FaceMeshFixtures.minimalFace());
			when(mockDetector.process(any())).thenReturn(FakeTask.success(faces));
		}

		@Test
		@DisplayName("emits 'face_mesh_ready' (not failed)")
		void emitsReadySignal() {
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			assertEquals(VisionPlugin.FACE_MESH_READY_SIGNAL, plugin.lastSignalName());
		}

		@Test
		@DisplayName("emitted payload is a Dictionary")
		void payloadIsDictionary() {
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			assertInstanceOf(Dictionary.class, plugin.lastSignalArg());
		}

		@Test
		@DisplayName("payload contains 'faces' key")
		void payloadHasFacesKey() {
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary payload = plugin.lastSignalArg();
			assertTrue(payload.containsKey("faces"), "Payload must contain 'faces'");
		}

		@Test
		@DisplayName("payload 'faces' array has one entry")
		void payloadOneFace() {
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary payload = plugin.lastSignalArg();
			Object[] faces = (Object[]) payload.get("faces");
			assertEquals(1, faces.length);
		}

		@Test
		@DisplayName("payload contains 'image_width' equal to image width")
		void payloadImageWidth() {
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary payload = plugin.lastSignalArg();
			assertEquals((long) FaceMeshFixtures.IMAGE_WIDTH, payload.get("image_width"));
		}

		@Test
		@DisplayName("payload contains 'image_height' equal to image height")
		void payloadImageHeight() {
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary payload = plugin.lastSignalArg();
			assertEquals((long) FaceMeshFixtures.IMAGE_HEIGHT, payload.get("image_height"));
		}

		@Test
		@DisplayName("detector.process() is called exactly once per scan_face() call")
		void detectorCalledOnce() {
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			verify(mockDetector, times(1)).process(any());
		}

		@Test
		@DisplayName("multiple faces are all included in the payload")
		void multipleFacesInPayload() {
			List<FaceMesh> faces = FaceMeshFixtures.multipleFaces(3);
			when(mockDetector.process(any())).thenReturn(FakeTask.success(faces));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary payload = plugin.lastSignalArg();
			Object[] arr = (Object[]) payload.get("faces");
			assertEquals(3, arr.length);
		}
	}

	// -- scan_face – no faces detected -------------------------------------

	@Nested
	@DisplayName("scan_face() – no faces detected")
	class ScanFaceEmpty {

		@Test
		@DisplayName("empty face list -> emits 'face_mesh_failed'")
		void emitsFailedSignalForEmptyList() {
			when(mockDetector.process(any()))
					.thenReturn(FakeTask.success(Collections.emptyList()));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
		}

		@Test
		@DisplayName("null face list -> emits 'face_mesh_failed'")
		void emitsFailedSignalForNullList() {
			when(mockDetector.process(any()))
					.thenReturn(FakeTask.success(null));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
		}

		@Test
		@DisplayName("failure payload code is NO_CODE_DETECTED")
		void failureCodeIsNoCodeDetected() {
			when(mockDetector.process(any()))
					.thenReturn(FakeTask.success(Collections.emptyList()));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(ScanError.Code.NO_CODE_DETECTED, error.get("code"));
		}
	}

	// -- scan_face – detector throws ----------------------------------------

	@Nested
	@DisplayName("scan_face() – detector failure")
	class ScanFaceDetectorFailure {

		@Test
		@DisplayName("detector failure -> emits 'face_mesh_failed'")
		void emitsFailedSignal() {
			when(mockDetector.process(any()))
					.thenReturn(FakeTask.failure(new RuntimeException("ML failure")));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
		}

		@Test
		@DisplayName("failure payload contains 'code' = SCANNER_FAILURE")
		void failureCodeIsScannerFailure() {
			when(mockDetector.process(any()))
					.thenReturn(FakeTask.failure(new RuntimeException("ML failure")));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(ScanError.Code.SCANNER_FAILURE, error.get("code"));
		}

		@Test
		@DisplayName("failure payload 'description' contains the exception message")
		void failureDescriptionContainsMessage() {
			String exMsg = "Network timeout from ML Kit";
			when(mockDetector.process(any()))
					.thenReturn(FakeTask.failure(new RuntimeException(exMsg)));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(exMsg, error.get("description"));
		}
	}

	// -- scan_face – invalid image data ------------------------------------

	@Nested
	@DisplayName("scan_face() – invalid image data (no detector call expected)")
	class ScanFaceInvalidImage {

		@Test
		@DisplayName("null buffer -> emits 'face_mesh_failed' with INVALID_IMAGE")
		void nullBuffer() {
			plugin.scan_face(ImageInfoFixtures.nullBufferDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(ScanError.Code.INVALID_IMAGE, error.get("code"));
		}

		@Test
		@DisplayName("zero-dimension image -> emits 'face_mesh_failed' with INVALID_IMAGE")
		void zeroDimensions() {
			plugin.scan_face(ImageInfoFixtures.zeroDimensionDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(ScanError.Code.INVALID_IMAGE, error.get("code"));
		}

		@Test
		@DisplayName("negative width -> emits 'face_mesh_failed' with INVALID_IMAGE")
		void negativeDimensions() {
			plugin.scan_face(ImageInfoFixtures.negativeDimensionDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(ScanError.Code.INVALID_IMAGE, error.get("code"));
		}

		@Test
		@DisplayName("invalid image does not call detector.process()")
		void detectorNotCalled() {
			plugin.scan_face(ImageInfoFixtures.nullBufferDict());
			verify(mockDetector, never()).process(any());
		}

		@Test
		@DisplayName("empty dict -> emits 'face_mesh_failed' with INVALID_IMAGE")
		void emptyDict() {
			plugin.scan_face(ImageInfoFixtures.emptyDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(ScanError.Code.INVALID_IMAGE, error.get("code"));
		}
	}

	// -- scan_face – uninitialised detector --------------------------------

	@Nested
	@DisplayName("scan_face() – detector not initialised")
	class ScanFaceNoDetector {

		@Test
		@DisplayName("null detector -> emits 'face_mesh_failed' with INTERNAL_ERROR")
		void nullDetectorEmitsInternalError() {
			VisionPluginTestHelper.injectDetector(plugin, null);
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(ScanError.Code.INTERNAL_ERROR, error.get("code"));
		}
	}

	// -- onMainDestroy lifecycle --------------------------------------------

	@Nested
	@DisplayName("onMainDestroy()")
	class Destroy {

		@Test
		@DisplayName("closes the detector")
		void closesDetector() {
			plugin.onMainDestroy();
			verify(mockDetector, times(1)).close();
		}

		@Test
		@DisplayName("nulls the detector field after close")
		void nullsDetectorField() {
			plugin.onMainDestroy();
			assertNull(VisionPluginTestHelper.readDetector(plugin));
		}

		@Test
		@DisplayName("second destroy call does not throw (detector is already null)")
		void idempotentDestroy() {
			plugin.onMainDestroy();
			assertDoesNotThrow(plugin::onMainDestroy);
		}

		@Test
		@DisplayName("scan_face() after destroy emits INTERNAL_ERROR")
		void scanAfterDestroyEmitsInternalError() {
			plugin.onMainDestroy();
			VisionPluginTestHelper.clearSignals(plugin);

			plugin.scan_face(ImageInfoFixtures.validImageDict());
			assertEquals(VisionPlugin.FACE_MESH_FAILED_SIGNAL, plugin.lastSignalName());
			Dictionary error = plugin.lastSignalArg();
			assertEquals(ScanError.Code.INTERNAL_ERROR, error.get("code"));
		}
	}

	// -- Signal payload contract --------------------------------------------

	@Nested
	@DisplayName("signal payload contract")
	class SignalPayloadContract {

		@Test
		@DisplayName("failed signal payload always has 'code' and 'description' keys")
		void failedPayloadKeys() {
			plugin.scan_face(ImageInfoFixtures.nullBufferDict());
			Dictionary error = plugin.lastSignalArg();
			assertTrue(error.containsKey("code"), "must have 'code'");
			assertTrue(error.containsKey("description"), "must have 'description'");
		}

		@Test
		@DisplayName("ready signal payload always has 'image_width', 'image_height', 'faces'")
		void readyPayloadKeys() {
			List<FaceMesh> faces = List.of(FaceMeshFixtures.minimalFace());
			when(mockDetector.process(any())).thenReturn(FakeTask.success(faces));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			Dictionary payload = plugin.lastSignalArg();
			assertTrue(payload.containsKey("image_width"), "must have 'image_width'");
			assertTrue(payload.containsKey("image_height"), "must have 'image_height'");
			assertTrue(payload.containsKey("faces"), "must have 'faces'");
		}

		@Test
		@DisplayName("exactly one signal emitted per scan_face() call")
		void exactlyOneSignalPerCall() {
			when(mockDetector.process(any()))
					.thenReturn(FakeTask.success(List.of(FaceMeshFixtures.minimalFace())));
			plugin.scan_face(ImageInfoFixtures.validImageDict());
			assertEquals(1, plugin.emittedSignals.size());
		}
	}
}

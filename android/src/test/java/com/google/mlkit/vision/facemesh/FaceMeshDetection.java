//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.mlkit.vision.facemesh;

/**
 * Test-only stub for the {@code FaceMeshDetection} factory class.
 *
 * <p>Because {@link FaceMeshDetector} is now correctly declared as an
 * <em>interface</em>, this factory returns an anonymous implementation that
 * does nothing.  Tests never actually call {@code getClient()} directly;
 * they inject a Mockito mock via
 * {@link org.godotengine.plugin.vision.fixtures.VisionPluginTestHelper#injectDetector}.
 * The no-op instance returned here exists only so that
 * {@code onGodotSetupCompleted()} (which calls this factory) does not NPE
 * before the mock is injected.
 */
public final class FaceMeshDetection {

	private FaceMeshDetection() {
	}

	/**
	* Returns a no-op {@link FaceMeshDetector} stub.
	* Tests replace this immediately via reflective field injection.
	*/
	public static FaceMeshDetector getClient(FaceMeshDetectorOptions options) {
		return new FaceMeshDetector() {
			@Override
			public com.google.android.gms.tasks.Task<java.util.List<FaceMesh>> process(
						com.google.mlkit.vision.common.InputImage image) {
				return null; // never called; the mock is injected before scan_face()
			}

			@Override
			public void close() { /* no-op */
			}
		};
	}
}

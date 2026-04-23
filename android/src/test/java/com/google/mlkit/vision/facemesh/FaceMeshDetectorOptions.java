//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.mlkit.vision.facemesh;

/**
 * Stub for {@code com.google.mlkit.vision.facemesh.FaceMeshDetectorOptions}.
 * Only the Builder pattern used by the plugin is required.
 */
public final class FaceMeshDetectorOptions {

	private FaceMeshDetectorOptions() {
	}

	public static final class Builder {

		public Builder() {
		}

		/** No-op – options are irrelevant in the test environment. */
		public Builder setPerformanceMode(int mode) {
			return this;
		}

		public FaceMeshDetectorOptions build() {
			return new FaceMeshDetectorOptions();
		}
	}
}

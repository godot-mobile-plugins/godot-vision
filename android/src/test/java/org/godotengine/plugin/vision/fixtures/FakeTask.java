//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.fixtures;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;

/**
 * Synchronous, single-shot {@link Task} implementation for unit tests.
 *
 * <p>Because the plugin chains {@code .addOnSuccessListener()} and
 * {@code .addOnFailureListener()} off the {@code Task} returned by
 * {@code FaceMeshDetector.process()}, we need a {@code Task} that fires
 * the appropriate listener immediately (on the calling thread) so tests
 * remain single-threaded and deterministic.
 *
 * <h3>extends, not implements</h3>
 * {@link Task} is an abstract class in the real GMS SDK (and in our stub),
 * so {@code FakeTask} must {@code extend} it rather than {@code implement} it.
 *
 * <h3>Usage</h3>
 * <pre>{@code
 * // Simulate a successful detection
 * when(mockDetector.process(any())).thenReturn(FakeTask.success(faceMeshes));
 *
 * // Simulate a detector failure
 * when(mockDetector.process(any())).thenReturn(FakeTask.failure(new RuntimeException("boom")));
 * }</pre>
 *
 * @param <T> the result type – typically {@code List<FaceMesh>}
 */
public final class FakeTask<T> extends Task<T> {

	// -- State --------------------------------------------------------------

	private final T         result;
	private final Exception error;
	private final boolean   succeeded;

	// -- Constructors -------------------------------------------------------

	private FakeTask(T result, Exception error, boolean succeeded) {
		this.result = result;
		this.error = error;
		this.succeeded = succeeded;
	}

	// -- Factories ----------------------------------------------------------

	/**
	* Creates a {@code FakeTask} that fires {@code onSuccess(result)}
	* synchronously when a listener is registered.
	*/
	public static <T> FakeTask<T> success(T result) {
		return new FakeTask<>(result, null, true);
	}

	/**
	* Creates a {@code FakeTask} that fires {@code onFailure(error)}
	* synchronously when a listener is registered.
	*/
	public static <T> FakeTask<T> failure(Exception error) {
		return new FakeTask<>(null, error, false);
	}

	// -- Task<T> ------------------------------------------------------------

	/**
	* Fires {@code onSuccess} immediately if this task succeeded;
	* does nothing otherwise.
	*
	* <p>The real GMS {@code Task} fires these lazily on a background
	* thread; the synchronous model here keeps tests simple and avoids
	* {@code CountDownLatch} boilerplate.
	*/
	@Override
	public Task<T> addOnSuccessListener(OnSuccessListener<? super T> listener) {
		if (succeeded) {
			listener.onSuccess(result);
		}
		return this;
	}

	/**
	* Fires {@code onFailure} immediately if this task failed;
	* does nothing otherwise.
	*/
	@Override
	public Task<T> addOnFailureListener(OnFailureListener listener) {
		if (!succeeded) {
			listener.onFailure(error);
		}
		return this;
	}
}

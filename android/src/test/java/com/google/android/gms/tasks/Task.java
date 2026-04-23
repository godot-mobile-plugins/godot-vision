//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.android.gms.tasks;

/**
 * Test-only stub for {@code com.google.android.gms.tasks.Task<TResult>}.
 *
 * <h3>Why an abstract class?</h3>
 * The real GMS {@code Task<TResult>} is an <em>abstract class</em>, not an
 * interface.  Production code compiled against the real SDK therefore emits
 * {@code invokevirtual} (class dispatch) instructions when it calls
 * {@code .addOnSuccessListener()} and {@code .addOnFailureListener()}.
 *
 * <p>When the stub is declared as an {@code interface} the JVM throws
 * {@code IncompatibleClassChangeError: Found interface … but class was
 * expected} at every call-site inside {@code VisionPlugin.scan_face()},
 * because {@code invokevirtual} requires a class receiver, not an interface.
 *
 * <p>Declaring the stub as an {@code abstract class} makes the bytecode
 * dispatch work correctly. {@link org.godotengine.plugin.vision.fixtures.FakeTask}
 * then {@code extends} (not {@code implements}) this class.
 *
 * @param <T> the result type of the asynchronous operation
 */
public abstract class Task<T> {

	/**
	* Registers a listener that is called when the task succeeds.
	* In tests this is implemented by {@link
	* org.godotengine.plugin.vision.fixtures.FakeTask}, which fires the
	* listener synchronously.
	*/
	public abstract Task<T> addOnSuccessListener(OnSuccessListener<? super T> listener);

	/**
	* Registers a listener that is called when the task fails.
	* In tests this is implemented by {@link
	* org.godotengine.plugin.vision.fixtures.FakeTask}, which fires the
	* listener synchronously.
	*/
	public abstract Task<T> addOnFailureListener(OnFailureListener listener);
}

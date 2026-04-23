//
// © 2026-present https://github.com/cengiz-pz
//

package com.google.mlkit.vision.facemesh;

import com.google.android.gms.tasks.Task;
import com.google.mlkit.vision.common.InputImage;

import java.io.Closeable;
import java.util.List;

/**
 * Test-only stub for {@code com.google.mlkit.vision.facemesh.FaceMeshDetector}.
 *
 * <h3>Why an interface?</h3>
 * The real ML Kit {@code FaceMeshDetector} is an <em>interface</em> (not a
 * class) that also extends {@link Closeable}.  Two things break when this stub
 * is declared as a {@code class} instead:
 *
 * <ol>
 *   <li><b>IncompatibleClassChangeError – "Found class, but interface was
 *       expected"</b>: production bytecode calls {@code process()} via an
 *       <em>invokeinterface</em> instruction.  The JVM throws at runtime when
 *       the receiver is a class-based Mockito subclass proxy, because the
 *       instruction requires an interface type.</li>
 *   <li><b>IncompatibleClassChangeError – "does not implement
 *       java.io.Closeable"</b>: {@code VisionPlugin.onMainDestroy()} casts the
 *       detector to {@code Closeable} in order to call {@code .close()}.  The
 *       cast throws if the stub does not declare the interface.</li>
 * </ol>
 *
 * Declaring the stub as an {@code interface extends Closeable} lets Mockito
 * create a correct JDK dynamic proxy, and lets {@code onMainDestroy()} close
 * it without error.
 */
public interface FaceMeshDetector extends Closeable {

	/**
	* Submits {@code image} for face-mesh detection and returns a
	* {@link Task} that will resolve with the detected {@link FaceMesh} list.
	*
	* <p>In tests, Mockito stubs this to return a {@link
	* org.godotengine.plugin.vision.fixtures.FakeTask}.
	*/
	Task<List<FaceMesh>> process(InputImage image);

	/**
	* Releases resources held by the detector.
	* Declared by {@link Closeable}; overridden here without {@code throws}
	* so call-sites do not need a try/catch.
	*/
	@Override
	void close();
}

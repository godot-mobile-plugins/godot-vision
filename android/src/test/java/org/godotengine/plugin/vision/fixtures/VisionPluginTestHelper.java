//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.fixtures;

import com.google.mlkit.vision.facemesh.FaceMeshDetector;

import org.godotengine.godot.Godot;
import org.godotengine.plugin.vision.VisionPlugin;

import java.lang.reflect.Field;

/**
 * Test-infrastructure helpers for {@link VisionPlugin}.
 *
 * <h3>Why reflection?</h3>
 * {@code VisionPlugin} creates its {@code FaceMeshDetector} lazily inside
 * {@code onGodotSetupCompleted()}, which calls the real ML Kit factory.  In
 * tests we need to replace that detector with a Mockito mock <em>after</em>
 * the constructor but <em>before</em> any {@code scan_face()} call.
 * Reflection is the most transparent way to do this without modifying
 * production code.
 */
public final class VisionPluginTestHelper {

	private VisionPluginTestHelper() {
	}

	// -- Factory ------------------------------------------------------------

	/**
	* Creates a {@link VisionPlugin} whose internal detector has already been
	* replaced with {@code mockDetector}.
	*
	* <p>This calls {@code onGodotSetupCompleted()} (which would normally
	* reach out to ML Kit) and then overwrites the field, so tests get a fully
	* initialised plugin without needing the Android runtime.
	*/
	public static VisionPlugin createWithMockDetector(FaceMeshDetector mockDetector) {
		VisionPlugin plugin = new VisionPlugin(new Godot());
		// onGodotSetupCompleted writes a real detector into the field;
		// we immediately replace it.
		plugin.onGodotSetupCompleted();
		injectDetector(plugin, mockDetector);
		return plugin;
	}

	// -- Injection helpers --------------------------------------------------

	/**
	* Overwrites the private {@code faceMeshDetector} field of {@code plugin}
	* with {@code detector}.
	*
	* @throws RuntimeException if reflection fails (misconfigured test env)
	*/
	public static void injectDetector(VisionPlugin plugin, FaceMeshDetector detector) {
		try {
			Field field = VisionPlugin.class.getDeclaredField("faceMeshDetector");
			field.setAccessible(true);
			field.set(plugin, detector);
		} catch (NoSuchFieldException | IllegalAccessException e) {
			throw new RuntimeException("Could not inject FaceMeshDetector into VisionPlugin", e);
		}
	}

	/**
	* Reads the current value of the private {@code faceMeshDetector} field.
	* Useful for asserting that {@code onMainDestroy()} nulls the field.
	*/
	public static FaceMeshDetector readDetector(VisionPlugin plugin) {
		try {
			Field field = VisionPlugin.class.getDeclaredField("faceMeshDetector");
			field.setAccessible(true);
			return (FaceMeshDetector) field.get(plugin);
		} catch (NoSuchFieldException | IllegalAccessException e) {
			throw new RuntimeException("Could not read faceMeshDetector from VisionPlugin", e);
		}
	}

	/**
	* Clears any previously emitted signals so tests can assert on a clean
	* slate after setup steps that themselves emit signals.
	*/
	public static void clearSignals(VisionPlugin plugin) {
		plugin.emittedSignals.clear();
	}
}

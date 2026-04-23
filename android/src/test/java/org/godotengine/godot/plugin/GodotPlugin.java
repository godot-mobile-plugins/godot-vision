//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.godot.plugin;

import android.app.Activity;
import android.view.View;

import org.godotengine.godot.Godot;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;

/**
 * Test-only stub for {@code GodotPlugin}.
 *
 * <p>The key addition over a bare no-op stub is the {@link #emittedSignals}
 * list, which records every {@link #emitSignal} call so that tests can assert
 * on signal name and payload without needing a live Godot runtime.
 *
 * <h3>Usage in tests</h3>
 * <pre>{@code
 * plugin.scan_face(dict);
 *
 * List<Object[]> signals = plugin.emittedSignals;
 * assertEquals(1, signals.size());
 * assertEquals("face_mesh_failed", signals.get(0)[0]);   // [0] = signal name
 * Dictionary payload = (Dictionary) signals.get(0)[1];   // [1] = first arg
 * }</pre>
 */
public abstract class GodotPlugin {

	/**
	* Ordered record of every {@code emitSignal(name, args…)} invocation.
	* Each entry is {@code Object[]{ signalName, arg0, arg1, … }}.
	*/
	public final List<Object[]> emittedSignals = new ArrayList<>();

	protected final Godot godot;

	public GodotPlugin(Godot godot) {
		this.godot = godot;
	}

	// -- Abstract methods every plugin must implement -----------------------

	public abstract String getPluginName();

	// -- Overridable lifecycle hooks ----------------------------------------

	public Set<SignalInfo> getPluginSignals() {
		return Collections.emptySet();
	}

	public View onMainCreate(Activity activity) {
		return null;
	}

	public void onGodotSetupCompleted() { /* default: no-op */
	}

	public void onMainDestroy() { /* default: no-op */
	}

	// -- Signal emission (records for test assertions) ----------------------

	/**
	* Records the signal emission; does NOT dispatch to a live Godot runtime.
	* Tests inspect {@link #emittedSignals} after calling plugin methods.
	*/
	protected void emitSignal(String signalName, Object... args) {
		Object[] record = new Object[1 + args.length];
		record[0] = signalName;
		System.arraycopy(args, 0, record, 1, args.length);
		emittedSignals.add(record);
	}

	// -- Convenience helpers for tests -------------------------------------

	/** Returns the name of the last emitted signal, or null if none. */
	public String lastSignalName() {
		if (emittedSignals.isEmpty()) {
			return null;
		}
		return (String) emittedSignals.get(emittedSignals.size() - 1)[0];
	}

	/** Returns the first argument of the last emitted signal, cast to T. */
	@SuppressWarnings("unchecked")
	public <T> T lastSignalArg() {
		if (emittedSignals.isEmpty()) {
			return null;
		}
		Object[] last = emittedSignals.get(emittedSignals.size() - 1);
		return last.length > 1 ? (T) last[1] : null;
	}
}

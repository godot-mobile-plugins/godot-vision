//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.godot;

import java.util.LinkedHashMap;

/**
 * Test-only stand-in for Godot's {@code Dictionary} type.
 *
 * <p>The real {@code Dictionary} behaves like a {@code HashMap<String, Object>}.
 * Extending {@link LinkedHashMap} here gives tests predictable iteration order,
 * which makes array-order assertions straightforward.
 */
public class Dictionary extends LinkedHashMap<String, Object> {

	public Dictionary() {
		super();
	}

	// -- Convenience aliases matching the real Godot API surface ------------

	/**
	* Returns the value for {@code key}, or {@code null} if absent.
	* Delegates to the Map API; named to match Godot's GDScript convention.
	*/
	@Override
	public Object get(Object key) {
		return super.get(key);
	}

	/** Returns {@code true} if the key is present (including when value is null). */
	@Override
	public boolean containsKey(Object key) {
		return super.containsKey(key);
	}
}

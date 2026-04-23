//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.godot.plugin;

/**
 * Minimal SignalInfo stub.
 * The real class carries metadata about a Godot signal; here we only need
 * the constructor that records the name so tests can verify declared signals.
 */
public final class SignalInfo {

	private final String name;
	private final Class<?>[] paramTypes;

	public SignalInfo(String name, Class<?>... paramTypes) {
		this.name = name;
		this.paramTypes = paramTypes;
	}

	public String getName() {
		return name;
	}

	public Class<?>[] getParamTypes() {
		return paramTypes;
	}

	@Override
	public String toString() {
		return "SignalInfo{" + name + "}";
	}
}

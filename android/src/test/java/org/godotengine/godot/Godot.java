//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.godot;

import android.app.Activity;

/** Minimal Godot host stub – satisfies the GodotPlugin constructor. */
public class Godot {
	public Activity getActivity() {
		return new Activity();
	}
}

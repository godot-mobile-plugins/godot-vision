//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.godot.plugin;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/** Marker annotation – kept at runtime so reflection-based checks still work. */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface UsedByGodot {
}

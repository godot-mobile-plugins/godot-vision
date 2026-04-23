//
// © 2026-present https://github.com/cengiz-pz
//

#import <Foundation/Foundation.h>

// Stub out the Godot plugin registry.
// These must have C++ linkage to match the mangled symbols referenced by
// Godot's static library (libgodot.ios.template_debug.arm64.simulator.a).
// Do NOT wrap in extern "C" – that produces _godot_apple_embedded_plugins_*
// (C linkage) which the linker cannot match against the C++ call sites.
void godot_apple_embedded_plugins_initialize(void) {}
void godot_apple_embedded_plugins_deinitialize(void) {}

// SDL stubs – Godot's iOS glue pulls these in on simulator builds.
// SDL_Is* are plain C functions, so extern "C" is correct here.
extern "C" {
    int SDL_IsAppleTV(void) { return 0; }
    int SDL_IsIPad(void)    { return 0; }
}

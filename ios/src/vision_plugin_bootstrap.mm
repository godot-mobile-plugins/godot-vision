//
// © 2026-present https://github.com/cengiz-pz
//

#import <Foundation/Foundation.h>

#import "vision_logger.h"
#import "vision_plugin.h"
#import "vision_plugin_bootstrap.h"

#import "core/config/engine.h"

VisionPlugin *vision_plugin;

void vision_plugin_init() {
	os_log_debug(vision_log, "VisionPlugin: Initializing plugin at timestamp: %f",
			[[NSDate date] timeIntervalSince1970]);

	vision_plugin = memnew(VisionPlugin);
	Engine::get_singleton()->add_singleton(Engine::Singleton("VisionPlugin", vision_plugin));
	os_log_debug(vision_log, "VisionPlugin: Singleton registered");
}

void vision_plugin_deinit() {
	os_log_debug(vision_log, "VisionPlugin: Deinitializing plugin");
	vision_log = NULL; // Prevent accidental reuse

	if (vision_plugin) {
		memdelete(vision_plugin);
		vision_plugin = nullptr;
	}
}

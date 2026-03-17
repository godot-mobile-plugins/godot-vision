//
// © 2026-present https://github.com/cengiz-pz
//

#import "vision_logger.h"

// Define and initialize the shared os_log_t instance
os_log_t vision_log;

__attribute__((constructor)) // Automatically runs at program startup
static void initialize_vision_log(void) {
	vision_log = os_log_create("org.godotengine.plugin.vision", "VisionPlugin");
}

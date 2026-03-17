//
// © 2026-present https://github.com/cengiz-pz
//

#import "vision_plugin.h"

#import "vision_plugin-Swift.h"

#import "vision_logger.h"

const String TEMPLATE_READY_SIGNAL = "template_ready";
// TODO: Define all signals

VisionPlugin *VisionPlugin::instance = NULL;

void VisionPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_vision"), &VisionPlugin::get_vision);
	// TODO: Register all methods

	ADD_SIGNAL(MethodInfo(TEMPLATE_READY_SIGNAL, PropertyInfo(Variant::DICTIONARY, "a_dict")));
	// TODO: Register all signals
}

Array VisionPlugin::get_vision() {
	os_log_debug(vision_log, "::get_vision()");

	Array godot_array = Array();

	return godot_array;
}

VisionPlugin::VisionPlugin() {
	os_log_debug(vision_log, "Plugin singleton constructor");

	ERR_FAIL_COND(instance != NULL);

	instance = this;
}

VisionPlugin::~VisionPlugin() {
	os_log_debug(vision_log, "Plugin singleton destructor");

	if (instance == this) {
		instance = nullptr;
	}
}

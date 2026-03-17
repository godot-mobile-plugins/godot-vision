//
// © 2026-present https://github.com/cengiz-pz
//

#ifndef vision_plugin_h
#define vision_plugin_h

#import <Foundation/Foundation.h>

#include "core/object/class_db.h"
#include "core/object/object.h"

@class Vision;

extern const String TEMPLATE_READY_SIGNAL;
// TODO: Declare all signals

class VisionPlugin : public Object {
	GDCLASS(VisionPlugin, Object);

private:
	static VisionPlugin *instance; // Singleton instance

	static void _bind_methods();

public:
	Array get_vision();
	// TODO: Declare all methods

	VisionPlugin();
	~VisionPlugin();
};

#endif /* vision_plugin_h */

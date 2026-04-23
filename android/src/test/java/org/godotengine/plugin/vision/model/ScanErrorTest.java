//
// © 2026-present https://github.com/cengiz-pz
//

package org.godotengine.plugin.vision.model;

import org.godotengine.godot.Dictionary;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests for {@link ScanError}.
 *
 * Covers:
 *  – {@code buildRawData()} includes both "code" and "description" keys
 *  – every {@link ScanError.Code} variant survives the round-trip
 *  – null description does not cause NPE
 *  – dictionary keys match the constants expected by GDScript consumers
 */
@DisplayName("ScanError")
class ScanErrorTest {

	@Test
	@DisplayName("buildRawData() contains 'code' key")
	void containsCodeKey() {
		ScanError err = new ScanError(ScanError.Code.SCANNER_FAILURE, "test");
		Dictionary dict = err.buildRawData();
		assertTrue(dict.containsKey("code"), "Dict must contain 'code'");
	}

	@Test
	@DisplayName("buildRawData() contains 'description' key")
	void containsDescriptionKey() {
		ScanError err = new ScanError(ScanError.Code.INVALID_IMAGE, "bad image");
		Dictionary dict = err.buildRawData();
		assertTrue(dict.containsKey("description"), "Dict must contain 'description'");
	}

	@Test
	@DisplayName("description value matches the string passed to constructor")
	void descriptionValue() {
		String msg = "Detector not initialised";
		ScanError err = new ScanError(ScanError.Code.INTERNAL_ERROR, msg);
		Dictionary dict = err.buildRawData();
		assertEquals(msg, dict.get("description"));
	}

	@ParameterizedTest(name = "code = {0}")
	@EnumSource(ScanError.Code.class)
	@DisplayName("all Code variants are preserved in the dictionary")
	void allCodesRoundTrip(ScanError.Code code) {
		ScanError err = new ScanError(code, "msg");
		Dictionary dict = err.buildRawData();
		assertEquals(code, dict.get("code"),
				"Expected code " + code + " but got " + dict.get("code"));
	}

	@Test
	@DisplayName("null description is stored without NPE")
	void nullDescriptionDoesNotThrow() {
		ScanError err = new ScanError(ScanError.Code.NONE, null);
		assertDoesNotThrow(err::buildRawData);
	}

	@Test
	@DisplayName("buildRawData() returns a new Dictionary on each call")
	void eachCallReturnsNewInstance() {
		ScanError err = new ScanError(ScanError.Code.NO_CODE_DETECTED, "none");
		assertNotSame(err.buildRawData(), err.buildRawData());
	}

	@Test
	@DisplayName("NO_CODE_DETECTED code is distinct from NONE")
	void noCodeDetectedDistinctFromNone() {
		assertNotEquals(ScanError.Code.NONE, ScanError.Code.NO_CODE_DETECTED);
	}
}

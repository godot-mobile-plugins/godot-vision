//
// © 2026-present https://github.com/cengiz-pz
//

package android.util;

/**
 * Log stub – prints to stdout so test output remains readable while keeping
 * the method signatures identical to the real android.util.Log class.
 */
public final class Log {

	private Log() {
	}

	public static int d(String tag, String msg) {
		System.out.println("[D/" + tag + "] " + msg);
		return 0;
	}

	public static int e(String tag, String msg) {
		System.err.println("[E/" + tag + "] " + msg);
		return 0;
	}

	public static int e(String tag, String msg, Throwable tr) {
		System.err.println("[E/" + tag + "] " + msg + " – " + tr);
		return 0;
	}

	public static int i(String tag, String msg) {
		System.out.println("[I/" + tag + "] " + msg);
		return 0;
	}

	public static int w(String tag, String msg) {
		System.out.println("[W/" + tag + "] " + msg);
		return 0;
	}
}

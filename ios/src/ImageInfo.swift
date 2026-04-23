//
// © 2026-present https://github.com/cengiz-pz
//
// ImageInfo.swift
//
// iOS counterpart of ImageInfo.java.
//
// Represents the image dictionary sent from GDScript:
//   {
//     "buffer":     PackedByteArray  – raw RGBA8 pixels
//     "width":      int
//     "height":     int
//     "format":     int              – Godot Image.FORMAT_RGBA8 == 4
//     "has_mipmaps": bool
//   }
//
// Provides a convenience factory to convert the raw RGBA8 buffer into a
// UIImage that MediaPipe Tasks Vision can accept.
//

import CoreGraphics
import Foundation
import UIKit

struct ImageInfo {

	// -----------------------------------------------------------------------
	// Constants
	// -----------------------------------------------------------------------

	static let formatRGBA8: Int = 4   // Godot Image.FORMAT_RGBA8

	// -----------------------------------------------------------------------
	// makeUIImage(from:width:height:)
	//
	// Creates a UIImage from a raw RGBA8 (packed, no padding) byte buffer.
	//
	// Godot's Image.get_data() with FORMAT_RGBA8 gives sequential RGBA bytes,
	// one byte per channel, row-major.  CGImage with CGBitmapInfo.byteOrder32Big
	// and .last alpha interprets the memory the same way.
	//
	// Returns nil if CGImage construction fails (malformed dimensions/data).
	// -----------------------------------------------------------------------
	static func makeUIImage(from buffer: Data, width: Int, height: Int) -> UIImage? {
		let bitsPerComponent = 8
		let bytesPerPixel    = 4        // RGBA
		let bytesPerRow      = bytesPerPixel * width
		let expectedSize     = bytesPerRow * height

		guard buffer.count >= expectedSize, width > 0, height > 0 else {
			return nil
		}

		let colorSpace = CGColorSpaceCreateDeviceRGB()

		// CGBitmapInfo: .byteOrder32Big + .last means RGBA byte layout,
		// which is exactly Godot's FORMAT_RGBA8.
		let bitmapInfo = CGBitmapInfo(rawValue:
			CGBitmapInfo.byteOrder32Big.rawValue |
			CGImageAlphaInfo.last.rawValue)

		guard let dataProvider = buffer.withUnsafeBytes({ rawBuffer -> CGDataProvider? in
			guard let baseAddress = rawBuffer.baseAddress else { return nil }
			return CGDataProvider(dataInfo: nil,
								data: baseAddress,
								size: buffer.count,
								releaseData: { _, _, _ in })
		}) else {
			return nil
		}

		guard let cgImage = CGImage(
			width: width,
			height: height,
			bitsPerComponent: bitsPerComponent,
			bitsPerPixel: bitsPerComponent * bytesPerPixel,
			bytesPerRow: bytesPerRow,
			space: colorSpace,
			bitmapInfo: bitmapInfo,
			provider: dataProvider,
			decode: nil,
			shouldInterpolate: false,
			intent: .defaultIntent
		) else {
			return nil
		}

		return UIImage(cgImage: cgImage)
	}

	// -----------------------------------------------------------------------
	// Note on format
	//
	// The "format" field in the GDScript dictionary (Godot Image.FORMAT_RGBA8
	// == 4) is not checked here; this function always treats the buffer as
	// RGBA8.  When adding support for additional formats (e.g. RGB8),
	// inspect the format field before selecting bitmapInfo / bytesPerPixel.
	// -----------------------------------------------------------------------
}

import AppKit

struct ImageDocument {
    let image: NSImage
    let sourceURL: URL

    /// Returns the dimensions of the largest bitmap representation in pixels.
    /// Non-bitmap images fall back to their logical image size.
    var pixelSize: CGSize {
        let bitmapRepresentations = image.representations.compactMap { $0 as? NSBitmapImageRep }
            .filter { $0.pixelsWide > 0 && $0.pixelsHigh > 0 }

        guard let largestBitmap = bitmapRepresentations.max(by: {
            Double($0.pixelsWide) * Double($0.pixelsHigh)
                < Double($1.pixelsWide) * Double($1.pixelsHigh)
        }) else {
            return image.size
        }

        return CGSize(width: largestBitmap.pixelsWide, height: largestBitmap.pixelsHigh)
    }
}

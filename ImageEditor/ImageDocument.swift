import AppKit

struct ImageDocument {
    let image: NSImage
    let sourceURL: URL

    /// Returns the largest bitmap representation by pixel area.
    var bitmapRepresentation: NSBitmapImageRep? {
        let bitmapRepresentations = image.representations.compactMap { $0 as? NSBitmapImageRep }
            .filter { $0.pixelsWide > 0 && $0.pixelsHigh > 0 }

        return bitmapRepresentations.max(by: {
            Double($0.pixelsWide) * Double($0.pixelsHigh)
                < Double($1.pixelsWide) * Double($1.pixelsHigh)
        })
    }

    /// Returns pixel dimensions for bitmap images, falling back to logical size
    /// for images without a bitmap representation.
    var pixelSize: CGSize {
        guard let bitmapRepresentation else {
            return image.size
        }

        return CGSize(width: bitmapRepresentation.pixelsWide, height: bitmapRepresentation.pixelsHigh)
    }
}

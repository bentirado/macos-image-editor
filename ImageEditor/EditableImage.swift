import AppKit

/// Owns an editable bitmap copy so pixel operations can leave the source image untouched.
final class EditableImage {
    private(set) var bitmap: NSBitmapImageRep

    var pixelSize: CGSize {
        CGSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
    }

    /// Creates an independent bitmap copy from an image document.
    init?(document: ImageDocument) {
        guard let sourceBitmap = document.bitmapRepresentation,
              let editableBitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: sourceBitmap.pixelsWide,
                pixelsHigh: sourceBitmap.pixelsHigh,
                bitsPerSample: sourceBitmap.bitsPerSample,
                samplesPerPixel: sourceBitmap.samplesPerPixel,
                hasAlpha: sourceBitmap.hasAlpha,
                isPlanar: sourceBitmap.isPlanar,
                colorSpaceName: sourceBitmap.colorSpaceName,
                bitmapFormat: sourceBitmap.bitmapFormat,
                bytesPerRow: sourceBitmap.bytesPerRow,
                bitsPerPixel: sourceBitmap.bitsPerPixel
              ),
              Self.copyPixelData(from: sourceBitmap, to: editableBitmap) else {
            return nil
        }

        editableBitmap.size = sourceBitmap.size
        self.bitmap = editableBitmap
    }

    private static func copyPixelData(
        from source: NSBitmapImageRep,
        to destination: NSBitmapImageRep
    ) -> Bool {
        guard source.numberOfPlanes > 0,
              source.numberOfPlanes == destination.numberOfPlanes,
              source.numberOfPlanes <= 5 else {
            return false
        }

        var sourcePlanes = [UnsafeMutablePointer<UInt8>?](repeating: nil, count: 5)
        var destinationPlanes = [UnsafeMutablePointer<UInt8>?](repeating: nil, count: 5)

        let sourcePlanesLoaded = sourcePlanes.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return false
            }
            source.getBitmapDataPlanes(baseAddress)
            return true
        }
        let destinationPlanesLoaded = destinationPlanes.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return false
            }
            destination.getBitmapDataPlanes(baseAddress)
            return true
        }

        guard sourcePlanesLoaded, destinationPlanesLoaded else {
            return false
        }

        for plane in 0..<source.numberOfPlanes {
            guard let sourceData = sourcePlanes[plane],
                  let destinationData = destinationPlanes[plane] else {
                return false
            }

            destinationData.update(from: sourceData, count: source.bytesPerPlane)
        }

        return true
    }
}

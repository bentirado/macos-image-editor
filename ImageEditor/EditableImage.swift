import AppKit

/// The actual pixel displacement applied to an image region.
struct PixelOffset: Equatable {
    let x: Int
    let y: Int
}

/// Owns an editable bitmap copy so pixel operations can leave the source image untouched.
final class EditableImage {
    private(set) var bitmap: NSBitmapImageRep

    var pixelSize: CGSize {
        CGSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
    }

    /// Moves a selected pixel region, clears its source, and keeps the full
    /// destination region inside the bitmap. Fractional selection edges round
    /// outward so every touched pixel is included. Returns `nil` for invalid
    /// regions or unsupported floating-point bitmap formats.
    func movePixels(in selection: Selection, byX deltaX: Int, byY deltaY: Int) -> PixelOffset? {
        let imageWidth = bitmap.pixelsWide
        let imageHeight = bitmap.pixelsHigh
        let selectionMaxX = selection.x + selection.geometry.width
        let selectionMaxY = selection.y + selection.geometry.height

        guard selection.x.isFinite,
              selection.y.isFinite,
              selectionMaxX.isFinite,
              selectionMaxY.isFinite else {
            return nil
        }

        let sourceX = Int(min(max(floor(selection.x), 0), Double(imageWidth)))
        let sourceY = Int(min(max(floor(selection.y), 0), Double(imageHeight)))
        let sourceMaxX = Int(min(max(ceil(selectionMaxX), 0), Double(imageWidth)))
        let sourceMaxY = Int(min(max(ceil(selectionMaxY), 0), Double(imageHeight)))
        let regionWidth = sourceMaxX - sourceX
        let regionHeight = sourceMaxY - sourceY

        guard regionWidth > 0,
              regionHeight > 0,
              regionWidth <= Int.max / regionHeight else {
            return nil
        }

        let offset = PixelOffset(
            x: min(max(deltaX, -sourceX), imageWidth - sourceMaxX),
            y: min(max(deltaY, -sourceY), imageHeight - sourceMaxY)
        )
        guard offset.x != 0 || offset.y != 0 else {
            return offset
        }

        guard !bitmap.bitmapFormat.contains(.floatingPointSamples),
              bitmap.hasAlpha || bitmap.bitsPerSample <= 16,
              ensureAlphaChannel() else {
            return nil
        }

        let samplesPerPixel = bitmap.samplesPerPixel
        let pixelCount = regionWidth * regionHeight
        guard samplesPerPixel > 0, pixelCount <= Int.max / samplesPerPixel else {
            return nil
        }

        var pixelData = [Int](repeating: 0, count: pixelCount * samplesPerPixel)
        let pixelsRead = pixelData.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return false
            }

            for row in 0..<regionHeight {
                for column in 0..<regionWidth {
                    let pixelOffset = (row * regionWidth + column) * samplesPerPixel
                    bitmap.getPixel(
                        baseAddress.advanced(by: pixelOffset),
                        atX: sourceX + column,
                        y: sourceY + row
                    )
                }
            }
            return true
        }
        guard pixelsRead else {
            return nil
        }

        var clearedPixel = [Int](repeating: 0, count: samplesPerPixel)
        let sourceCleared = clearedPixel.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return false
            }

            for row in 0..<regionHeight {
                for column in 0..<regionWidth {
                    bitmap.setPixel(baseAddress, atX: sourceX + column, y: sourceY + row)
                }
            }
            return true
        }
        guard sourceCleared else {
            return nil
        }

        let pixelsWritten = pixelData.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return false
            }

            for row in 0..<regionHeight {
                for column in 0..<regionWidth {
                    let pixelOffset = (row * regionWidth + column) * samplesPerPixel
                    bitmap.setPixel(
                        baseAddress.advanced(by: pixelOffset),
                        atX: sourceX + offset.x + column,
                        y: sourceY + offset.y + row
                    )
                }
            }
            return true
        }
        guard pixelsWritten else {
            return nil
        }

        return offset
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
              source.bytesPerPlane == destination.bytesPerPlane,
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

    /// Converts opaque bitmap data into a working RGBA bitmap before clearing pixels.
    private func ensureAlphaChannel() -> Bool {
        guard !bitmap.hasAlpha else {
            return true
        }

        let bitsPerSample = max(8, min(bitmap.bitsPerSample, 16))
        guard let alphaBitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: bitmap.pixelsWide,
            pixelsHigh: bitmap.pixelsHigh,
            bitsPerSample: bitsPerSample,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return false
        }

        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let color = bitmap.colorAt(x: x, y: y) else {
                    return false
                }
                alphaBitmap.setColor(color, atX: x, y: y)
            }
        }

        alphaBitmap.size = bitmap.size
        bitmap = alphaBitmap
        return true
    }
}

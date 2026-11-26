
import Foundation


/// Describes the image's position and dimensions when displayed
/// proportionally within a canvas, and converts points between image and
/// AppKit canvas coordinates. Image points use a top-left origin; canvas
/// points use AppKit's bottom-left origin.
struct ImageDisplayGeometry {

    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let scale: Double

    /// Calculates the centered display rectangle for an image.
    ///
    /// - Parameters:
    ///   - canvasWidth: Width of the available canvas.
    ///   - canvasHeight: Height of the available canvas.
    ///   - imageWidth: Original image width.
    ///   - imageHeight: Original image height.
    /// - Returns: A display geometry, or nil for invalid dimensions.
    init?(
        canvasWidth: Double,
        canvasHeight: Double,
        imageWidth: Double,
        imageHeight: Double
    ) {
        guard canvasWidth > 0,
              canvasHeight > 0,
              imageWidth > 0,
              imageHeight > 0,
              canvasWidth.isFinite,
              canvasHeight.isFinite,
              imageWidth.isFinite,
              imageHeight.isFinite else {
            return nil
        }

        let widthRatio = canvasWidth / imageWidth
        let heightRatio = canvasHeight / imageHeight

        let scale = min(widthRatio, heightRatio, 1.0)

        let displayedWidth = imageWidth * scale
        let displayedHeight = imageHeight * scale

        self.scale = scale
        self.width = displayedWidth
        self.height = displayedHeight

        self.x = (canvasWidth - displayedWidth) / 2
        self.y = (canvasHeight - displayedHeight) / 2
    }

    /// Converts an image-space point into the displayed canvas rectangle.
    /// Points on the image boundary are accepted.
    func canvasPoint(fromImagePoint point: CGPoint) -> CGPoint {
        CGPoint(
            x: x + Double(point.x) * scale,
            y: y + height - Double(point.y) * scale
        )
    }

    /// Converts an AppKit canvas point into image space.
    ///
    /// Returns `nil` when the point is outside the displayed image, including
    /// letterboxed margins. Points on the displayed image boundary are accepted.
    func imagePoint(fromCanvasPoint point: CGPoint) -> CGPoint? {
        let canvasX = Double(point.x)
        let canvasY = Double(point.y)

        guard canvasX.isFinite,
              canvasY.isFinite,
              canvasX >= x,
              canvasX <= x + width,
              canvasY >= y,
              canvasY <= y + height else {
            return nil
        }

        return CGPoint(
            x: (canvasX - x) / scale,
            y: (y + height - canvasY) / scale
        )
    }

    /// Converts a canvas point into image space, clamping it to the image edge
    /// when it falls outside the displayed image.
    func clampedImagePoint(fromCanvasPoint point: CGPoint) -> CGPoint? {
        let canvasX = Double(point.x)
        let canvasY = Double(point.y)

        guard canvasX.isFinite, canvasY.isFinite else {
            return nil
        }

        let clampedPoint = CGPoint(
            x: min(max(canvasX, x), x + width),
            y: min(max(canvasY, y), y + height)
        )
        return imagePoint(fromCanvasPoint: clampedPoint)
    }
}

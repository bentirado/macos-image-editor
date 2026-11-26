import Foundation

/// A selection boundary whose position and dimensions are in image space.
/// The origin is at the image's top-left corner.
struct Selection {
    
    let x: Double
    let y: Double
    let geometry: SelectionGeometry

    /// Returns whether an image-space point lies inside or on this boundary.
    func contains(imagePoint point: CGPoint) -> Bool {
        let pointX = Double(point.x)
        let pointY = Double(point.y)

        return pointX >= x
            && pointX <= x + geometry.width
            && pointY >= y
            && pointY <= y + geometry.height
    }
}

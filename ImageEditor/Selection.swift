import Foundation

/// The four corner handles that can resize a selection boundary.
enum SelectionCorner: CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

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

    /// Returns the image-space position of a resize corner.
    func point(at corner: SelectionCorner) -> CGPoint {
        switch corner {
        case .topLeft:
            CGPoint(x: x, y: y)
        case .topRight:
            CGPoint(x: x + geometry.width, y: y)
        case .bottomLeft:
            CGPoint(x: x, y: y + geometry.height)
        case .bottomRight:
            CGPoint(x: x + geometry.width, y: y + geometry.height)
        }
    }

    /// Resizes this boundary from a corner while keeping the opposite corner fixed.
    func resized(
        from corner: SelectionCorner,
        to point: CGPoint,
        maintainAspectRatio: Bool
    ) -> Selection? {
        let anchor: CGPoint
        let adjustsLeftEdge: Bool
        let adjustsTopEdge: Bool

        switch corner {
        case .topLeft:
            anchor = self.point(at: .bottomRight)
            adjustsLeftEdge = true
            adjustsTopEdge = true
        case .topRight:
            anchor = self.point(at: .bottomLeft)
            adjustsLeftEdge = false
            adjustsTopEdge = true
        case .bottomLeft:
            anchor = self.point(at: .topRight)
            adjustsLeftEdge = true
            adjustsTopEdge = false
        case .bottomRight:
            anchor = self.point(at: .topLeft)
            adjustsLeftEdge = false
            adjustsTopEdge = false
        }

        let pointX = Double(point.x)
        let pointY = Double(point.y)
        let anchorX = Double(anchor.x)
        let anchorY = Double(anchor.y)

        guard (adjustsLeftEdge ? pointX < anchorX : pointX > anchorX),
              (adjustsTopEdge ? pointY < anchorY : pointY > anchorY),
              let resizedGeometry = geometry.resized(
                toWidth: abs(pointX - anchorX),
                height: abs(pointY - anchorY),
                maintainAspectRatio: maintainAspectRatio
              ) else {
            return nil
        }

        let resizedX = adjustsLeftEdge ? anchorX - resizedGeometry.width : anchorX
        let resizedY = adjustsTopEdge ? anchorY - resizedGeometry.height : anchorY

        return Selection(x: resizedX, y: resizedY, geometry: resizedGeometry)
    }
}

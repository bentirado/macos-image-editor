import Foundation

struct SelectionGeometry {

    let width: Double
    let height: Double
    
    init?(width: Double, height: Double) {
        guard width > 0, height > 0, width.isFinite, height.isFinite else {
            return nil
        }
        
        self.width = width
        self.height = height
    }

    func resized(
        toWidth newWidth: Double,
        maintainAspectRatio: Bool
    ) -> SelectionGeometry? {

        let requestedHeight = maintainAspectRatio
            ? newWidth / (width / height)
            : height

        return resized(
            toWidth: newWidth,
            height: requestedHeight,
            maintainAspectRatio: maintainAspectRatio
        )
    }

    /// Resizes the selection to fit within the requested dimensions.
    /// When preserving the ratio, the resulting size is the largest that fits
    /// inside the requested width and height.
    func resized(
        toWidth newWidth: Double,
        height newHeight: Double,
        maintainAspectRatio: Bool
    ) -> SelectionGeometry? {

        guard newWidth > 0,
              newHeight > 0,
              newWidth.isFinite,
              newHeight.isFinite else {
            return nil
        }

        guard maintainAspectRatio else {
            return SelectionGeometry(width: newWidth, height: newHeight)
        }

        let scale = min(newWidth / width, newHeight / height)

        return SelectionGeometry(	
            width: width * scale,
            height: height * scale
        )
    }
}

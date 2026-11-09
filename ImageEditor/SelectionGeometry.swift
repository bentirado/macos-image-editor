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

        // Reject invalid dimensions
        guard newWidth > 0, newWidth.isFinite else {
            return nil
        }
        
        // Resize without preserving aspect ratio
        guard maintainAspectRatio else {
            return SelectionGeometry(width: newWidth, height: height)
        }

        // Calculate new dimensions
        let aspectRatio = width / height
        let newHeight = newWidth / aspectRatio

        return SelectionGeometry(	
            width: newWidth,
            height: newHeight
        )
    }
}

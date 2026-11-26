import Foundation

final class SelectionManager {
    
    private(set) var selection: Selection?
    
    func createSelection(
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) {
        guard let geometry = SelectionGeometry(width: width, height: height) else {
            return
        }
        
        selection = Selection(x: x, y: y, geometry: geometry)
    }
    
    func moveSelection(toX x: Double, y: Double) {
        guard let currentSelection = selection else {
            return
        }
        
        selection = Selection(x: x, y: y, geometry: currentSelection.geometry)
    }

    /// Moves the selection while keeping its full boundary inside the image.
    func moveSelection(
        toX x: Double,
        y: Double,
        clampedToImageWidth imageWidth: Double,
        height imageHeight: Double
    ) {
        guard let currentSelection = selection,
              x.isFinite,
              y.isFinite,
              imageWidth.isFinite,
              imageHeight.isFinite,
              imageWidth > 0,
              imageHeight > 0,
              currentSelection.geometry.width <= imageWidth,
              currentSelection.geometry.height <= imageHeight else {
            return
        }

        let clampedX = min(max(x, 0), imageWidth - currentSelection.geometry.width)
        let clampedY = min(max(y, 0), imageHeight - currentSelection.geometry.height)
        selection = Selection(x: clampedX, y: clampedY, geometry: currentSelection.geometry)
    }
    
    func clearSelection() {
        selection = nil
    }
    
    func resizeSelection(
        toWidth newWidth: Double,
        maintainAspectRatio: Bool
    ) {
        guard let currentSelection = selection,
              let resizedGeometry = currentSelection.geometry.resized(toWidth: newWidth, maintainAspectRatio: maintainAspectRatio) else {
            return
        }
        
        selection = Selection(x: currentSelection.x, y: currentSelection.y, geometry: resizedGeometry
        )
    }

    /// Updates the selection dimensions while preserving its image-space origin.
    func resizeSelection(toWidth newWidth: Double, height newHeight: Double) {
        guard let currentSelection = selection,
              let resizedGeometry = currentSelection.geometry.resized(
                toWidth: newWidth,
                height: newHeight,
                maintainAspectRatio: false
              ) else {
            return
        }

        selection = Selection(
            x: currentSelection.x,
            y: currentSelection.y,
            geometry: resizedGeometry
        )
    }
}


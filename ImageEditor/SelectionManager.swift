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
    
    func clearSelection() {
        selection = nil
    }
}


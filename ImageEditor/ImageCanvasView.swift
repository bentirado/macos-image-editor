import AppKit

final class ImageCanvasView: NSView {
    
    private let selectionManager = SelectionManager()
    private var dragStartPoint: NSPoint?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
        
        guard let selection = selectionManager.selection else {
            let message = "Click and drag to create a selection"
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            
            let size = message.size(withAttributes: attributes)
            
            let point = NSPoint(
                x: (bounds.width - size.width) / 2,
                y: (bounds.height - size.height) / 2
            )
            
            message.draw(at: point, withAttributes: attributes)
            return
        }
        
        let rect = NSRect(
            x: selection.x,
            y: selection.y,
            width: selection.geometry.width,
            height: selection.geometry.height
        )
        
        let path = NSBezierPath(rect: rect)
        
        NSColor.controlAccentColor.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    override func mouseDown(with event: NSEvent) {
        dragStartPoint = convert (
            event.locationInWindow,
            from: nil
        )
    }
    
    override func mouseDragged(with event: NSEvent) {
        let currentPoint = convert (
            event.locationInWindow,
            from: nil
        )
        
        updateSelection(to: currentPoint)
    }
    
    override func mouseUp(with event: NSEvent) {
        let currentPoint = convert(
            event.locationInWindow,
            from: nil
        )
        
        updateSelection(to: currentPoint)
        dragStartPoint = nil
    }
    
    private func updateSelection(to currentPoint: NSPoint) {
        guard let startPoint = dragStartPoint else {
            return
        }
        
        let x = min(startPoint.x, currentPoint.x)
        let y = min(startPoint.y, currentPoint.y)

        let width = abs(currentPoint.x - startPoint.x)
        let height = abs(currentPoint.y - startPoint.y)
        
        guard width > 0, height > 0 else {
            return
        }
        
        selectionManager.createSelection(x: Double(x), y: Double(y), width: Double(width), height: Double(height)
        )
        
        needsDisplay = true
    }
}

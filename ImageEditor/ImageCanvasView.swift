import AppKit

/// Draws the image and selection boundary and translates pointer input into
/// image-space selection geometry.
final class ImageCanvasView: NSView {
    
    var image: NSImage? {
        didSet {
            needsDisplay = true
        }
    }
    
    private let selectionManager = SelectionManager()
    private var dragStartPoint: CGPoint?

    private var displayGeometry: ImageDisplayGeometry? {
        guard let image else {
            return nil
        }

        return ImageDisplayGeometry(
            canvasWidth: bounds.width,
            canvasHeight: bounds.height,
            imageWidth: image.size.width,
            imageHeight: image.size.height
        )
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.controlBackgroundColor.setFill()
        dirtyRect.fill()
        
        if let image,
           let geometry = displayGeometry {
            
            let imageRect = NSRect(
                x: geometry.x,
                y: geometry.y,
                width: geometry.width,
                height: geometry.height
            )
            
            image.draw(
                in: imageRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
        }
        
        guard let selection = selectionManager.selection else {
            if image == nil {
                let message = "Open an image to get started"

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
            }

            return
        }

        guard let geometry = displayGeometry else {
            return
        }

        let topLeft = geometry.canvasPoint(fromImagePoint: CGPoint(x: selection.x, y: selection.y))
        let bottomRight = geometry.canvasPoint(
            fromImagePoint: CGPoint(
                x: selection.x + selection.geometry.width,
                y: selection.y + selection.geometry.height
            )
        )
        let rect = NSRect(
            x: topLeft.x,
            y: bottomRight.y,
            width: bottomRight.x - topLeft.x,
            height: topLeft.y - bottomRight.y
        )

        let path = NSBezierPath(rect: rect)

        NSColor.controlAccentColor.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let geometry = displayGeometry else {
            dragStartPoint = nil
            return
        }

        let canvasPoint = convert(event.locationInWindow, from: nil)
        dragStartPoint = geometry.imagePoint(fromCanvasPoint: canvasPoint)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let geometry = displayGeometry else {
            return
        }

        let canvasPoint = convert(event.locationInWindow, from: nil)
        guard let imagePoint = geometry.clampedImagePoint(fromCanvasPoint: canvasPoint) else {
            return
        }

        updateSelection(to: imagePoint)
    }
    
    override func mouseUp(with event: NSEvent) {
        defer { dragStartPoint = nil }

        guard let geometry = displayGeometry else {
            return
        }

        let canvasPoint = convert(event.locationInWindow, from: nil)
        guard let imagePoint = geometry.clampedImagePoint(fromCanvasPoint: canvasPoint) else {
            return
        }

        updateSelection(to: imagePoint)
    }
    
    private func updateSelection(to currentPoint: CGPoint) {
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
        
        selectionManager.createSelection(
            x: Double(x),
            y: Double(y),
            width: Double(width),
            height: Double(height)
        )
        
        needsDisplay = true
    }
}

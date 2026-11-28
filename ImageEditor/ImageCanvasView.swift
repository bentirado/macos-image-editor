import AppKit

/// Draws the image and selection boundary and translates pointer input into
/// image-space selection geometry.
final class ImageCanvasView: NSView {
    
    var image: NSImage? {
        didSet {
            needsDisplay = true
        }
    }

    var imagePixelSize: CGSize? {
        didSet {
            needsDisplay = true
        }
    }
    
    private let selectionManager = SelectionManager()
    private enum DragOperation {
        case create(startPoint: CGPoint)
        case move(startPoint: CGPoint, selectionOrigin: CGPoint)
        case resize(corner: SelectionCorner, startPoint: CGPoint, originalSelection: Selection)
    }

    private let resizeHandleSize: CGFloat = 8
    private var dragOperation: DragOperation?

    private var displayGeometry: ImageDisplayGeometry? {
        guard image != nil, let imagePixelSize else {
            return nil
        }

        return ImageDisplayGeometry(
            canvasWidth: bounds.width,
            canvasHeight: bounds.height,
            imageWidth: imagePixelSize.width,
            imageHeight: imagePixelSize.height
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

        for corner in SelectionCorner.allCases {
            let handleRect = resizeHandleRect(for: selection, at: corner, using: geometry)
            NSColor.controlBackgroundColor.setFill()
            NSBezierPath(rect: handleRect).fill()
            NSColor.controlAccentColor.setStroke()
            NSBezierPath(rect: handleRect).stroke()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let geometry = displayGeometry else {
            dragOperation = nil
            return
        }

        let canvasPoint = convert(event.locationInWindow, from: nil)
        guard let imagePoint = geometry.imagePoint(fromCanvasPoint: canvasPoint) else {
            dragOperation = nil
            return
        }

        if let selection = selectionManager.selection {
            if let corner = resizeCorner(at: canvasPoint, for: selection, using: geometry) {
                dragOperation = .resize(corner: corner, startPoint: imagePoint, originalSelection: selection)
            } else if selection.contains(imagePoint: imagePoint) {
                dragOperation = .move(
                    startPoint: imagePoint,
                    selectionOrigin: CGPoint(x: selection.x, y: selection.y)
                )
            } else {
                dragOperation = .create(startPoint: imagePoint)
            }
        } else {
            dragOperation = .create(startPoint: imagePoint)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let geometry = displayGeometry else {
            return
        }

        let canvasPoint = convert(event.locationInWindow, from: nil)
        guard let imagePoint = geometry.clampedImagePoint(fromCanvasPoint: canvasPoint) else {
            return
        }

        updateSelection(
            to: imagePoint,
            using: geometry,
            maintainAspectRatio: event.modifierFlags.contains(.shift)
        )
    }
    
    override func mouseUp(with event: NSEvent) {
        defer { dragOperation = nil }

        guard let geometry = displayGeometry else {
            return
        }

        let canvasPoint = convert(event.locationInWindow, from: nil)
        guard let imagePoint = geometry.clampedImagePoint(fromCanvasPoint: canvasPoint) else {
            return
        }

        updateSelection(
            to: imagePoint,
            using: geometry,
            maintainAspectRatio: event.modifierFlags.contains(.shift)
        )
    }
    
    private func updateSelection(
        to currentPoint: CGPoint,
        using geometry: ImageDisplayGeometry,
        maintainAspectRatio: Bool
    ) {
        guard let dragOperation else {
            return
        }

        switch dragOperation {
        case let .create(startPoint):
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
        case let .move(startPoint, selectionOrigin):
            selectionManager.moveSelection(
                toX: Double(selectionOrigin.x + currentPoint.x - startPoint.x),
                y: Double(selectionOrigin.y + currentPoint.y - startPoint.y),
                clampedToImageWidth: geometry.imageWidth,
                height: geometry.imageHeight
            )
        case let .resize(corner, startPoint, originalSelection):
            let originalCorner = originalSelection.point(at: corner)
            let resizedCorner = CGPoint(
                x: originalCorner.x + currentPoint.x - startPoint.x,
                y: originalCorner.y + currentPoint.y - startPoint.y
            )
            selectionManager.resizeSelection(
                from: corner,
                startingFrom: originalSelection,
                to: resizedCorner,
                maintainAspectRatio: maintainAspectRatio
            )
        }

        needsDisplay = true
    }

    private func resizeHandleRect(
        for selection: Selection,
        at corner: SelectionCorner,
        using geometry: ImageDisplayGeometry
    ) -> NSRect {
        let handleCenter = geometry.canvasPoint(fromImagePoint: selection.point(at: corner))

        return NSRect(
            x: handleCenter.x - resizeHandleSize / 2,
            y: handleCenter.y - resizeHandleSize / 2,
            width: resizeHandleSize,
            height: resizeHandleSize
        )
    }

    private func resizeCorner(
        at canvasPoint: CGPoint,
        for selection: Selection,
        using geometry: ImageDisplayGeometry
    ) -> SelectionCorner? {
        var nearestCorner: (corner: SelectionCorner, distance: CGFloat)?

        for corner in SelectionCorner.allCases {
            let handleRect = resizeHandleRect(for: selection, at: corner, using: geometry)
            guard handleRect.contains(canvasPoint) else {
                continue
            }

            let deltaX = canvasPoint.x - handleRect.midX
            let deltaY = canvasPoint.y - handleRect.midY
            let distance = deltaX * deltaX + deltaY * deltaY

            if let currentNearest = nearestCorner {
                if distance < currentNearest.distance {
                    nearestCorner = (corner, distance)
                }
            } else {
                nearestCorner = (corner, distance)
            }
        }

        return nearestCorner?.corner
    }
}

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
        case resize(startPoint: CGPoint, originalWidth: Double, originalHeight: Double)
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

        let handleRect = resizeHandleRect(for: selection, using: geometry)
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath(rect: handleRect).fill()
        NSColor.controlAccentColor.setStroke()
        NSBezierPath(rect: handleRect).stroke()
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
            if resizeHandleRect(for: selection, using: geometry).contains(canvasPoint) {
                dragOperation = .resize(
                    startPoint: imagePoint,
                    originalWidth: selection.geometry.width,
                    originalHeight: selection.geometry.height
                )
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
        case let .resize(startPoint, originalWidth, originalHeight):
            let proposedWidth = originalWidth + Double(currentPoint.x - startPoint.x)
            let proposedHeight = originalHeight + Double(currentPoint.y - startPoint.y)

            guard let originalGeometry = SelectionGeometry(
                width: originalWidth,
                height: originalHeight
            ),
            let resizedGeometry = originalGeometry.resized(
                toWidth: proposedWidth,
                height: proposedHeight,
                maintainAspectRatio: maintainAspectRatio
            ) else {
                return
            }

            selectionManager.resizeSelection(
                toWidth: resizedGeometry.width,
                height: resizedGeometry.height
            )
        }

        needsDisplay = true
    }

    private func resizeHandleRect(
        for selection: Selection,
        using geometry: ImageDisplayGeometry
    ) -> NSRect {
        let bottomRight = geometry.canvasPoint(
            fromImagePoint: CGPoint(
                x: selection.x + selection.geometry.width,
                y: selection.y + selection.geometry.height
            )
        )

        return NSRect(
            x: bottomRight.x - resizeHandleSize / 2,
            y: bottomRight.y - resizeHandleSize / 2,
            width: resizeHandleSize,
            height: resizeHandleSize
        )
    }
}

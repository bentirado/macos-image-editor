import XCTest
import AppKit
@testable import ImageEditor

/// Tests selection dimensions and boundary behavior.
final class SelectionGeometryTests: XCTestCase {

    func testResizeMaintainsAspectRatio() {

        // Arrange
        let selection = SelectionGeometry(width: 200, height: 100)!

        // Act
        let resized = selection.resized(toWidth: 300, maintainAspectRatio: true)

        // Assert
        XCTAssertEqual(resized?.width, 300)
        XCTAssertEqual(resized?.height, 150)
    }
    
    func testResizeWithoutMaintainingAspectRatio() {
        
        // Arrange
        let selection = SelectionGeometry(width: 200, height: 100)!
        
        // Act
        let resized = selection.resized(toWidth: 300, maintainAspectRatio: false)
        
        // Assert
        XCTAssertEqual(resized?.width, 300)
        XCTAssertEqual(resized?.height, 100)
    }

    /// Verifies that a ratio-locked resize fits inside the dragged dimensions.
    func testResizeWithAspectRatioFitsWithinRequestedDimensions() {
        let selection = SelectionGeometry(width: 200, height: 100)!

        let resized = selection.resized(
            toWidth: 500,
            height: 200,
            maintainAspectRatio: true
        )

        XCTAssertEqual(resized?.width, 400)
        XCTAssertEqual(resized?.height, 200)
    }
    
    func testRejectsZeroHeight() {
        
        // Arrange
        let selection = SelectionGeometry(width: 200, height: 0)
        
        // Assert
        XCTAssertNil(selection)
    }
    
    func testResizeRejectsNegativeWidth() {
        
        // Arrange
        let selection = SelectionGeometry(width: -200, height: 100)
        
        // Assert
        XCTAssertNil(selection)
    }
    
    func testResizeRejectsNegativeHeight() {
        
        // Arrange
        let selection = SelectionGeometry(width: 200, height: -100)
        
        // Assert
        XCTAssertNil(selection)
    }
    
    func testRejectsInfiniteWidth() {
         
        // Arrange
        let selection = SelectionGeometry(width: .infinity, height: 100)
        
        // Assert
        XCTAssertNil(selection)
    }
    
    func testRejectsInfiniteResizeWidth() {
        
        // Arrange
        let selection = SelectionGeometry(width: 200, height: 100)!
        
        // Act
        let resized = selection.resized(toWidth: .infinity, maintainAspectRatio: true)
        
        // Assert
        XCTAssertNil(resized)
    }
    
    func testRejectsNaNHeight () {
        
        // Arrange
        let selection = SelectionGeometry(width: 200, height: .nan)
        
        // Assert
        XCTAssertNil(selection)
    }
    
    func testRejectsNaNResizeWidth() {
        
        // Arrange
        let selection = SelectionGeometry(width: 200, height: 100)!
        
        // Act
        let resized = selection.resized(toWidth: .nan, maintainAspectRatio: true)
        
        // Assert
        XCTAssertNil(resized)
    }
    
    func testSelectionStoresPositionAndGeometry() {
        
        // Arrange
        let geometry = SelectionGeometry(width: 200, height: 100)!
        
        let selection = Selection(x: 50, y: 75, geometry: geometry)
        
        // AssertDone
        XCTAssertEqual(selection.x, 50)
        XCTAssertEqual(selection.y, 75)
        XCTAssertEqual(selection.geometry.width, 200)
        XCTAssertEqual(selection.geometry.height, 100)
    }

    /// Verifies that hit-testing includes the selection's edges.
    func testSelectionContainsImagePointsWithinInclusiveBounds() {
        let selection = Selection(
            x: 50,
            y: 75,
            geometry: SelectionGeometry(width: 200, height: 100)!
        )

        XCTAssertTrue(selection.contains(imagePoint: CGPoint(x: 50, y: 75)))
        XCTAssertTrue(selection.contains(imagePoint: CGPoint(x: 150, y: 125)))
        XCTAssertTrue(selection.contains(imagePoint: CGPoint(x: 250, y: 175)))
        XCTAssertFalse(selection.contains(imagePoint: CGPoint(x: 251, y: 175)))
    }

    /// Verifies that resizing from the top-left keeps the opposite corner fixed.
    func testResizeFromTopLeftKeepsBottomRightAnchorFixed() {
        let selection = Selection(
            x: 40,
            y: 30,
            geometry: SelectionGeometry(width: 80, height: 40)!
        )

        let resized = selection.resized(
            from: .topLeft,
            to: CGPoint(x: 20, y: 10),
            maintainAspectRatio: false
        )

        XCTAssertEqual(resized?.x, 20)
        XCTAssertEqual(resized?.y, 10)
        XCTAssertEqual(resized?.geometry.width, 100)
        XCTAssertEqual(resized?.geometry.height, 60)
    }

    /// Verifies that resizing from the top-right keeps the opposite corner fixed.
    func testResizeFromTopRightKeepsBottomLeftAnchorFixed() {
        let selection = Selection(
            x: 40,
            y: 30,
            geometry: SelectionGeometry(width: 80, height: 40)!
        )

        let resized = selection.resized(
            from: .topRight,
            to: CGPoint(x: 150, y: 10),
            maintainAspectRatio: false
        )

        XCTAssertEqual(resized?.x, 40)
        XCTAssertEqual(resized?.y, 10)
        XCTAssertEqual(resized?.geometry.width, 110)
        XCTAssertEqual(resized?.geometry.height, 60)
    }

    /// Verifies that Shift-style ratio locking preserves the opposite corner.
    func testRatioLockedCornerResizeKeepsOppositeCornerFixed() {
        let selection = Selection(
            x: 40,
            y: 30,
            geometry: SelectionGeometry(width: 80, height: 40)!
        )

        let resized = selection.resized(
            from: .topRight,
            to: CGPoint(x: 160, y: 0),
            maintainAspectRatio: true
        )

        XCTAssertEqual(resized?.x, 40)
        XCTAssertEqual(resized?.y, 10)
        XCTAssertEqual(resized?.geometry.width, 120)
        XCTAssertEqual(resized?.geometry.height, 60)
    }

    /// Verifies that resizing from the bottom-left keeps the opposite corner fixed.
    func testResizeFromBottomLeftKeepsTopRightAnchorFixed() {
        let selection = Selection(
            x: 40,
            y: 30,
            geometry: SelectionGeometry(width: 80, height: 40)!
        )

        let resized = selection.resized(
            from: .bottomLeft,
            to: CGPoint(x: 20, y: 100),
            maintainAspectRatio: false
        )

        XCTAssertEqual(resized?.x, 20)
        XCTAssertEqual(resized?.y, 30)
        XCTAssertEqual(resized?.geometry.width, 100)
        XCTAssertEqual(resized?.geometry.height, 70)
    }

    /// Verifies that resizing rejects crossing the fixed opposite corner.
    func testResizeRejectsCrossingOppositeCorner() {
        let selection = Selection(
            x: 40,
            y: 30,
            geometry: SelectionGeometry(width: 80, height: 40)!
        )

        XCTAssertNil(
            selection.resized(
                from: .bottomRight,
                to: CGPoint(x: 20, y: 100),
                maintainAspectRatio: false
            )
        )
    }
    
}

/// Tests creating, moving, resizing, and clearing selection state.
final class SelectionManagerTests: XCTestCase {
    
    func testCreateSelection() {
        // Arrange
        let manager = SelectionManager()
        
        // Act
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)
        
        // Assert
        XCTAssertEqual(manager.selection?.x, 50)
        XCTAssertEqual(manager.selection?.y, 75)
        XCTAssertEqual(manager.selection?.geometry.width, 200)
    }
    
    func testMoveSelection() {
        // Arrange
        let manager = SelectionManager()
        
        // Act
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)
        
        manager.moveSelection(toX: 100, y: 125)
        
        // Assert
        XCTAssertEqual(manager.selection?.x, 100)
        XCTAssertEqual(manager.selection?.y, 125)
        XCTAssertEqual(manager.selection?.geometry.width, 200)
        XCTAssertEqual(manager.selection?.geometry.height, 100)
    }

    /// Verifies that moving a selection keeps it within image bounds.
    func testMoveSelectionClampsToImageBounds() {
        let manager = SelectionManager()
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)

        manager.moveSelection(
            toX: 500,
            y: 400,
            clampedToImageWidth: 300,
            height: 250
        )

        XCTAssertEqual(manager.selection?.x, 100)
        XCTAssertEqual(manager.selection?.y, 150)
        XCTAssertEqual(manager.selection?.geometry.width, 200)
        XCTAssertEqual(manager.selection?.geometry.height, 100)
    }

    /// Verifies that negative move positions clamp to the image origin.
    func testMoveSelectionClampsToImageOrigin() {
        let manager = SelectionManager()
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)

        manager.moveSelection(
            toX: -20,
            y: -30,
            clampedToImageWidth: 300,
            height: 250
        )

        XCTAssertEqual(manager.selection?.x, 0)
        XCTAssertEqual(manager.selection?.y, 0)
    }
    
    func testClearSelection() {
        // Arrange
        let manager = SelectionManager()
        
        // Act
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)
        
        manager.clearSelection()
        
        // Assert
        XCTAssertNil(manager.selection)
        
    }
    
    func testMoveWithoutExistingSelection() {
        // Arrange
        let manager = SelectionManager()
        
        // Act
        manager.moveSelection(toX: 100, y: 125)
        
        // Assert
        XCTAssertNil(manager.selection)
    }
    
    func testInvalidDimensionsDoNotReplaceExistingSelection() {
        // Arrange
        let manager = SelectionManager()
        
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)
        
        // Act
        manager.createSelection(x: 0, y: 0, width: -100, height: 100)
        
        // Assert
        XCTAssertEqual(manager.selection?.x, 50)
        XCTAssertEqual(manager.selection?.y, 75)
        
    }
    
    func testResizeSelectionMaintainsAspectRatio() {
        // Arrange
        let manager = SelectionManager()
        
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)
        
        // Act
        manager.resizeSelection(
            toWidth: 300,
            maintainAspectRatio: true
        )
        
        // Assert
        XCTAssertEqual(manager.selection?.x, 50)
        XCTAssertEqual(manager.selection?.y, 75)
        XCTAssertEqual(manager.selection?.geometry.width, 300)
        XCTAssertEqual(manager.selection?.geometry.height, 150)

    }

    /// Verifies that resizing changes dimensions while preserving the origin.
    func testResizeSelectionToDimensions() {
        let manager = SelectionManager()
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)

        manager.resizeSelection(toWidth: 300, height: 150)

        XCTAssertEqual(manager.selection?.x, 50)
        XCTAssertEqual(manager.selection?.y, 75)
        XCTAssertEqual(manager.selection?.geometry.width, 300)
        XCTAssertEqual(manager.selection?.geometry.height, 150)
    }
    
    func testResizeSelectionWithoutAspectRatio() {
        // Arrange
        let manager = SelectionManager()
        
        manager.createSelection(x: 50, y: 75, width: 200, height: 100)
        
        // Act
        manager.resizeSelection(
            toWidth: 300,
            maintainAspectRatio: false
        )
        
        // Assert
        XCTAssertEqual(manager.selection?.geometry.width, 300)
        XCTAssertEqual(manager.selection?.geometry.height, 100)
    }
    
    func testResizeWithoutExistingSelection() {
        // Arrange
        let manager = SelectionManager()
        
        // Act
        manager.resizeSelection(
            toWidth: 300,
            maintainAspectRatio: true
        )
        
        // Assert
        XCTAssertNil(manager.selection)
    }
}

/// Tests image document metadata and coordinate dimensions.
final class ImageDocumentTests: XCTestCase {
    
    func testImageDocumentStoresImage() {
        let image = NSImage(
            size: NSSize(width: 640, height: 480)
        )
        
        let url = URL(fileURLWithPath: "/tmp/test-image.png")
        
        let document = ImageDocument(
            image: image,
            sourceURL: url
        )
        
        XCTAssertEqual(document.image.size.width, 640)
        XCTAssertEqual(document.image.size.height, 480)
    }
    
    func testImageDocumentStoresSourceURL() {
        let image = NSImage(
            size: NSSize(width: 640, height: 480)
        )
        
        let url = URL(fileURLWithPath: "/tmp/test-image.png")
        
        let document = ImageDocument(
            image: image,
            sourceURL: url
        )
        
        XCTAssertEqual(document.sourceURL, url)
    }

    /// Verifies that pixel dimensions come from the largest bitmap
    /// representation instead of the image's logical point size.
    func testPixelSizeUsesLargestBitmapRepresentation() {
        let image = NSImage(size: NSSize(width: 300, height: 200))
        func makeBitmap(width: Int, height: Int) -> NSBitmapImageRep? {
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: width,
                pixelsHigh: height,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        }

        guard let standardBitmap = makeBitmap(width: 300, height: 200),
              let highResolutionBitmap = makeBitmap(width: 600, height: 400) else {
            XCTFail("Expected to create bitmap representations")
            return
        }
        standardBitmap.size = NSSize(width: 300, height: 200)
        highResolutionBitmap.size = NSSize(width: 300, height: 200)
        image.addRepresentation(standardBitmap)
        image.addRepresentation(highResolutionBitmap)

        let document = ImageDocument(
            image: image,
            sourceURL: URL(fileURLWithPath: "/tmp/retina-image.png")
        )

        XCTAssertEqual(document.pixelSize, CGSize(width: 600, height: 400))
    }

    /// Verifies that images without bitmap representations use their image size.
    func testPixelSizeFallsBackToImageSizeWithoutBitmapRepresentation() {
        let image = NSImage(size: NSSize(width: 320, height: 240))
        let document = ImageDocument(
            image: image,
            sourceURL: URL(fileURLWithPath: "/tmp/vector-image.pdf")
        )

        XCTAssertEqual(document.pixelSize, CGSize(width: 320, height: 240))
    }
}

final class ImageLoaderTests: XCTestCase {
    
    func testLoadImageFromValidURL() throws {
        let imageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 1,
            pixelsHigh: 1,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        
        let imageData = bitmap.representation(using: .png, properties: [:])!
        
        try imageData.write(to: imageURL)
        defer {
            try? FileManager.default.removeItem(at: imageURL)
        }
        
        let document = try ImageLoader.load(from: imageURL)
        
        XCTAssertEqual(document.sourceURL, imageURL)
        XCTAssertEqual(document.image.size.width, 1)
        XCTAssertEqual(document.image.size.height, 1)
    }
    
    func testLoadImageFromInavidURLThrowsError() throws {
        let imageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        let invalidData = Data("This is not an image".utf8)
        try invalidData.write(to: imageURL)
        
        defer {
            try? FileManager.default.removeItem(at: imageURL)
        }
        
        XCTAssertThrowsError(
            try ImageLoader.load(from: imageURL)
        )
    }
}

final class ImageDocumentControllerTests: XCTestCase {
    
    func testInitiallyHasNoDocument() {
        let controller = ImageDocumentController()
        
        XCTAssertNil(controller.document)
    }
    
    func testCanOpenDocument() {
        let controller = ImageDocumentController()
        
        let image = NSImage(size: NSSize(width: 640, height: 430))
        let url = URL(fileURLWithPath: "/tmp/test-image.png")
        let document = ImageDocument(image: image, sourceURL: url)
        
        controller.open(document)
        
        XCTAssertNotNil(controller.document)
        XCTAssertEqual(controller.document?.sourceURL, url)
    }
    
    func testCanCloseDocument() {
        let controller = ImageDocumentController()
        
        let image = NSImage(size: NSSize(width: 640, height: 480))
        let url = URL(fileURLWithPath: "/tmp/test-image.png")
        let document = ImageDocument(image: image, sourceURL: url)
        
        controller.open(document)
        controller.close()
        
        XCTAssertNil(controller.document)
    }
    
    func testCanLoadDocumentFromURL() throws {
        let imageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")
        
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 1,
            pixelsHigh: 1,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        
        let imageData = bitmap.representation(using: .png, properties: [:])!
        try imageData.write(to: imageURL)
        
        defer {
            try? FileManager.default.removeItem(at: imageURL)
        }
        
        let controller = ImageDocumentController()
        try controller.open(from: imageURL)
        
        XCTAssertEqual(controller.document?.sourceURL, imageURL)
    }
}

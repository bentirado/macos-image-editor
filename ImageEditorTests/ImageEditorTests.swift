import XCTest
import AppKit
@testable import ImageEditor

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
    
}

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

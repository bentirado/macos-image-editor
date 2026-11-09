import XCTest
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
    
    func testRexizeRejectsZeroHeight() {
        
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
    
    func testRejectsInifiniteWidth() {
         
        // Arrange
        let selection = SelectionGeometry(width: .infinity, height: 100)
        
        // Assert
        XCTAssertNil(selection)
    }
    
    func testRejeectsInfiniteResizeWidth() {
        
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
        let selection = SelectionGeometry(width: 200, height: 100)
        
        // Act
        let resized = selection?.resized(toWidth: .nan, maintainAspectRatio: true)
        
        // Assert
        XCTAssertNil(resized)
    }
    
}

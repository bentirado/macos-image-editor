import XCTest
@testable import ImageEditor

/// Tests the calculations used to position and scale images
/// within the available canvas dimensions.
final class ImageDisplayGeometryTests: XCTestCase {

    /// Verifies that a large image scales proportionally
    /// to fit the available canvas dimensions.
    func testLargeImageFitsInsideCanvas() {
        let geometry = ImageDisplayGeometry(
            canvasWidth: 900,
            canvasHeight: 600,
            imageWidth: 1800,
            imageHeight: 1200
        )

        XCTAssertNotNil(geometry)
        XCTAssertEqual(geometry?.width, 900)
        XCTAssertEqual(geometry?.height, 600)
        XCTAssertEqual(geometry?.scale, 0.5)
        XCTAssertEqual(geometry?.x, 0)
        XCTAssertEqual(geometry?.y, 0)
    }

    /// Verifies that an image with a different aspect ratio
    /// is scaled proportionally and centered within the canvas.
    func testImageWithDifferentAspectRatioIsCentered() {
        let geometry = ImageDisplayGeometry(canvasWidth: 900, canvasHeight: 600, imageWidth: 1200, imageHeight: 1200)

        XCTAssertNotNil(geometry)
        XCTAssertEqual(geometry?.width, 600)
        XCTAssertEqual(geometry?.height, 600)
        XCTAssertEqual(geometry?.scale, 0.5)
        XCTAssertEqual(geometry?.x, 150)
        XCTAssertEqual(geometry?.y, 0)
    }

    /// Verifies that zero or negative dimensions are rejected.
    func testInvalidDimensionsReturnNil() {
        XCTAssertNil(
            ImageDisplayGeometry(canvasWidth: 0, canvasHeight: 600, imageWidth: 400, imageHeight: 200)
        )

        XCTAssertNil(
            ImageDisplayGeometry(canvasWidth: 900, canvasHeight: -1, imageWidth: 400, imageHeight: 200)
        )

        XCTAssertNil(
            ImageDisplayGeometry(canvasWidth: 900, canvasHeight: 600, imageWidth: 0, imageHeight: 200)
        )
    }

    /// Verifies that infinite and NaN dimensions are rejected.
    func testNonFiniteDimensionsReturnNil() {
        XCTAssertNil(
            ImageDisplayGeometry(canvasWidth: .infinity, canvasHeight: 600, imageWidth: 400, imageHeight: 200)
        )

        XCTAssertNil(
            ImageDisplayGeometry(canvasWidth: 900, canvasHeight: 600, imageWidth: .nan, imageHeight: 200)
        )
    }

    /// Verifies that image coordinates map to canvas coordinates with the
    /// expected vertical-axis inversion.
    func testImagePointConvertsToCanvasPoint() {
        let geometry = ImageDisplayGeometry(
            canvasWidth: 900,
            canvasHeight: 600,
            imageWidth: 1200,
            imageHeight: 1200
        )!

        let canvasPoint = geometry.canvasPoint(fromImagePoint: CGPoint(x: 0, y: 0))

        XCTAssertEqual(canvasPoint, CGPoint(x: 150, y: 600))
    }

    /// Verifies that canvas points in the letterboxed area are rejected.
    func testCanvasPointOutsideDisplayedImageReturnsNil() {
        let geometry = ImageDisplayGeometry(
            canvasWidth: 900,
            canvasHeight: 600,
            imageWidth: 1200,
            imageHeight: 1200
        )!

        XCTAssertNil(geometry.imagePoint(fromCanvasPoint: CGPoint(x: 149, y: 300)))
        XCTAssertNil(geometry.imagePoint(fromCanvasPoint: CGPoint(x: 751, y: 300)))
    }

    /// Verifies that points beyond the displayed image are clamped to its edge.
    func testCanvasPointOutsideDisplayedImageCanBeClamped() {
        let geometry = ImageDisplayGeometry(
            canvasWidth: 900,
            canvasHeight: 600,
            imageWidth: 1200,
            imageHeight: 1200
        )!

        XCTAssertEqual(
            geometry.clampedImagePoint(fromCanvasPoint: CGPoint(x: 100, y: 300)),
            CGPoint(x: 0, y: 600)
        )
        XCTAssertEqual(
            geometry.clampedImagePoint(fromCanvasPoint: CGPoint(x: 800, y: 300)),
            CGPoint(x: 1200, y: 600)
        )
    }

    /// Verifies that points on the displayed image edges are convertible.
    func testImageAndCanvasBoundaryPointsConvert() {
        let geometry = ImageDisplayGeometry(
            canvasWidth: 900,
            canvasHeight: 600,
            imageWidth: 1200,
            imageHeight: 1200
        )!

        XCTAssertEqual(
            geometry.canvasPoint(fromImagePoint: CGPoint(x: 1200, y: 1200)),
            CGPoint(x: 750, y: 0)
        )
        XCTAssertEqual(
            geometry.imagePoint(fromCanvasPoint: CGPoint(x: 750, y: 0)),
            CGPoint(x: 1200, y: 1200)
        )
    }

    /// Verifies that converting a point to canvas space and back preserves it.
    func testCoordinateConversionsRoundTrip() {
        let geometry = ImageDisplayGeometry(
            canvasWidth: 900,
            canvasHeight: 600,
            imageWidth: 1800,
            imageHeight: 1200
        )!
        let imagePoint = CGPoint(x: 450, y: 300)

        let canvasPoint = geometry.canvasPoint(fromImagePoint: imagePoint)
        let convertedImagePoint = geometry.imagePoint(fromCanvasPoint: canvasPoint)

        XCTAssertEqual(convertedImagePoint, imagePoint)
    }
}

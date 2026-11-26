import Foundation

/// A selection boundary whose position and dimensions are in image space.
/// The origin is at the image's top-left corner.
struct Selection {
    
    let x: Double
    let y: Double
    let geometry: SelectionGeometry
}

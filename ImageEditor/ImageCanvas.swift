import SwiftUI
import AppKit

struct ImageCanvas: NSViewRepresentable {
    
    let document: ImageDocument?
    
    func makeNSView(context: Context) -> ImageCanvasView {
        return ImageCanvasView()
    }
    
    func updateNSView(_ nsView: ImageCanvasView, context: Context) {
        nsView.image = document?.image
    }
    
}

import SwiftUI
import AppKit

struct ImageCanvas: NSViewRepresentable {
    
    func makeNSView(context: Context) -> ImageCanvasView {
        return ImageCanvasView()
    }
    
    func updateNSView(_ nsView: ImageCanvasView, context: Context) {
        // Updates will come later
    }
    
}

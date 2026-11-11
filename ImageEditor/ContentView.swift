import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Toolbar
            HStack {
                Text("Image Editor")
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Canvas
            ImageCanvas()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

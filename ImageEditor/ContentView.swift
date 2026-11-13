import SwiftUI
import AppKit

struct ContentView: View {
    
    @State private var documentController = ImageDocumentController()
    @State private var openedDocument: ImageDocument?

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Text("Image Editor")
                    .font(.headline)

                Spacer()

                Button("Open Image") {
                    guard let url = ImageFilePicker.chooseImageURL() else {
                        return
                    }
                    
                    do {
                        try documentController.open(from: url)
                        openedDocument = documentController.document
                    } catch {
                        print("Failed to open image: \(error)")
                    }
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .zIndex(1)

            if let document = openedDocument {
                Text("Opened: \(document.sourceURL.lastPathComponent)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            Divider()
                .zIndex(1)

            ImageCanvas(document: openedDocument)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .zIndex(0)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

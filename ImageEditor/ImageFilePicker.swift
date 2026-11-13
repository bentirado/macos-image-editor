import AppKit
import UniformTypeIdentifiers

enum ImageFilePicker {
    
    static func chooseImageURL() -> URL? {
        let panel = NSOpenPanel()
        
        panel.title = "Open Image"
        panel.prompt = "Open"
        panel.allowedContentTypes = [.image]
        panel.allowsOtherFileTypes = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        guard panel.runModal() == .OK else {
            return nil
        }
        
        return panel.url
    }
}

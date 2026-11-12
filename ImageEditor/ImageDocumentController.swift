import Foundation

final class ImageDocumentController {
    
    private(set) var document: ImageDocument?
    
    func open(_ document: ImageDocument) {
        self.document = document
    }
    
    func open(from url: URL) throws {
        let loadedDocument = try ImageLoader.load(from: url)
        open(loadedDocument)
    }
    
    func close() {
        document = nil
    }
}

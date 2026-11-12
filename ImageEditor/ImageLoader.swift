import AppKit

enum ImageLoader {
    
    static func load(from url: URL) throws -> ImageDocument {
        guard let image = NSImage(contentsOf: url),
              image.isValid else {
            throw ImageLoaderError.invalidImage
        }
        
        return ImageDocument(image: image, sourceURL: url
        )
    }
}

enum ImageLoaderError: Error {
    case invalidImage
}

import UIKit

class LocalImageManager {
    static let shared = LocalImageManager()
    
    private init() {}
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Save image to local documents directory
    /// Returns: The relative path (filename)
    func saveImage(image: UIImage, id: String) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw LocalStorageError.invalidImage
        }
        
        let filename = "\(id).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            throw LocalStorageError.saveFailed
        }
    }
    
    /// Load image from local documents directory
    func getImage(filename: String) -> UIImage? {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// Delete image from local documents directory
    func deleteImage(filename: String) {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    /// Get full URL for sharing
    func getFileURL(filename: String) -> URL {
        return documentsDirectory.appendingPathComponent(filename)
    }
}

enum LocalStorageError: LocalizedError {
    case invalidImage
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Invalid image data"
        case .saveFailed: return "Failed to save image locally"
        }
    }
}

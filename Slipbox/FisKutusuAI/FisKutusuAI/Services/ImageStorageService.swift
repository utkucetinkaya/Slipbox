import Foundation
import UIKit

class ImageStorageService {
    static let shared = ImageStorageService()
    
    private let fileManager = FileManager.default
    
    private var baseDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let supportDir = paths[0].appendingPathComponent("SlipBox", isDirectory: true)
        let receiptsDir = supportDir.appendingPathComponent("receipts", isDirectory: true)
        
        // Create directories if they don't exist
        try? fileManager.createDirectory(at: receiptsDir, withIntermediateDirectories: true)
        
        return receiptsDir
    }
    
    func saveImage(_ image: UIImage, fileName: String) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.dataConversionFailed
        }
        
        let nameWithExt = fileName.hasSuffix(".jpg") ? fileName : "\(fileName).jpg"
        let fileURL = baseDirectory.appendingPathComponent(nameWithExt)
        try data.write(to: fileURL)
        
        // Return ONLY the filename. The app support directory path changes on iOS.
        return nameWithExt
    }
    
    func loadImage(from path: String) -> UIImage? {
        if path.isEmpty { return nil }
        
        // Handle legacy absolute paths OR new relative paths
        if path.starts(with: "/") {
            // Legacy: Try to load directly, but if it fails (due to app update), 
            // try to recover by taking only the filename
            if let image = UIImage(contentsOfFile: path) {
                return image
            }
            
            let fileName = (path as NSString).lastPathComponent
            let recoveredURL = baseDirectory.appendingPathComponent(fileName)
            return UIImage(contentsOfFile: recoveredURL.path)
        } else {
            // New: Relative path (just filename)
            let fileURL = baseDirectory.appendingPathComponent(path)
            return UIImage(contentsOfFile: fileURL.path)
        }
    }
    
    func deleteImage(at path: String) {
        if path.isEmpty { return }
        
        let url: URL
        if path.starts(with: "/") {
            url = URL(fileURLWithPath: path)
        } else {
            url = baseDirectory.appendingPathComponent(path)
        }
        
        try? fileManager.removeItem(at: url)
    }
    
    enum StorageError: Error {
        case dataConversionFailed
    }
}

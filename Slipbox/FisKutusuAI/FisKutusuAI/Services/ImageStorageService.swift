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
        
        let fileURL = baseDirectory.appendingPathComponent("\(fileName).jpg")
        try data.write(to: fileURL)
        
        return fileURL.path
    }
    
    func loadImage(from path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
    
    func deleteImage(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? fileManager.removeItem(at: url)
    }
    
    enum StorageError: Error {
        case dataConversionFailed
    }
}

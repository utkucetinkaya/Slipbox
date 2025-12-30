import Foundation

extension String {
    /// Convenience method for localization
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Localization with arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

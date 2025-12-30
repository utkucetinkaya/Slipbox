import SwiftUI
import Combine

/// Observable localization manager that provides dynamic string translation
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguageCode")
        }
    }
    
    private var bundle: Bundle?
    
    init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguageCode") ?? "tr"
        self.bundle = LocalizationManager.getBundle(for: currentLanguage)
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        bundle = LocalizationManager.getBundle(for: language)
    }
    
    func localizedString(for key: String) -> String {
        guard let bundle = bundle else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
    
    private static func getBundle(for language: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return nil
        }
        return bundle
    }
}

/// String extension for easy localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: LocalizationManager.shared.localizedString(for: self), arguments: arguments)
    }
}

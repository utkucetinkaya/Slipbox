import SwiftUI
import Combine

class AppUIState: ObservableObject {
    static let shared = AppUIState()
    
    @Published var isTabBarHidden: Bool = false
    
    private init() {}
}

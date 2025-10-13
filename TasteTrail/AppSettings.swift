import Foundation
import SwiftUI
import Combine

class AppSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }
    
    static let shared = AppSettings()
    
    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage")
        self.language = AppLanguage(rawValue: savedLanguage ?? "de") ?? .german
    }
}


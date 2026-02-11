import Foundation

// MARK: - Configuration
struct DisplayConfig: Codable {
    enum PhoneticType: String, Codable {
        case uk
        case us
    }
    var phoneticType: PhoneticType = .uk
    var showPhonetics: Bool = true
    var showWordType: Bool = true
    var showSentencePattern: Bool = true
    var showTranslation: Bool = true
    var backgroundImageIndex: Int = 0
    var maskOpacity: Float = 0.8
    
    // MARK: - Persistence
    private static let userDefaultsKey = "DisplayConfig"
    
    static func load() -> DisplayConfig {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let config = try? JSONDecoder().decode(DisplayConfig.self, from: data) {
            return config
        }
        return DisplayConfig()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: DisplayConfig.userDefaultsKey)
        }
    }
}

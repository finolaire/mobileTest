import Foundation
import UIKit

// MARK: - Configuration
struct DisplayConfig: Codable {
    enum PhoneticType: String, Codable {
        case uk
        case us
    }
    var phoneticType: PhoneticType = .us
    var showPhonetics: Bool = true
    var showWordType: Bool = true
    var showSentencePattern: Bool = true
    var showTranslation: Bool = true
    var showEnglishSentence: Bool = true
    var showAudioButton: Bool = true
    var showTranslationAudioButton: Bool = true
    var showEnglishAudioButton: Bool = true
    var backgroundImageIndex: Int = 0
    var selectedVoiceIdentifier: String? = nil
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

// MARK: - App Theme Colors
struct AppTheme {
    static let lightBlue = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
    static let lightRed = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
    static let lightGreen = UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
    static let yellowOrange = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
    static let white = UIColor.white
    
    static func color(forTag tag: String) -> UIColor {
        switch tag {
        case "pronoun_subject": return lightBlue
        case "verb_be": return lightRed
        case "article_indefinite": return lightGreen
        case "noun_object": return yellowOrange
        default: return white
        }
    }
    
    static func color(forKeyword keyword: String) -> UIColor {
        switch keyword {
        case "主语": return lightBlue
        case "Be动词", "系动词": return lightRed
        case "冠词": return lightGreen
        case "名词", "宾语", "表语": return yellowOrange
        default: return white
        }
    }
}

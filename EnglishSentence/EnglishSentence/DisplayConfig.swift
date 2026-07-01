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
    var useCustomBackground: Bool = false
    var customBackgroundImageName: String? = nil
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
    static let lightPurple = UIColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0)
    static let lightGray = UIColor(white: 0.7, alpha: 1.0)
    static let white = UIColor.white
    
    static func color(forTag tag: String) -> UIColor {
        switch tag {
        // Subject (Blue)
        case "pronoun_subject", "noun_subject", "clause_subject", "noun_proper", "phrase_emphasis_head":
            return lightBlue
            
        // Verb (Red)
        case "verb_be", "verb_intransitive", "verb_transitive", "verb_linking", "verb_phrase",
             "verb_auxiliary", "verb_base", "verb_past", "verb_past_participle", "verb_present_participle",
             "verb_imperative", "verb_auxiliary_negative", "phrase_verb":
            return lightRed
            
        // Object / Complement (Orange)
        case "noun_object", "pronoun_object", "noun_object_direct", "noun_object_indirect",
             "noun_predicative", "noun_complement", "clause_object", "clause_remaining", "clause_main":
            return yellowOrange
            
        // Adjective / Adverb / Modifier (Green)
        case "article_indefinite", "article_definite", "adjective_predicative", "adjective_complement",
             "adverb_guide", "adverb_frequency", "adverb_time", "adverb_place", "adverb_negative", "adverb_politeness",
             "phrase_prepositional", "phrase_time", "phrase_future", "clause_adverbial", "clause_attributive",
             "numeral_cardinal", "phrase_noun":
            return lightGreen
            
        // Special / Other (Purple/Gray)
        case "conjunction_emphasis", "conjunction_subordinating":
            return lightPurple
        case "ellipsis_subject", "ellipsis_clause_subject_verb":
            return lightGray
            
        default:
            return white
        }
    }
    
    static func color(forKeyword keyword: String) -> UIColor {
        // Simple heuristic matching
        if keyword.contains("主语") { return lightBlue }
        if keyword.contains("动词") || keyword.contains("谓语") { return lightRed }
        if keyword.contains("宾语") || keyword.contains("表语") || keyword.contains("补足语") { return yellowOrange }
        if keyword.contains("状语") || keyword.contains("定语") || keyword.contains("冠词") || keyword.contains("形容词") || keyword.contains("副词") { return lightGreen }
        
        return white
    }
}

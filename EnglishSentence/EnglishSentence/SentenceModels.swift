import Foundation

// MARK: - CourseUnit
struct CourseUnit: Codable {
    let unitName: String
    let description: String
    let sentences: [Sentence]

    enum CodingKeys: String, CodingKey {
        case unitName = "unit_name"
        case description
        case sentences
    }
}

// MARK: - Sentence
struct Sentence: Codable {
    let id: String
    let sentenceInfo: SentenceInfo
    let analysis: [WordAnalysis]

    enum CodingKeys: String, CodingKey {
        case id
        case sentenceInfo = "sentence_info"
        case analysis
    }
}

// MARK: - SentenceInfo
struct SentenceInfo: Codable {
    let original: String
    let translation: String
    let sentencePattern: String
    let patternCode: String
    let difficultyLevel: Int
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case original
        case translation
        case sentencePattern = "sentence_pattern"
        case patternCode = "pattern_code"
        case difficultyLevel = "difficulty_level"
        case tags
    }
}

// MARK: - WordAnalysis
struct WordAnalysis: Codable {
    let word: String
    let baseForm: String
    let range: [Int]
    let tag: String
    let type: String
    let chineseDefinition: String
    let explanation: String
    let phonetics: Phonetics

    enum CodingKeys: String, CodingKey {
        case word
        case baseForm = "base_form"
        case range
        case tag
        case type
        case chineseDefinition = "chinese_definition"
        case explanation
        case phonetics
    }
}

// MARK: - Phonetics
struct Phonetics: Codable {
    let uk: String
    let us: String
    let audioUk: String
    let audioUs: String

    enum CodingKeys: String, CodingKey {
        case uk
        case us
        case audioUk = "audio_uk"
        case audioUs = "audio_us"
    }
}

import Foundation
import UIKit

class SentenceViewModel {
    // MARK: - Properties
    private var courseUnit: CourseUnit?
    private var currentSentenceIndex: Int = 0
    var displayConfig = DisplayConfig.load()
    
    // MARK: - Output Properties
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    var currentPattern: String {
        guard let unit = courseUnit, !unit.sentences.isEmpty else { return "" }
        return unit.sentences[currentSentenceIndex].sentenceInfo.sentencePattern
    }
    
    var currentTranslation: String {
        guard let unit = courseUnit, !unit.sentences.isEmpty else { return "" }
        return unit.sentences[currentSentenceIndex].sentenceInfo.translation
    }
    
    var isPrevEnabled: Bool {
        return currentSentenceIndex > 0
    }
    
    var isNextEnabled: Bool {
        guard let unit = courseUnit else { return false }
        return currentSentenceIndex < unit.sentences.count - 1
    }
    
    // MARK: - Methods
    func loadData() {
        // Try to load from Bundle
        if let url = Bundle.main.url(forResource: "sentence_01", withExtension: "json") {
            parseJSON(from: url)
        } else {
            // Error handling if file is missing from Bundle
            let errorMsg = "Could not find sentence_01.json in Bundle. Please ensure it is added to 'Copy Bundle Resources' in Build Phases."
            print(errorMsg)
            onError?(errorMsg)
        }
    }
    
    private func parseJSON(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            courseUnit = try decoder.decode(CourseUnit.self, from: data)
            onDataUpdated?()
        } catch {
            onError?("Failed to load data: \(error.localizedDescription)")
        }
    }
    
    func nextSentence() {
        guard let unit = courseUnit else { return }
        if currentSentenceIndex < unit.sentences.count - 1 {
            currentSentenceIndex += 1
            onDataUpdated?()
        }
    }
    
    func prevSentence() {
        if currentSentenceIndex > 0 {
            currentSentenceIndex -= 1
            onDataUpdated?()
        }
    }
    
    func updateConfig(_ newConfig: DisplayConfig) {
        self.displayConfig = newConfig
        self.displayConfig.save()
        onDataUpdated?()
    }
    
    // MARK: - CollectionView Helpers
    func numberOfItems() -> Int {
        guard let unit = courseUnit, !unit.sentences.isEmpty else { return 0 }
        return unit.sentences[currentSentenceIndex].analysis.count
    }
    
    func viewModelForCell(at index: Int) -> WordCellViewModel? {
        guard let unit = courseUnit,
              !unit.sentences.isEmpty,
              index < unit.sentences[currentSentenceIndex].analysis.count else {
            return nil
        }
        let analysis = unit.sentences[currentSentenceIndex].analysis[index]
        return WordCellViewModel(analysis: analysis, config: displayConfig)
    }
}

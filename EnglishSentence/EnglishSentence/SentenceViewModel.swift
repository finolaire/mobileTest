import Foundation
import UIKit

class SentenceViewModel {
    // MARK: - Properties
    private var courseUnit: CourseUnit?
    private var currentSentenceIndex: Int = 0
    private var allCourses: [CourseUnit] = []
    private var currentCourseIndex: Int = 0
    var displayConfig = DisplayConfig.load()
    
    // MARK: - Output Properties
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    var currentSentence: Sentence? {
        guard let unit = courseUnit, !unit.sentences.isEmpty else { return nil }
        return unit.sentences[currentSentenceIndex]
    }
    
    var currentPatternAttributed: NSAttributedString {
        guard let unit = courseUnit, !unit.sentences.isEmpty else { return NSAttributedString(string: "") }
        let pattern = unit.sentences[currentSentenceIndex].sentenceInfo.sentencePattern
        
        // Split by " + "
        // Example: "主语 + Be动词 + 冠词 + 名词"
        let components = pattern.components(separatedBy: " + ")
        let attributedString = NSMutableAttributedString()
        
        for (index, component) in components.enumerated() {
            // Get color for component
            let color = AppTheme.color(forKeyword: component)
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: UIFont.systemFont(ofSize: 16, weight: .medium)
            ]
            let part = NSAttributedString(string: component, attributes: attributes)
            attributedString.append(part)
            
            // Add separator if not last
            if index < components.count - 1 {
                let separatorAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 16, weight: .medium)
                ]
                attributedString.append(NSAttributedString(string: " + ", attributes: separatorAttributes))
            }
        }
        
        return attributedString
    }
    
    var currentEnglishSentenceAttributed: NSAttributedString {
        guard let unit = courseUnit, !unit.sentences.isEmpty else { return NSAttributedString(string: "") }
        let sentence = unit.sentences[currentSentenceIndex]
        let original = sentence.sentenceInfo.original
        
        let attributedString = NSMutableAttributedString(string: original, attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ])
        
        // Track ranges that have already been colored to avoid overlapping
        var coloredRanges: [NSRange] = []
        
        for analysis in sentence.analysis {
            let color = AppTheme.color(forTag: analysis.tag)
            let word = analysis.word
            
            // Find all ranges of this word in the original string
            let ranges = original.ranges(of: word)
            
            for range in ranges {
                // Check if this range overlaps with any already colored range
                let isOverlapping = coloredRanges.contains { existingRange in
                    return NSIntersectionRange(existingRange, range).length > 0
                }
                
                if !isOverlapping {
                    // Apply color
                    attributedString.addAttribute(.foregroundColor, value: color, range: range)
                    coloredRanges.append(range)
                    break // Move to next word in analysis
                }
            }
        }
        
        return attributedString
    }
    
    var currentTranslationAttributed: NSAttributedString {
        guard let unit = courseUnit, !unit.sentences.isEmpty else { return NSAttributedString(string: "") }
        let sentence = unit.sentences[currentSentenceIndex]
        let translation = sentence.sentenceInfo.translation
        
        let attributedString = NSMutableAttributedString(string: translation, attributes: [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ])
        
        // Track ranges that have already been colored to avoid overlapping
        var coloredRanges: [NSRange] = []
        
        for analysis in sentence.analysis {
            let color = AppTheme.color(forTag: analysis.tag)
            // Split definitions by "/" (e.g., "一个/一名")
            let definitions = analysis.chineseDefinition.components(separatedBy: "/")
            
            var foundMatchForWord = false
            
            for def in definitions {
                if foundMatchForWord { break }
                
                // Find all ranges of this definition in the translation string
                let ranges = translation.ranges(of: def)
                
                for range in ranges {
                    // Check if this range overlaps with any already colored range
                    let isOverlapping = coloredRanges.contains { existingRange in
                        return NSIntersectionRange(existingRange, range).length > 0
                    }
                    
                    if !isOverlapping {
                        // Apply color
                        attributedString.addAttribute(.foregroundColor, value: color, range: range)
                        coloredRanges.append(range)
                        foundMatchForWord = true
                        break // Move to next word in analysis
                    }
                }
            }
        }
        
        return attributedString
    }
    
    var isPrevEnabled: Bool {
        return currentSentenceIndex > 0 || currentCourseIndex > 0
    }
    
    var isNextEnabled: Bool {
        guard let unit = courseUnit else { return false }
        if currentSentenceIndex < unit.sentences.count - 1 { return true }
        return currentCourseIndex < allCourses.count - 1
    }
    
    var currentCourseId: String? {
        return courseUnit?.id
    }
    
    var currentCourseSentenceCount: Int {
        return courseUnit?.sentences.count ?? 0
    }
    
    var currentSentencePosition: Int {
        return currentSentenceIndex
    }
    
    var hasNextCourse: Bool {
        return currentCourseIndex < allCourses.count - 1
    }
    
    // MARK: - Methods
    func loadData(unit: CourseUnit? = nil) {
        refreshCourseList()
        
        if let unit = unit {
            applyCourse(unit, sentenceIndex: 0, shouldPersist: true)
            onDataUpdated?()
            return
        }
        
        // Try to load last played course
        if let lastId = CourseManager.shared.getLastPlayedCourseId(),
           let lastCourse = allCourses.first(where: { $0.id == lastId }) {
            print("Loading last played course: \(lastCourse.unitName)")
            applyCourse(lastCourse, sentenceIndex: 0, shouldPersist: false)
            onDataUpdated?()
            return
        }
        
        // Fallback: Try to load the first available course from CourseManager
        if let firstCourse = allCourses.first {
            applyCourse(firstCourse, sentenceIndex: 0, shouldPersist: true)
            onDataUpdated?()
        } else {
            let errorMsg = "No course data found."
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
            return
        }
        
        // Current JSON finished: jump to next JSON's first sentence
        let nextCourseIndex = currentCourseIndex + 1
        guard nextCourseIndex < allCourses.count else { return }
        let nextCourse = allCourses[nextCourseIndex]
        applyCourse(nextCourse, sentenceIndex: 0, shouldPersist: true)
        onDataUpdated?()
    }
    
    func prevSentence() {
        if currentSentenceIndex > 0 {
            currentSentenceIndex -= 1
            onDataUpdated?()
            return
        }
        
        // At first sentence: jump to previous JSON's last sentence
        let prevCourseIndex = currentCourseIndex - 1
        guard prevCourseIndex >= 0 else { return }
        let prevCourse = allCourses[prevCourseIndex]
        let lastSentenceIndex = max(prevCourse.sentences.count - 1, 0)
        applyCourse(prevCourse, sentenceIndex: lastSentenceIndex, shouldPersist: true)
        onDataUpdated?()
    }
    
    func moveToNextCourseFirstSentence() {
        let nextCourseIndex = currentCourseIndex + 1
        guard nextCourseIndex < allCourses.count else { return }
        let nextCourse = allCourses[nextCourseIndex]
        applyCourse(nextCourse, sentenceIndex: 0, shouldPersist: true)
        onDataUpdated?()
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
        guard let analysis = analysisForCell(at: index) else { return nil }
        return WordCellViewModel(analysis: analysis, config: displayConfig)
    }
    
    func analysisForCell(at index: Int) -> WordAnalysis? {
        guard let unit = courseUnit,
              !unit.sentences.isEmpty,
              index < unit.sentences[currentSentenceIndex].analysis.count else {
            return nil
        }
        return unit.sentences[currentSentenceIndex].analysis[index]
    }
    
    private func refreshCourseList() {
        let sections = CourseManager.shared.getAllCourses()
        allCourses = sections.flatMap { $0.courses }
        
        if let current = courseUnit,
           let idx = allCourses.firstIndex(where: { $0.id == current.id }) {
            currentCourseIndex = idx
        }
    }
    
    private func applyCourse(_ course: CourseUnit, sentenceIndex: Int, shouldPersist: Bool) {
        courseUnit = course
        currentSentenceIndex = min(max(sentenceIndex, 0), max(course.sentences.count - 1, 0))
        if let idx = allCourses.firstIndex(where: { $0.id == course.id }) {
            currentCourseIndex = idx
        }
        
        if shouldPersist {
            CourseManager.shared.saveLastPlayedCourseId(course.id)
        }
    }
}

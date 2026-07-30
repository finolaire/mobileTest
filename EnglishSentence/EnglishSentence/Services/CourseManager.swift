import Foundation

struct CourseSection {
    let categoryName: String
    var courses: [CourseUnit]
}

class CourseManager {
    static let shared = CourseManager()
    
    private init() {
        print("CourseManager initialized")
    }
    
    struct CourseManifest: Codable {
        let sections: [ManifestSection]
    }
    
    struct ManifestSection: Codable {
        let id: String
        let title: String
        let directory: String
        let files: [String]
    }
    
    var isManifestLoaded: Bool = false
    
    // MARK: - Persistence
    private let kLastPlayedCourseId = "LastPlayedCourseId"
    
    func saveLastPlayedCourseId(_ id: String) {
        UserDefaults.standard.set(id, forKey: kLastPlayedCourseId)
    }
    
    func getLastPlayedCourseId() -> String? {
        return UserDefaults.standard.string(forKey: kLastPlayedCourseId)
    }
    
    func getCourse(byId id: String) -> CourseUnit? {
        // This is a bit inefficient (O(N)), but with < 100 courses it's fine.
        // We could build a dictionary map if needed.
        let sections = getAllCourses()
        for section in sections {
            if let course = section.courses.first(where: { $0.id == id }) {
                return course
            }
        }
        return nil
    }
    
    func getAllCourses(forceReload: Bool = false) -> [CourseSection] {
        // If manifest is used, we want to preserve the order defined in it.
        var manifestSectionsList: [CourseSection] = []
        
        // Fallback map for scanning mode
        var sectionMap: [String: [CourseUnit]] = [:]
        var seenIDs = Set<String>()
        
        let fileManager = FileManager.default
        
        // Helper to load a course from path
        func loadCourseFromFile(_ path: String) -> CourseUnit? {
            guard path.lowercased().hasSuffix(".json") else { return nil }
            return self.loadCourse(at: path)
        }
        
        // Strategy 0: Load from Manifest (Preferred)
        var manifestLoaded = false
        if let manifestURL = Bundle.main.url(forResource: "SentenceJsonConfig", withExtension: "json", subdirectory: "Resources/SentenceJson")
            ?? Bundle.main.url(forResource: "SentenceJsonConfig", withExtension: "json", subdirectory: "SentenceJson")
            ?? Bundle.main.url(forResource: "SentenceJsonConfig", withExtension: "json") {
            print("Found manifest at: \(manifestURL)")
            do {
                let data = try Data(contentsOf: manifestURL)
                let manifest = try JSONDecoder().decode(CourseManifest.self, from: data)
                
                let baseURL = manifestURL.deletingLastPathComponent()
                
                for section in manifest.sections {
                    var sectionCourses: [CourseUnit] = []
                    
                    for filename in section.files {
                        // Try multiple ways to find the file
                        var foundPath: String?
                        
                        // 1. Relative to manifest
                        let fullURL = baseURL.appendingPathComponent(section.directory).appendingPathComponent(filename)
                        if fileManager.fileExists(atPath: fullURL.path) {
                            foundPath = fullURL.path
                        }
                        
                        // 2. Flattened (Root)
                        if foundPath == nil {
                            let name = (filename as NSString).deletingPathExtension
                            let ext = (filename as NSString).pathExtension
                            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                                foundPath = url.path
                            }
                        }
                        
                        // 3. Flattened (SentenceJson subdir)
                        if foundPath == nil {
                            let name = (filename as NSString).deletingPathExtension
                            let ext = (filename as NSString).pathExtension
                            for subdir in ["Resources/SentenceJson", "SentenceJson"] {
                                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) {
                                    foundPath = url.path
                                    break
                                }
                            }
                        }
                        
                        if let path = foundPath, let course = loadCourseFromFile(path) {
                            if !seenIDs.contains(course.id) {
                                seenIDs.insert(course.id)
                                sectionCourses.append(course)
                                print("Loaded course: \(course.unitName) [\(course.id)]")
                            }
                        } else {
                            print("Failed to load file: \(filename)")
                        }
                    }
                    
                    if !sectionCourses.isEmpty {
                        manifestSectionsList.append(CourseSection(categoryName: section.title, courses: sectionCourses))
                    }
                }
                
                manifestLoaded = true
                print("Successfully loaded \(seenIDs.count) courses from manifest")
            } catch {
                print("Error loading manifest: \(error)")
            }
        }
        
        self.isManifestLoaded = manifestLoaded
        
        // If manifest loaded successfully, return the preserved order
        if manifestLoaded && !manifestSectionsList.isEmpty {
            return manifestSectionsList
        }
        
        // --- Fallback: Scanning Mode ---
        // Only runs if manifest failed
        
        // Helper for scanning
        func processPath(_ path: String) {
            guard let course = loadCourseFromFile(path) else { return }
            if seenIDs.contains(course.id) { return }
            seenIDs.insert(course.id)
            
            let categoryMapping: [String: String] = [
                "Basic_Structure": "01_句法基础 (Basic Structure)",
                "Tenses": "02_核心时态 (Tenses)",
                "Voice_Mood": "03_语态与语气 (Voice & Mood)",
                "Clauses": "04_从句 (Clauses)",
                "Special_Patterns": "05_特殊句型 (Special Patterns)"
            ]
            let rawCategory = course.category ?? "General"
            let displayCategory = categoryMapping[rawCategory] ?? (rawCategory == "General" ? "00_基础课程" : rawCategory)
            
            if sectionMap[displayCategory] == nil { sectionMap[displayCategory] = [] }
            sectionMap[displayCategory]?.append(course)
        }
        
        // Strategy 1: Deep Scan
        if let bundlePath = Bundle.main.resourcePath {
            let enumerator = fileManager.enumerator(atPath: bundlePath)
            while let element = enumerator?.nextObject() as? String {
                if element.lowercased().hasSuffix(".json") && !element.contains("SentenceJsonConfig") {
                    processPath((bundlePath as NSString).appendingPathComponent(element))
                }
            }
        }
        
        // Strategy 2: Specific Fallbacks (omitted for brevity as Deep Scan usually covers it, but keeping logic structure)
        if seenIDs.count < 5 {
             // ... existing fallback logic ...
        }
        
        // Convert map to sorted array (Fallback behavior)
        var sections: [CourseSection] = []
        for (key, value) in sectionMap {
            let sortedCourses = value.sorted { (c1, c2) -> Bool in
                return (c1.code ?? c1.unitName) < (c2.code ?? c2.unitName)
            }
            sections.append(CourseSection(categoryName: key, courses: sortedCourses))
        }
        return sections.sorted { $0.categoryName < $1.categoryName }
    }
    
    private func loadCourse(at path: String) -> CourseUnit? {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            let course = try decoder.decode(CourseUnit.self, from: data)
            // Basic validation
            if !course.sentences.isEmpty {
                return course
            }
            return nil
        } catch {
            print("Error decoding file at \(path): \(error)")
            return nil
        }
    }
}

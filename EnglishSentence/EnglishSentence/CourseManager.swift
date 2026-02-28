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
        let files: [String]
    }
    
    func getAllCourses(forceReload: Bool = false) -> [CourseSection] {
        var sectionMap: [String: [CourseUnit]] = [:]
        var seenIDs = Set<String>()
        
        let fileManager = FileManager.default
        
        // Helper to process a file path
        func processPath(_ path: String) {
            guard path.lowercased().hasSuffix(".json") else { return }
            
            if let course = self.loadCourse(at: path) {
                if seenIDs.contains(course.id) {
                    return
                }
                seenIDs.insert(course.id)
                
                // Map category
                // JSON categories: "Basic_Structure", "Tenses", "Voice_Mood", "Clauses", "Special_Patterns"
                let categoryMapping: [String: String] = [
                    "Basic_Structure": "01_句法基础 (Basic Structure)",
                    "Tenses": "02_核心时态 (Tenses)",
                    "Voice_Mood": "03_语态与语气 (Voice & Mood)",
                    "Clauses": "04_从句 (Clauses)",
                    "Special_Patterns": "05_特殊句型 (Special Patterns)"
                ]
                
                let rawCategory = course.category ?? "General"
                let displayCategory = categoryMapping[rawCategory] ?? (rawCategory == "General" ? "00_基础课程" : rawCategory)
                
                if sectionMap[displayCategory] == nil {
                    sectionMap[displayCategory] = []
                }
                sectionMap[displayCategory]?.append(course)
                
                print("Loaded course: \(course.unitName) [\(course.id)]")
            }
        }
        
        // Strategy 0: Load from Manifest (Preferred)
        var manifestLoaded = false
        if let manifestURL = Bundle.main.url(forResource: "course_manifest", withExtension: "json", subdirectory: "SentenceJson") ?? Bundle.main.url(forResource: "course_manifest", withExtension: "json") {
            print("Found manifest at: \(manifestURL)")
            do {
                let data = try Data(contentsOf: manifestURL)
                let manifest = try JSONDecoder().decode(CourseManifest.self, from: data)
                
                // Determine base URL for relative paths
                let baseURL = manifestURL.deletingLastPathComponent()
                
                for relativePath in manifest.files {
                    let fullURL = baseURL.appendingPathComponent(relativePath)
                    processPath(fullURL.path)
                }
                manifestLoaded = true
                print("Successfully loaded \(seenIDs.count) courses from manifest")
            } catch {
                print("Error loading manifest: \(error)")
            }
        } else {
            print("Manifest not found, falling back to scan...")
        }
        
        // Strategy 1: Deep Scan of the entire Bundle using Enumerator (Fallback)
        if !manifestLoaded || seenIDs.isEmpty {
            if let bundlePath = Bundle.main.resourcePath {
                print("--- Starting Deep Bundle Scan ---")
                print("Bundle Path: \(bundlePath)")
                
                let enumerator = fileManager.enumerator(atPath: bundlePath)
                while let element = enumerator?.nextObject() as? String {
                    if element.lowercased().hasSuffix(".json") && !element.contains("course_manifest") {
                        // We found a JSON file!
                        let fullPath = (bundlePath as NSString).appendingPathComponent(element)
                        processPath(fullPath)
                    }
                }
                print("--- End Deep Bundle Scan ---")
            }
        }
        
        // Strategy 2: Fallback (Legacy/Specific checks) - Only run if Strategy 1 failed completely
        if seenIDs.count < 5 {
             // ... (keep existing fallback logic just in case, or remove it if the enumerator covers everything)
        }
        
        // Strategy 2: Fallback - Look for specific known files if count is low
        if seenIDs.count < 5 {
            print("Low course count (\(seenIDs.count)), trying fallback scan...")
            
            // 2.1: Root level
            if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) {
                for url in urls { processPath(url.path) }
            }
            
            // 2.2: SentenceJson folder (if flat or folder ref)
            if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "SentenceJson") {
                for url in urls { processPath(url.path) }
            }
            
            // 2.3: Explicitly check known subdirectories (Deep Search)
            // This is needed if "SentenceJson" is a folder reference, because urls(forResources...) is not recursive
            let subdirs = [
                "SentenceJson/01_Basic_Structure",
                "SentenceJson/02_Tenses",
                "SentenceJson/03_Voice_Mood",
                "SentenceJson/04_Clauses",
                "SentenceJson/05_Special_Patterns"
            ]
            
            for subdir in subdirs {
                if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: subdir) {
                    print("Found files in subdir: \(subdir)")
                    for url in urls {
                        processPath(url.path)
                    }
                } else {
                    // Try without "SentenceJson/" prefix in case it was added as groups
                    let rawSubdir = subdir.replacingOccurrences(of: "SentenceJson/", with: "")
                    if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: rawSubdir) {
                        print("Found files in subdir: \(rawSubdir)")
                        for url in urls {
                            processPath(url.path)
                        }
                    }
                }
            }
        }
        
        // Convert map to sorted array
        var sections: [CourseSection] = []
        for (key, value) in sectionMap {
            // Sort courses within section by code or name
            let sortedCourses = value.sorted { (c1, c2) -> Bool in
                return (c1.code ?? c1.unitName) < (c2.code ?? c2.unitName)
            }
            sections.append(CourseSection(categoryName: key, courses: sortedCourses))
        }
        
        // Sort sections by name (00, 01, 02...)
        let sortedSections = sections.sorted { $0.categoryName < $1.categoryName }
        
        print("Total loaded courses: \(seenIDs.count) in \(sortedSections.count) sections")
        return sortedSections
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

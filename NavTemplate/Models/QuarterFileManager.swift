import Foundation

class QuarterFileManager {
    static let shared = QuarterFileManager()
    private let baseDirectory = "Category Notes/Daily"
    private let fileCoordinator = NSFileCoordinator()
    
    private init() {
        print(">>>>> QuarterFileManager: Initializing...")
        ensureBaseDirectoryExists()
    }
    
    internal var vaultURL: URL? {
        let url = ObsidianVaultAccess.shared.vaultURL
        if url == nil {
            print(">>>>> QuarterFileManager: No vault URL available")
        }
        return url
    }
    
    private func ensureBaseDirectoryExists() {
        guard let vault = vaultURL else {
            print(">>>>> QuarterFileManager: Cannot create base directory - no vault access")
            return
        }
        
        guard vault.startAccessingSecurityScopedResource() else {
            print(">>>>> QuarterFileManager: Cannot access vault for base directory creation")
            return
        }
        defer { vault.stopAccessingSecurityScopedResource() }
        
        let baseURL = vault.appendingPathComponent(baseDirectory)
        print(">>>>> QuarterFileManager: Ensuring base directory exists at: \(baseURL.path)")
        
        do {
            try FileManager.default.createDirectory(
                at: baseURL,
                withIntermediateDirectories: true
            )
            print(">>>>> QuarterFileManager: Base directory created/verified")
        } catch {
            print(">>>>> QuarterFileManager: Error creating base directory: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func getQuarterInfo(for date: Date = Date()) -> (year: String, quarter: Int) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let quarter = ((month - 1) / 3) + 1
        
        return (String(year), quarter)
    }
    
    private func ensureDirectoryExists(at path: URL) throws {
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        }
    }
    
    private func getQuarterFilePath(year: String, quarter: Int, baseURL: URL) -> URL {
        let yearPath = baseURL.appendingPathComponent(year)
        return yearPath.appendingPathComponent("\(year)-Q\(quarter).md")
    }
    
    // MARK: - Public Methods
    func appendActivity(_ activity: ActivityItem) throws {
        print(">>>>> QuarterFileManager: Attempting to append activity: \(activity.activityType.rawValue) at \(activity.activityTime)")
        
        guard let vault = vaultURL else {
            print(">>>>> QuarterFileManager: Cannot append - no vault access")
            throw QuarterFileError.noVaultAccess
        }
        
        guard vault.startAccessingSecurityScopedResource() else {
            print(">>>>> QuarterFileManager: Cannot access vault for append")
            throw QuarterFileError.noVaultAccess
        }
        defer { 
            vault.stopAccessingSecurityScopedResource()
            print(">>>>> QuarterFileManager: Released vault access")
        }
        
        var writeError: Error?
        var coordinatorError: NSError?
        
        fileCoordinator.coordinate(writingItemAt: vault, options: [], error: &coordinatorError) { url in
            do {
                let baseURL = url.appendingPathComponent(baseDirectory)
                let (year, quarter) = getQuarterInfo(for: activity.activityTime)
                print(">>>>> QuarterFileManager: Writing to Year: \(year), Quarter: \(quarter)")
                
                let yearPath = baseURL.appendingPathComponent(year)
                print(">>>>> QuarterFileManager: Ensuring year directory exists at: \(yearPath.path)")
                try ensureDirectoryExists(at: yearPath)
                
                let quarterFile = getQuarterFilePath(year: year, quarter: quarter, baseURL: baseURL)
                print(">>>>> QuarterFileManager: Quarter file path: \(quarterFile.path)")
                
                let timestamp = Int(activity.activityTime.timeIntervalSince1970)
                let entry = "\(activity.activityType.rawValue):: \(timestamp)\n"
                
                if FileManager.default.fileExists(atPath: quarterFile.path) {
                    print(">>>>> QuarterFileManager: Appending to existing file")
                    let fileHandle = try FileHandle(forWritingTo: quarterFile)
                    defer { try? fileHandle.close() }
                    try fileHandle.seekToEnd()
                    if let data = entry.data(using: .utf8) {
                        try fileHandle.write(contentsOf: data)
                    }
                } else {
                    print(">>>>> QuarterFileManager: Creating new quarter file")
                    try entry.write(to: quarterFile, atomically: true, encoding: .utf8)
                }
                print(">>>>> QuarterFileManager: Successfully wrote activity")
            } catch {
                writeError = error
            }
        }
        
        if let error = writeError ?? coordinatorError {
            print(">>>>> QuarterFileManager: Error occurred: \(error)")
            throw QuarterFileError.fileOperationFailed(error.localizedDescription)
        }
    }
    
    func loadLatestActivities(count: Int) throws -> [ActivityItem] {
        print(">>>>> QuarterFileManager: Loading latest \(count) activities")
        
        guard let vault = vaultURL else {
            throw QuarterFileError.noVaultAccess
        }
        
        guard vault.startAccessingSecurityScopedResource() else {
            throw QuarterFileError.noVaultAccess
        }
        defer { vault.stopAccessingSecurityScopedResource() }
        
        var activities: [ActivityItem] = []
        var coordinatorError: NSError?
        
        fileCoordinator.coordinate(readingItemAt: vault, options: [], error: &coordinatorError) { url in
            let baseURL = url.appendingPathComponent(baseDirectory)
            let (currentYear, currentQuarter) = getQuarterInfo()
            
            // Start from current quarter and go backwards
            var year = Int(currentYear)!
            var quarter = currentQuarter
            
            while activities.count < count {
                let quarterFile = getQuarterFilePath(year: String(year), quarter: quarter, baseURL: baseURL)
                
                if FileManager.default.fileExists(atPath: quarterFile.path),
                   let content = try? String(contentsOf: quarterFile, encoding: .utf8) {
                    
                    // Parse activities from file
                    let lines = content.components(separatedBy: .newlines)
                        .filter { !$0.isEmpty }
                        .compactMap { line -> ActivityItem? in
                            let components = line.components(separatedBy: ":: ")
                            guard components.count == 2,
                                  let activityType = ActivityType(rawValue: components[0]),
                                  let timestamp = Double(components[1]) else {
                                return nil
                            }
                            return ActivityItem(
                                type: activityType,
                                time: Date(timeIntervalSince1970: timestamp)
                            )
                        }
                    
                    activities.append(contentsOf: lines)
                    
                    if activities.count >= count {
                        break
                    }
                }
                
                // Move to previous quarter
                quarter -= 1
                if quarter < 1 {
                    quarter = 4
                    year -= 1
                }
                
                // Stop if we go too far back (e.g., 2 years)
                if year < Int(currentYear)! - 2 {
                    break
                }
            }
        }
        
        if let error = coordinatorError {
            throw QuarterFileError.fileOperationFailed(error.localizedDescription)
        }
        
        print(">>>>> QuarterFileManager: Loaded \(activities.count) activities")
        return activities
            .sorted { $0.activityTime > $1.activityTime }
            .prefix(count)
            .reversed()
    }
    
    // MARK: - Error Type
    enum QuarterFileError: Error {
        case noVaultAccess
        case fileOperationFailed(String)
    }
}

// Helper extension
private extension String {
    func appendToURL(_ url: URL) throws {
        if let data = (self + "\n").data(using: .utf8) {
            let handle = try FileHandle(forWritingTo: url)
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        }
    }
} 
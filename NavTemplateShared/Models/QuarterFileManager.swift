import Foundation

class QuarterFileManager {
    static let shared = QuarterFileManager()
    private let baseDirectory = "Category Notes/Daily"
    private let fileCoordinator = NSFileCoordinator()
    
    private init() {
        ensureBaseDirectoryExists()
    }
    
    internal var vaultURL: URL? {
        let url = ObsidianVaultAccess.shared.vaultURL
        if url == nil {
            print("QuarterFileManager: No vault URL available")
        }
        return url
    }
    
    private func ensureBaseDirectoryExists() {
        guard let vault = vaultURL else {
            print("QuarterFileManager: Cannot create base directory - no vault access")
            return
        }
        
        guard vault.startAccessingSecurityScopedResource() else {
            print("QuarterFileManager: Cannot access vault for base directory creation")
            return
        }
        defer { vault.stopAccessingSecurityScopedResource() }
        
        let baseURL = vault.appendingPathComponent(baseDirectory)
        
        do {
            try FileManager.default.createDirectory(
                at: baseURL,
                withIntermediateDirectories: true
            )
        } catch {
            print("QuarterFileManager: Error creating base directory: \(error)")
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
        guard let vault = vaultURL else {
            print("QuarterFileManager: Cannot append - no vault access")
            throw QuarterFileError.noVaultAccess
        }
        
        guard vault.startAccessingSecurityScopedResource() else {
            print("QuarterFileManager: Cannot access vault for append")
            throw QuarterFileError.noVaultAccess
        }
        defer { 
            vault.stopAccessingSecurityScopedResource()
        }
        
        var writeError: Error?
        var coordinatorError: NSError?
        
        fileCoordinator.coordinate(writingItemAt: vault, options: [], error: &coordinatorError) { url in
            do {
                let baseURL = url.appendingPathComponent(baseDirectory)
                let (year, quarter) = getQuarterInfo(for: activity.activityTime)
                
                let yearPath = baseURL.appendingPathComponent(year)
                try ensureDirectoryExists(at: yearPath)
                
                let quarterFile = getQuarterFilePath(year: year, quarter: quarter, baseURL: baseURL)
                
                let timestamp = Int(activity.activityTime.timeIntervalSince1970)
                let entry = "\(activity.activityType.rawValue):: \(timestamp)\n"
                
                if FileManager.default.fileExists(atPath: quarterFile.path) {
                    let fileHandle = try FileHandle(forWritingTo: quarterFile)
                    defer { try? fileHandle.close() }
                    try fileHandle.seekToEnd()
                    if let data = entry.data(using: .utf8) {
                        try fileHandle.write(contentsOf: data)
                    }
                } else {
                    try entry.write(to: quarterFile, atomically: true, encoding: .utf8)
                }
            } catch {
                writeError = error
            }
        }
        
        if let error = writeError ?? coordinatorError {
            print("QuarterFileManager: Error occurred: \(error)")
            throw QuarterFileError.fileOperationFailed(error.localizedDescription)
        }
    }
    
    func loadLatestActivities(count: Int) throws -> [ActivityItem] {
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
                
                if FileManager.default.fileExists(atPath: quarterFile.path) {
                    guard let fileHandle = try? FileHandle(forReadingFrom: quarterFile) else {
                        continue
                    }
                    defer { try? fileHandle.close() }
                    
                    // Get file size
                    let fileSize = try? fileHandle.seekToEnd()
                    guard let size = fileSize else { continue }
                    
                    // Read in chunks from end
                    let chunkSize: UInt64 = 4096  // 4KB chunks
                    var offset = size
                    var foundActivities: [ActivityItem] = []
                    
                    while offset > 0 && foundActivities.count < count {
                        let readSize = min(chunkSize, offset)
                        offset = offset - readSize
                        
                        try? fileHandle.seek(toOffset: offset)
                        guard let data = try? fileHandle.read(upToCount: Int(readSize)),
                              let chunk = String(data: data, encoding: .utf8) else {
                            continue
                        }
                        
                        // Parse chunk into activities
                        let newActivities = chunk.cleansedLines()
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
                        
                        foundActivities.append(contentsOf: newActivities)
                    }
                    
                    activities.append(contentsOf: foundActivities)
                }
                
                if activities.count >= count {
                    break
                }
                
                // Move to previous quarter
                quarter -= 1
                if quarter < 1 {
                    quarter = 4
                    year -= 1
                }
                
                // Stop if we go too far back
                if year < Int(currentYear)! - 2 {
                    break
                }
            }
        }
        
        if let error = coordinatorError {
            print("QuarterFileManager: Coordinator error: \(error)")
            throw QuarterFileError.fileOperationFailed(error.localizedDescription)
        }
        
        // Sort and take only what we need
        return activities
            .sorted { $0.activityTime > $1.activityTime }
            .prefix(count)
            .reversed()
    }
    
    func removeActivity(_ activity: ActivityItem) throws {
        guard let vault = vaultURL else {
            print("QuarterFileManager: Cannot remove - no vault access")
            throw QuarterFileError.noVaultAccess
        }
        
        guard vault.startAccessingSecurityScopedResource() else {
            print("QuarterFileManager: Cannot access vault for removal")
            throw QuarterFileError.noVaultAccess
        }
        defer { vault.stopAccessingSecurityScopedResource() }
        
        var writeError: Error?
        var coordinatorError: NSError?
        
        fileCoordinator.coordinate(writingItemAt: vault, options: [], error: &coordinatorError) { url in
            do {
                let baseURL = url.appendingPathComponent(baseDirectory)
                let (year, quarter) = getQuarterInfo(for: activity.activityTime)
                let quarterFile = getQuarterFilePath(year: year, quarter: quarter, baseURL: baseURL)
                
                // Check if file exists
                guard FileManager.default.fileExists(atPath: quarterFile.path) else {
                    throw QuarterFileError.fileOperationFailed("Quarter file not found")
                }
                
                // Read current content
                let content = try String(contentsOf: quarterFile, encoding: .utf8)
                let timestamp = Int(activity.activityTime.timeIntervalSince1970)
                let targetEntry = "\(activity.activityType.rawValue):: \(timestamp)"
                
                // Filter out the target entry using cleansedLines
                let updatedContent = content.cleansedLines()
                    .filter { $0 != targetEntry }
                    .joined(separator: "\n") + "\n"
                
                // Write back to file
                try updatedContent.write(to: quarterFile, atomically: true, encoding: .utf8)
            } catch {
                writeError = error
            }
        }
        
        if let error = writeError ?? coordinatorError {
            print("QuarterFileManager: Error occurred during removal: \(error)")
            throw QuarterFileError.fileOperationFailed(error.localizedDescription)
        }
    }
    
    func updateActivity(_ oldItem: ActivityItem, to newItem: ActivityItem) throws {
        guard let vault = vaultURL else {
            print("QuarterFileManager: Cannot update - no vault access")
            throw QuarterFileError.noVaultAccess
        }
        
        guard vault.startAccessingSecurityScopedResource() else {
            print("QuarterFileManager: Cannot access vault for update")
            throw QuarterFileError.noVaultAccess
        }
        defer { vault.stopAccessingSecurityScopedResource() }
        
        var writeError: Error?
        var coordinatorError: NSError?
        
        fileCoordinator.coordinate(writingItemAt: vault, options: [], error: &coordinatorError) { url in
            do {
                let baseURL = url.appendingPathComponent(baseDirectory)
                
                // Get file paths for both items
                let (oldYear, oldQuarter) = getQuarterInfo(for: oldItem.activityTime)
                let oldFile = getQuarterFilePath(year: oldYear, quarter: oldQuarter, baseURL: baseURL)
                
                let (newYear, newQuarter) = getQuarterInfo(for: newItem.activityTime)
                let newFile = getQuarterFilePath(year: newYear, quarter: newQuarter, baseURL: baseURL)
                
                // If same file, update in place
                if oldFile == newFile {
                    guard FileManager.default.fileExists(atPath: oldFile.path) else {
                        throw QuarterFileError.fileOperationFailed("Quarter file not found")
                    }
                    
                    // Read and clean content
                    let content = try String(contentsOf: oldFile, encoding: .utf8)
                    
                    // Remove old entry
                    let oldTimestamp = Int(oldItem.activityTime.timeIntervalSince1970)
                    let oldEntry = "\(oldItem.activityType.rawValue):: \(oldTimestamp)"
                    
                    // Create new entry
                    let newTimestamp = Int(newItem.activityTime.timeIntervalSince1970)
                    let newEntry = "\(newItem.activityType.rawValue):: \(newTimestamp)"
                    
                    // Get all entries and sort them
                    var entries = content.cleansedLines()
                        .filter { $0 != oldEntry }
                    entries.append(newEntry)
                    
                    // Sort entries by timestamp
                    entries.sort { line1, line2 in
                        let timestamp1 = Int(line1.components(separatedBy: ":: ")[1]) ?? 0
                        let timestamp2 = Int(line2.components(separatedBy: ":: ")[1]) ?? 0
                        return timestamp1 < timestamp2
                    }
                    
                    // Write back sorted content
                    let updatedContent = entries.joined(separator: "\n") + "\n"
                    try updatedContent.write(to: oldFile, atomically: true, encoding: .utf8)
                    
                } else {
                    // Different files - remove from old and add to new
                    if FileManager.default.fileExists(atPath: oldFile.path) {
                        let oldContent = try String(contentsOf: oldFile, encoding: .utf8)
                        let oldTimestamp = Int(oldItem.activityTime.timeIntervalSince1970)
                        let oldEntry = "\(oldItem.activityType.rawValue):: \(oldTimestamp)"
                        
                        let updatedOldContent = oldContent.components(separatedBy: .newlines)
                            .filter { !$0.isEmpty && $0 != oldEntry }
                            .joined(separator: "\n") + "\n"
                        
                        try updatedOldContent.write(to: oldFile, atomically: true, encoding: .utf8)
                    }
                    
                    // Ensure new year directory exists
                    try ensureDirectoryExists(at: baseURL.appendingPathComponent(newYear))
                    
                    // Add to new file
                    let newTimestamp = Int(newItem.activityTime.timeIntervalSince1970)
                    let newEntry = "\(newItem.activityType.rawValue):: \(newTimestamp)\n"
                    
                    if FileManager.default.fileExists(atPath: newFile.path) {
                        // Read existing content and merge
                        let existingContent = try String(contentsOf: newFile, encoding: .utf8)
                        var entries = existingContent.components(separatedBy: .newlines)
                            .filter { !$0.isEmpty }
                        entries.append(newEntry)
                        
                        // Sort entries
                        entries.sort { line1, line2 in
                            let timestamp1 = Int(line1.components(separatedBy: ":: ")[1]) ?? 0
                            let timestamp2 = Int(line2.components(separatedBy: ":: ")[1]) ?? 0
                            return timestamp1 < timestamp2
                        }
                        
                        let updatedContent = entries.joined(separator: "\n") + "\n"
                        try updatedContent.write(to: newFile, atomically: true, encoding: .utf8)
                    } else {
                        try newEntry.write(to: newFile, atomically: true, encoding: .utf8)
                    }
                }
                
            } catch {
                writeError = error
            }
        }
        
        if let error = writeError ?? coordinatorError {
            print("QuarterFileManager: Error occurred during update: \(error)")
            throw QuarterFileError.fileOperationFailed(error.localizedDescription)
        }
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
    
    func cleansedLines() -> [String] {
        // Split by both newlines and null characters
        let separators = CharacterSet.newlines.union(CharacterSet(["\0"]))
        return self
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
} 
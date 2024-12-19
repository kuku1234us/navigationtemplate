import Foundation

class ProjectFileManager {
    static let shared = ProjectFileManager()
    private let baseDirectory = "Category Notes/Projects"
    private static var uniqueOffset: Int64 = 0
    
    private init() {}
    
    func findAllProjectFiles() throws -> [URL] {
        guard let vault = ObsidianVaultAccess.shared.vaultURL else {
            throw ProjectFileError.noVaultAccess
        }
        
        guard vault.startAccessingSecurityScopedResource() else {
            throw ProjectFileError.noVaultAccess
        }
        defer { vault.stopAccessingSecurityScopedResource() }
        
        let projectsURL = vault.appendingPathComponent(baseDirectory)
        return try findMarkdownFiles(in: projectsURL)
    }
    
    private func findMarkdownFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        var results: [URL] = []
        
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        for url in contents {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues.isDirectory == true {
                // Recursively search subdirectories
                results.append(contentsOf: try findMarkdownFiles(in: url))
            } else if url.pathExtension == "md" {
                // Check if file has "notetype: Project" in frontmatter
                if try isProjectFile(url) {
                    results.append(url)
                }
            }
        }
        
        return results
    }
    
    private func isProjectFile(_ url: URL) throws -> Bool {
        let content = try String(contentsOf: url, encoding: .utf8)
        return content.contains("notetype: Project")
    }
    
    func parseTasksFromFile(_ url: URL) throws -> [TaskItem]? {
        let content = try String(contentsOf: url, encoding: .utf8)
            .replacingOccurrences(of: "\0", with: "\n")
        
        let projectName = url.deletingPathExtension().lastPathComponent
        let projectPath = url.path  // Get full path
        
        var tasks: [TaskItem] = []
        
        // Parse each line
        content.enumerateLines { [weak self] line, _ in
            
            // Check if line is a task
            if let taskLine = self?.extractTaskLine(line) {
                if let task = self?.parseTaskLine(taskLine, projectName: projectName, projectPath: projectPath) {
                    tasks.append(task)
                }
            }
        }
        
        return tasks.isEmpty ? nil : tasks
    }
    
    private func extractTaskLine(_ line: String) -> String? {
        // Updated pattern to match:
        // 1. Optional ">" followed by optional spaces
        // 2. Optional spaces, then "-", then optional spaces
        // 3. "[" followed by any character followed by "]"
        let pattern = "^(>\\s*)?\\s*-\\s*\\[.\\]"
        
        if line.range(of: pattern, options: .regularExpression) != nil {
            
            // If line starts with ">", remove it and any following spaces
            if line.hasPrefix(">") {
                let trimmed = line.drop { $0 == ">" || $0 == " " || $0 == "-" }
                return String(trimmed)
            }
            
            // Otherwise, just trim leading spaces and dash
            let trimmed = line.trimmingCharacters(in: .whitespaces)
                .drop { $0 == "-" || $0 == " " }

            return String(trimmed)
        }
        
        return nil
    }
    
    private func parseTaskLine(_ line: String, projectName: String, projectPath: String) -> TaskItem? {
        // Extract status character between [ and ]
        let statusPattern = "\\[(.?)\\]"
        let isCompleted: Bool
        if let statusMatch = line.range(of: statusPattern, options: .regularExpression) {
            let statusChar = line[statusMatch].dropFirst().dropLast().first ?? " "
            isCompleted = statusChar == "x"  // For now, only "x" means completed
        } else {
            return nil  // Invalid task line
        }
        
        // Remove the status marker and trim
        let line = line.replacingOccurrences(of: "\\[.\\]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // Extract task name (up to first #tag, (due::, or <span)
        var taskName = ""
        var remainingLine = line
        
        // Find first occurrence of each boundary
        let hashIndex = line.range(of: " #")?.lowerBound
        let dueIndex = line.range(of: "(due::")?.lowerBound
        let spanIndex = line.range(of: "<span")?.lowerBound
        
        // Get the earliest boundary
        var endIndex = line.endIndex
        if let hash = hashIndex {
            endIndex = hash
        }
        if let due = dueIndex {
            endIndex = min(endIndex, due)
        }
        if let span = spanIndex {
            endIndex = min(endIndex, span)
        }
        
        // Extract task name and remaining line
        taskName = String(line[..<endIndex]).trimmingCharacters(in: .whitespaces)
        if endIndex < line.endIndex {
            remainingLine = String(line[endIndex...])
        }
        
        // Parse due date if exists
        var dueDate: Date?
        if let dueDateRange = remainingLine.range(of: "\\(due:: \\d{4}-\\d{2}-\\d{2}\\)", options: .regularExpression) {
            let dueDateStr = remainingLine[dueDateRange]
                .replacingOccurrences(of: "(due:: ", with: "")
                .replacingOccurrences(of: ")", with: "")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dueDate = formatter.date(from: dueDateStr)
        }
        
        // Parse tags
        let tags = remainingLine.components(separatedBy: " ")
            .filter { $0.hasPrefix("#") }
            .map { String($0.dropFirst()) }
        
        // Parse priority
        let priority: TaskPriority
        if let match = remainingLine.firstMatch(of: /priority">(\w+)</)?.1 {
            let priorityStr = String(match)
            if let parsedPriority = TaskPriority(rawValue: priorityStr) {
                priority = parsedPriority
            } else {
                priority = .normal
            }
        } else {
            priority = .normal
        }
        
        // Parse creation time
        var timestamp: Int64 = 0
        var timeStr: String = ""
        if let range = remainingLine.range(of: "createTime\">\\d+<", options: .regularExpression) {
            timeStr = String(remainingLine[range].dropFirst(12).dropLast(1))
        } else {
            timeStr = String(Int64(Date().timeIntervalSince1970 * 1000))  // Convert current time to milliseconds
        }

        timestamp = Int64(timeStr) ?? 0

        var createTime = Date()
        createTime = Date(timeIntervalSince1970: TimeInterval(timestamp/1000))

        return TaskItem(
            id: timestamp,
            name: taskName,
            isCompleted: isCompleted,
            priority: priority,
            projectName: projectName,
            projectFilePath: projectPath,  // Add project path
            dueDate: dueDate,
            tags: tags,
            createTime: createTime
        )
    }
    
    enum ProjectFileError: Error {
        case noVaultAccess
        case invalidFormat
    }
    
    func removeTask(_ task: TaskItem) throws {
        let file = URL(fileURLWithPath: task.projectFilePath)
        try removeTaskFromFile(task, in: file)
    }
    
    private func removeTaskFromFile(_ task: TaskItem, in file: URL) throws {
        let content = try String(contentsOf: file, encoding: .utf8)
        var lines = content.components(separatedBy: .newlines)
        
        // Find and remove the task line
        if let index = lines.firstIndex(where: { line in 
            line.contains("createTime\">\(task.id)<")
        }) {
            lines.remove(at: index)
            let updatedContent = lines.joined(separator: "\n")
            try updatedContent.write(to: file, atomically: true, encoding: .utf8)
        }
    }
    
    func updateTaskCompletion(_ task: TaskItem, isCompleted: Bool) throws {
        let file = URL(fileURLWithPath: task.projectFilePath)
        let content = try String(contentsOf: file, encoding: .utf8)
        var lines = content.components(separatedBy: .newlines)
        
        // Find and update the task line
        if let index = lines.firstIndex(where: { line in
            line.contains("createTime\">\(task.id)<")
        }) {
            let line = lines[index]
            let updatedLine = line.replacingOccurrences(
                of: "\\[.\\]",
                with: isCompleted ? "[x]" : "[ ]",
                options: .regularExpression
            )
            lines[index] = updatedLine
            let updatedContent = lines.joined(separator: "\n")
            try updatedContent.write(to: file, atomically: true, encoding: .utf8)
        }
    }
} 
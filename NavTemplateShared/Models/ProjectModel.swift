import Foundation
import Combine
import SwiftUI

public class ProjectMetadata: ObservableObject, Codable {
    public let projId: Int64          // Unix timestamp
    public let banner: URL?           // Image URL
    @Published public var projectStatus: ProjectStatus
    public let noteType: String       // Always "Project"
    public let creationTime: Date     // File creation time
    @Published public var modifiedTime: Date     // File last modified time
    public let filePath: String       // Full path to project file
    public let icon: String  // Add icon field
    
    enum CodingKeys: String, CodingKey {
        case projId, banner, projectStatus, noteType, creationTime, modifiedTime, filePath, icon
    }
    
    // Encoding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projId, forKey: .projId)
        try container.encode(banner, forKey: .banner)
        try container.encode(projectStatus.rawValue, forKey: .projectStatus)  // Encode raw value
        try container.encode(noteType, forKey: .noteType)
        try container.encode(creationTime, forKey: .creationTime)
        try container.encode(modifiedTime, forKey: .modifiedTime)
        try container.encode(filePath, forKey: .filePath)
        try container.encode(icon, forKey: .icon)
    }
    
    // Decoding
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projId = try container.decode(Int64.self, forKey: .projId)
        banner = try container.decodeIfPresent(URL.self, forKey: .banner)
        let statusString = try container.decode(String.self, forKey: .projectStatus)
        projectStatus = ProjectStatus.from(statusString)  // Convert from string
        noteType = try container.decode(String.self, forKey: .noteType)
        creationTime = try container.decode(Date.self, forKey: .creationTime)
        modifiedTime = try container.decode(Date.self, forKey: .modifiedTime)
        filePath = try container.decode(String.self, forKey: .filePath)
        icon = try container.decode(String.self, forKey: .icon)
    }
    
    public init(
        projId: Int64,
        banner: URL? = nil,
        projectStatus: ProjectStatus,
        noteType: String,
        creationTime: Date,
        modifiedTime: Date,
        filePath: String,
        icon: String = "folder"  // Default icon
    ) {
        self.projId = projId
        self.banner = banner
        self.projectStatus = projectStatus
        self.noteType = noteType
        self.creationTime = creationTime
        self.modifiedTime = modifiedTime
        self.filePath = filePath
        self.icon = icon
    }
    
    public func updateStatus(_ newStatus: ProjectStatus) {
        projectStatus = newStatus
        modifiedTime = Date()
        
        // TODO: Update the actual file's frontmatter
        // This would be implemented when we add file writing functionality
    }
    
    public var projectName: String {
        URL(fileURLWithPath: filePath).lastPathComponent.replacingOccurrences(of: ".md", with: "")
    }
}

@available(iOS 16.0, *)
extension ProjectMetadata: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

public enum ProjectStatus: String, Codable {
    case idea = "Idea"
    case progress = "Progress"
    case done = "Done"
    
    public var icon: String {
        switch self {
        case .idea:
            return "lightbulb"
        case .progress:
            return "gearshape.2"
        case .done:
            return "checkmark.seal"
        }
    }
    
    public var selectedIcon: String {
        switch self {
        case .idea:
            return "lightbulb.fill"
        case .progress:
            return "gearshape.2.fill"
        case .done:
            return "checkmark.seal.fill"
        }
    }
    
    public static func from(_ string: String) -> ProjectStatus {
        switch string.lowercased() {
        case "idea": return .idea
        case "progress": return .progress
        case "done": return .done
        default: return .progress
        }
    }
}

// Define the project settings structure
public struct ProjectSettings: Codable {
    public var selectedProjects: Set<Int64>
    public var projectOrder: [Int64]  // Array of projIds in display order
    
    public init(selectedProjects: Set<Int64> = [], projectOrder: [Int64] = []) {
        self.selectedProjects = selectedProjects
        self.projectOrder = projectOrder
    }
}

public class ProjectModel: ObservableObject {
    public private(set) static var shared: ProjectModel = {
        let instance = ProjectModel()
        return instance
    }()
    
    // Prevent additional instances
    public static func getInstance() -> ProjectModel {
        return shared
    }
    
    @Published public private(set) var projects: [ProjectMetadata] = []
    
    // Add project settings
    @Published public private(set) var settings: ProjectSettings {
        didSet {
            // Save to UserDefaults whenever it changes
            saveProjectSettings()
        }
    }
    
    private init() {
        // Load project settings from UserDefaults
        self.settings = Self.loadProjectSettings()
        loadProjects()  // Load projects after settings
        
        // Initialize with default settings if needed
        if settings.projectOrder.isEmpty && !projects.isEmpty {
            let allProjectIds = projects.map { $0.projId }
            updateProjectSettings(
                selectedProjects: Set(allProjectIds),
                projectOrder: allProjectIds
            )
        }
    }
    
    // Methods to handle project settings
    private static func loadProjectSettings() -> ProjectSettings {
        if let data = UserDefaults.standard.data(forKey: "ProjectSettings"),
           let settings = try? JSONDecoder().decode(ProjectSettings.self, from: data) {
            return settings
        }
        return ProjectSettings()  // Return empty settings if nothing saved
    }
    
    private func saveProjectSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "ProjectSettings")
        }
    }
    
    // Public method to update settings
    public func updateProjectSettings(
        selectedProjects: Set<Int64>? = nil,
        projectOrder: [Int64]? = nil
    ) {
        var newSettings = settings
        if let selectedProjects = selectedProjects {
            newSettings.selectedProjects = selectedProjects
        }
        if let projectOrder = projectOrder {
            newSettings.projectOrder = projectOrder
        }
        settings = newSettings
    }
    
    // Helper method to check if a project is selected
    public func isProjectSelected(_ projId: Int64) -> Bool {
        return settings.selectedProjects.contains(projId)
    }
    
    // Helper method to toggle project selection
    public func toggleProjectSelection(_ projId: Int64) {
        var selectedProjects = settings.selectedProjects
        if selectedProjects.contains(projId) {
            selectedProjects.remove(projId)
        } else {
            selectedProjects.insert(projId)
        }
        updateProjectSettings(selectedProjects: selectedProjects)
    }
    
    public func loadProjects() {
        do {
            let projectFiles = try ProjectFileManager.shared.findAllProjectFiles()
            var projectMetadata: [ProjectMetadata] = []
            
            for fileURL in projectFiles {
                if let metadata = try parseProjectMetadata(from: fileURL) {
                    projectMetadata.append(metadata)
                }
            }
            
            // Sort by modified time, newest first
            projectMetadata.sort { $0.modifiedTime > $1.modifiedTime }
            
            // Assign immediately so other components can access
            self.projects = projectMetadata
            
            // Notify observers on main thread
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            print("Error loading projects: \(error)")
        }
    }
    
    private func parseProjectMetadata(from fileURL: URL) throws -> ProjectMetadata? {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        // Find frontmatter boundaries
        guard let startIndex = lines.firstIndex(of: "---") else { return nil }
        guard let endIndex = lines.dropFirst(startIndex + 1).firstIndex(of: "---") else { return nil }
        
        // Extract frontmatter
        let frontmatter = lines[(startIndex + 1)..<(startIndex + 1 + endIndex)]
        var metadata: [String: String] = [:]
        
        for line in frontmatter {
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: CharacterSet.whitespaces)
                let value = parts[1].trimmingCharacters(in: CharacterSet.whitespaces)
                metadata[key] = value
            }
        }
        
        // Get file attributes
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let creationDate = fileAttributes[.creationDate] as? Date ?? Date()
        let modificationDate = fileAttributes[.modificationDate] as? Date ?? Date()
        
        // Parse projId (default to file creation time if not found)
        let projId = Int64(metadata["projId"] ?? "") ?? Int64(creationDate.timeIntervalSince1970)
        
        // Parse banner URL
        var bannerURL: URL? = nil
        if let bannerPath = metadata["banner"] {
            bannerURL = URL(string: bannerPath)
        }
        
        return ProjectMetadata(
            projId: projId,
            banner: bannerURL,
            projectStatus: ProjectStatus.from(metadata["projectStatus"] ?? "Progress"),
            noteType: metadata["notetype"] ?? "Project",
            creationTime: creationDate,
            modifiedTime: modificationDate,
            filePath: fileURL.path,
            icon: metadata["icon"] ?? "folder"
        )
    }
    
    // Add the helper methods from ProjectList
    public func getProject(withId id: Int64) -> ProjectMetadata? {
        projects.first { $0.projId == id }
    }
    
    public func getProject(atPath path: String) -> ProjectMetadata? {
        projects.first { $0.filePath == path }
    }
    
    public func getActiveProjects() -> [ProjectMetadata] {
        projects.filter { $0.projectStatus == .progress }
    }
    
    public func getProjectsByStatus(_ status: ProjectStatus) -> [ProjectMetadata] {
        projects.filter { $0.projectStatus == status }
    }
    
    // Prevent copying
    private func copy() -> ProjectModel {
        return self
    }
    
    // Prevent additional instances through NSCopying if needed
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    // Prevent additional instances through coding
    private func encode(with coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func decode(with coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var inboxProject: ProjectMetadata {
        // Return Inbox project or create if doesn't exist
        if let inbox = projects.first(where: { 
            URL(fileURLWithPath: $0.filePath).lastPathComponent == "Inbox.md"
        }) {
            return inbox
        }
        
        // Create default inbox project if none exists
        // This is a simplified version - you'll need to implement proper inbox creation
        return ProjectMetadata(
            projId: Int64(Date().timeIntervalSince1970),
            projectStatus: .progress,
            noteType: "Project",
            creationTime: Date(),
            modifiedTime: Date(),
            filePath: "Category Notes/Projects/Inbox.md",
            icon: "tray.and.arrow.down"
        )
    }
    
    public func updateProjectModifiedTime(_ project: ProjectMetadata, to date: Date) {
        if let index = projects.firstIndex(where: { $0.projId == project.projId }) {
            projects[index].modifiedTime = date  // Now we can directly modify the property
            
            DispatchQueue.main.async {
                // Force UI update
                self.objectWillChange.send()
            }
        }
    }
    
    // Helper to get sorted projects
    public var sortedProjects: [ProjectMetadata] {
        let orderDict = Dictionary(
            uniqueKeysWithValues: settings.projectOrder.enumerated().map { ($1, $0) }
        )
        
        return projects.sorted { project1, project2 in
            let index1 = orderDict[project1.projId] ?? Int.max
            let index2 = orderDict[project2.projId] ?? Int.max
            return index1 < index2
        }
    }
}

#if DEBUG
extension ProjectModel {
    static func resetSharedInstance() {
        shared = ProjectModel()
    }
}
#endif 
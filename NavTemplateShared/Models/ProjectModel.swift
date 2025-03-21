import Foundation
import Combine
import SwiftUI

public class ProjectMetadata: ObservableObject, Codable {
    public let projId: Int64          // Unix timestamp
    public let banner: URL?           // Image URL
    @Published public var projectStatus: ProjectStatus
    public let noteType: String
    public let creationTime: Date
    @Published public var modifiedTime: Date
    public let filePath: String
    public let icon: String?  // Changed back to String to store icon filename
    
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
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
    }
    
    public init(
        projId: Int64,
        banner: URL? = nil,
        projectStatus: ProjectStatus,
        noteType: String,
        creationTime: Date,
        modifiedTime: Date,
        filePath: String,
        icon: String? = nil  // Updated initializer
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
    
    // Add at the top with other static properties
    private static let lastSelectedProjIdKey = "LastSelectedProjId"
    
    // Modified lastSelectedProjId property
    public var lastSelectedProjId: Int64 {
        get {
            let saved = UserDefaults.standard.integer(forKey: Self.lastSelectedProjIdKey)
            if saved == 0 {
                // Return inbox project's ID since inboxProject always exists
                return inboxProject.projId
            }
            return Int64(saved)
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: Self.lastSelectedProjIdKey)
            objectWillChange.send()
        }
    }
    
    private init() {
        // Load project settings from UserDefaults
        self.settings = Self.loadProjectSettings()
        
        // Start loading projects asynchronously
        Task {
            await loadProjects()
            
            // Initialize with default settings if needed
            await MainActor.run {
                if settings.projectOrder.isEmpty && !projects.isEmpty {
                    let allProjectIds = projects.map { $0.projId }
                    updateProjectSettings(
                        selectedProjects: Set(allProjectIds),
                        projectOrder: allProjectIds
                    )
                }
            }
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
        saveProjectsToUserDefaults()
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
    
    @MainActor
    public func loadProjects() async {
        do {
            // First try to load from ProjectsSummary.md
            if let projects = try loadFromProjectsSummary() {
                // Update projects array
                self.projects = projects
                
                // Load tasks for each project
                var allTasks: [TaskItem] = []
                for project in projects {
                    let fileURL = URL(fileURLWithPath: project.filePath)
                    if let (content, _) = try ProjectFileManager.shared.readProjectFile(fileURL) {
                        if let tasks = ProjectFileManager.shared.parseTasksFromContent(
                            content,
                            projId: project.projId
                        ) {
                            allTasks.append(contentsOf: tasks)
                        }
                    }
                }
                
                // Update TaskModel
                TaskModel.shared.updateAllTasks(allTasks)
                
                // Update settings with current project IDs
                updateSettingsWithCurrentProjects()
                return
            }
            
            // If ProjectsSummary.md loading fails, reconcile projects
            do {
                try await reconcileProjects()  // Add try await here
            } catch {
                Logger.shared.error("[E033] Failed to reconcile projects", error: error)
            }
            
        } catch {
            Logger.shared.error("[E031] Failed to load projects from summary", error: error)
            // If loading from summary fails, reconcile projects
            do {
                try await reconcileProjects()  // Add try await here
            } catch {
                Logger.shared.error("[E033] Failed to reconcile projects", error: error)
            }
        }
    }
    
    private func loadFromProjectsSummary() throws -> [ProjectMetadata]? {
        do {
            let summaryURL = try getProjectsSummaryURL()
            let data = try Data(contentsOf: summaryURL)
            let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            
            guard let jsonArray = jsonArray else {
                return nil
            }
            
            var projects: [ProjectMetadata] = []
            
            for json in jsonArray {
                guard let projId = json["projId"] as? Int64,
                      let projectStatus = json["projectStatus"] as? String,
                      let noteType = json["noteType"] as? String,
                      let filePath = json["filePath"] as? String else {
                    continue
                }
                
                let banner = (json["banner"] as? String).flatMap { URL(string: $0) }
                let icon = json["icon"] as? String
                
                let project = ProjectMetadata(
                    projId: projId,
                    banner: banner,
                    projectStatus: ProjectStatus.from(projectStatus),
                    noteType: noteType,
                    creationTime: Date(),  // These will be updated when we read the actual file
                    modifiedTime: Date(),
                    filePath: filePath,
                    icon: icon
                )
                
                projects.append(project)
            }
            
            return projects.isEmpty ? nil : projects
        } catch {
            Logger.shared.error("[E031] Failed to read ProjectsSummary.md", error: error)
            throw error
        }
    }
    
    private func updateSettingsWithCurrentProjects() {
        let currentProjectIds = Set(projects.map { $0.projId })
        
        // Update selected projects
        var selectedProjects = settings.selectedProjects
        selectedProjects.formIntersection(currentProjectIds)
        
        // Update project order
        var projectOrder = settings.projectOrder.filter { currentProjectIds.contains($0) }
        let newProjectIds = currentProjectIds.subtracting(Set(projectOrder))
        projectOrder.append(contentsOf: newProjectIds)
        
        // Update settings
        updateProjectSettings(
            selectedProjects: selectedProjects,
            projectOrder: projectOrder
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
        return ProjectMetadata(
            projId: Int64(Date().timeIntervalSince1970),
            projectStatus: .progress,
            noteType: "Project",
            creationTime: Date(),
            modifiedTime: Date(),
            filePath: "Category Notes/Projects/Inbox.md",
            icon: "inbox.png"  // Use appropriate default icon filename
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
    
    private struct SerializableProjectMetadata: Codable {
        let projId: Int64
        let banner: URL?
        let projectStatus: String
        let noteType: String
        let creationTime: Date
        let modifiedTime: Date
        let filePath: String
        let icon: String?  // Keep icon filename
        
        init(from project: ProjectMetadata) {
            self.projId = project.projId
            self.banner = project.banner
            self.projectStatus = project.projectStatus.rawValue
            self.noteType = project.noteType
            self.creationTime = project.creationTime
            self.modifiedTime = project.modifiedTime
            self.filePath = project.filePath
            self.icon = project.icon
        }
    }
    
    /// Updates UserDefaults with current projects state for widget access
    private func saveProjectsToUserDefaults() {
        let serializableProjects = projects.map { SerializableProjectMetadata(from: $0) }
        if let encoded = try? JSONEncoder().encode(serializableProjects) {
            UserDefaults(suiteName: "group.us.kothreat.NavTemplate")?
                .set(encoded, forKey: "CachedProjects")
        }
    }
    
    /// Loads projects from UserDefaults (used by widget)
    public func loadProjectsFromDefaults() -> [ProjectMetadata] {
        guard let defaults = UserDefaults(suiteName: "group.us.kothreat.NavTemplate"),
              let data = defaults.data(forKey: "CachedProjects"),
              let serializableProjects = try? JSONDecoder().decode([SerializableProjectMetadata].self, from: data) else {
            return []
        }
        
        return serializableProjects.map { cached in
            ProjectMetadata(
                projId: cached.projId,
                banner: cached.banner,
                projectStatus: ProjectStatus.from(cached.projectStatus),
                noteType: cached.noteType,
                creationTime: cached.creationTime,
                modifiedTime: cached.modifiedTime,
                filePath: cached.filePath,
                icon: cached.icon  // Just pass the icon filename
            )
        }
    }
    
    public func reconcileProjects() async throws {
        do {
            // Do file operations in background
            let markdownFiles = try ProjectFileManager.shared.findAllMarkdownFiles()
            var projectMetadata: [ProjectMetadata] = []
            var allTasks: [TaskItem] = []
            
            // Process files concurrently
            try await withThrowingTaskGroup(of: (ProjectMetadata?, [TaskItem]?).self) { group in
                for fileURL in markdownFiles {
                    group.addTask {
                        guard let (content, projId) = try ProjectFileManager.shared.readProjectFile(fileURL) else {
                            return (nil, nil)
                        }
                        
                        // Add try to throwing call
                        let metadata = try self.parseProjectMetadata(from: fileURL, content: content)
                        let tasks = ProjectFileManager.shared.parseTasksFromContent(content, projId: projId)
                        
                        return (metadata, tasks)
                    }
                }
                
                // Collect results
                for try await (metadata, tasks) in group {
                    if let metadata = metadata {
                        projectMetadata.append(metadata)
                    }
                    if let tasks = tasks {
                        allTasks.append(contentsOf: tasks)
                    }
                }
            }
            
            // Switch to main thread for model updates
            await MainActor.run {
                // Update the projects array first
                self.projects = projectMetadata
                
                // Get set of all current project IDs
                let currentProjectIds = Set(projectMetadata.map { $0.projId })
                
                // Update project settings
                var selectedProjects = settings.selectedProjects
                selectedProjects.formIntersection(currentProjectIds)
                
                var projectOrder = settings.projectOrder.filter { currentProjectIds.contains($0) }
                let newProjects = currentProjectIds.subtracting(Set(projectOrder))
                projectOrder.append(contentsOf: newProjects)
                
                // Update settings and notify observers
                updateProjectSettings(
                    selectedProjects: selectedProjects,
                    projectOrder: projectOrder
                )
                
                // Clean up unused icons
                let usedIcons = Set(projectMetadata.compactMap { $0.icon })
                ImageCache.shared.removeUnusedImages(folder: "icons", currentlyUsedFilenames: usedIcons)
                
                // Update tasks
                TaskModel.shared.updateAllTasks(allTasks)
                
                // Notify observers
                self.objectWillChange.send()
            }
            
            // Write summary file in background
            let summaryURL = try getProjectsSummaryURL()
            let jsonData = try JSONSerialization.data(
                withJSONObject: projectMetadata.map { self.extractMetadata(from: $0) },
                options: .prettyPrinted
            )
            try jsonData.write(to: summaryURL, options: .atomic)
            
        } catch {
            Logger.shared.error("[E032] Failed to reconcile projects", error: error)
            throw error
        }
    }
    
    private func extractMetadata(from project: ProjectMetadata) -> [String: Any] {
        var metadata: [String: Any] = [
            "projId": project.projId,
            "projectStatus": project.projectStatus.rawValue,
            "noteType": project.noteType,
            "filePath": project.filePath
        ]
        
        if let banner = project.banner {
            metadata["banner"] = banner.absoluteString
        }
        if let icon = project.icon {
            metadata["icon"] = icon
        }
        
        return metadata
    }
    
    private func getProjectsSummaryURL() throws -> URL {
        guard let vaultURL = ObsidianVaultAccess.shared.vaultURL else {
            throw ObsidianError.noVaultAccess
        }
        
        let summaryURL = vaultURL.appendingPathComponent("Category Notes/Projects/ProjectsSummary.md")
        if !FileManager.default.fileExists(atPath: summaryURL.path) {
            FileManager.default.createFile(atPath: summaryURL.path, contents: nil)
        }
        
        return summaryURL
    }
    
    // Add new method that accepts content
    private func parseProjectMetadata(from fileURL: URL, content: String) throws -> ProjectMetadata? {
        // Get file attributes - these will now use cached values
        let resourceValues = try fileURL.resourceValues(forKeys: [
            .creationDateKey,
            .contentModificationDateKey
        ])
        
        let creationDate = resourceValues.creationDate ?? Date()
        let modificationDate = resourceValues.contentModificationDate ?? Date()
        
        // Parse metadata from content
        var metadata: [String: String] = [:]
        var inFrontmatter = false
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            if line == "---" {
                inFrontmatter = !inFrontmatter
                continue
            }
            
            if inFrontmatter {
                let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    metadata[key] = value
                }
            }
        }
        
        // Verify it's a project file
        guard metadata["notetype"]?.lowercased() == "project" else {
            return nil
        }
        
        // Parse banner URL
        var bannerURL: URL? = nil
        if let bannerPath = metadata["banner"] {
            bannerURL = URL(string: bannerPath)
        }
        
        // Get or generate projId
        let projId: Int64
        if let existingId = metadata["projId"].flatMap({ Int64($0) }) {
            projId = existingId
        } else {
            // Generate new projId
            projId = Int64(creationDate.timeIntervalSince1970 * 1000)
            
            // Write the new projId to the file
            let _ = try ProjectFileManager.shared.updateFrontmatterField(
                content,
                field: "projId",
                value: String(projId),
                fileURL: fileURL
            )
        }
        
        return ProjectMetadata(
            projId: projId,
            banner: bannerURL,
            projectStatus: ProjectStatus.from(metadata["projectStatus"] ?? "Progress"),
            noteType: metadata["notetype"] ?? "Project",
            creationTime: creationDate,
            modifiedTime: modificationDate,
            filePath: fileURL.path,
            icon: metadata["icon"]
        )
    }
    
    public func getProjectFilePath(_ projId: Int64) throws -> String {
        guard let project = getProject(withId: projId) else {
            throw ProjectFileError.projectNotFound
        }
        return project.filePath
    }
}

#if DEBUG
extension ProjectModel {
    static func resetSharedInstance() {
        shared = ProjectModel()
    }
}
#endif 
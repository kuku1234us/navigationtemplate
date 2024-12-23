import Foundation
import Combine

public class ProjectMetadata: ObservableObject {
    public let projId: Int64          // Unix timestamp
    public let banner: URL?           // Image URL
    @Published public private(set) var projectStatus: ProjectStatus
    public let noteType: String       // Always "Project"
    public let creationTime: Date     // File creation time
    @Published public private(set) var modifiedTime: Date     // File last modified time
    public let filePath: String       // Full path to project file
    
    public init(
        projId: Int64,
        banner: URL? = nil,
        projectStatus: ProjectStatus,
        noteType: String,
        creationTime: Date,
        modifiedTime: Date,
        filePath: String
    ) {
        self.projId = projId
        self.banner = banner
        self.projectStatus = projectStatus
        self.noteType = noteType
        self.creationTime = creationTime
        self.modifiedTime = modifiedTime
        self.filePath = filePath
    }
    
    public func updateStatus(_ newStatus: ProjectStatus) {
        projectStatus = newStatus
        modifiedTime = Date()
        
        // TODO: Update the actual file's frontmatter
        // This would be implemented when we add file writing functionality
    }
}

public enum ProjectStatus: String {
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
    
    private init() {
        loadProjects()  // Load projects immediately when initialized
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
            
            DispatchQueue.main.async {
                self.projects = projectMetadata
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
            filePath: fileURL.path
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
}

#if DEBUG
extension ProjectModel {
    static func resetSharedInstance() {
        shared = ProjectModel()
    }
}
#endif 
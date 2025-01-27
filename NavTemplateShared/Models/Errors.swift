import Foundation

public enum ProjectFileError: Error {
    case invalidFormat
    case projectNotFound
}

extension ProjectFileError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid project file format"
        case .projectNotFound:
            return "Project not found"
        }
    }
}

public enum ObsidianError: Error {
    case noVaultAccess
    case vaultNotFound
    case vaultAccessDenied
    case fileNotFound
    case invalidFileFormat
    case invalidFrontmatter
}

extension ObsidianError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noVaultAccess:
            return "Cannot access Obsidian vault"
        case .vaultNotFound:
            return "Obsidian vault not found"
        case .vaultAccessDenied:
            return "Access to Obsidian vault denied"
        case .fileNotFound:
            return "File not found"
        case .invalidFileFormat:
            return "Invalid file format"
        case .invalidFrontmatter:
            return "Invalid or missing frontmatter section"
        }
    }
}

public enum ImageCacheError: Error {
    case downloadFailed
    case invalidImageData
    case saveFailed
}

extension ImageCacheError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download image"
        case .invalidImageData:
            return "Invalid image data"
        case .saveFailed:
            return "Failed to save image"
        }
    }
}

public enum CalendarError: Error {
    case invalidData
    case fileOperationFailed
    case eventNotFound
    case invalidDateRange
    case reconciliationFailed
}

extension CalendarError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid calendar data"
        case .fileOperationFailed:
            return "Calendar file operation failed"
        case .eventNotFound:
            return "Calendar event not found"
        case .invalidDateRange:
            return "Invalid date range"
        case .reconciliationFailed:
            return "Calendar reconciliation failed"
        }
    }
} 
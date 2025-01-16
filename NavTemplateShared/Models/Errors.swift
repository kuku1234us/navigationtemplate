import Foundation

public enum ProjectFileError: Error {
    case invalidFormat
    case projectNotFound
}

public enum ObsidianError: Error {
    case noVaultAccess
    case vaultNotFound
    case vaultAccessDenied
    case fileNotFound
    case invalidFileFormat
}

public enum ImageCacheError: Error {
    case downloadFailed
    case invalidImageData
    case saveFailed
}

public enum CalendarError: Error {
    case invalidData
    case fileOperationFailed
    case eventNotFound
    case invalidDateRange
    case reconciliationFailed
} 
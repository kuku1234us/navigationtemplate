import Foundation

public enum ProjectFileError: Error {
    case noVaultAccess
    case invalidFormat
    case projectNotFound
}

public enum ObsidianError: Error {
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
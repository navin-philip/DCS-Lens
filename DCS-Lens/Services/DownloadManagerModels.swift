import Foundation

enum DownloadStatus: Codable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded(localPath: String)
    case failed(error: String)
    
    // Custom Codable implementation if needed, especially for progress/error
    // Or simplify by just storing path/status and recreating progress/error transiently
}

struct DownloadInfo: Codable {
    let videoId: String
    var localPath: String? // Relative path within Documents directory
    var status: DownloadStatus = .notDownloaded
    
    // Transient properties not saved directly, but useful at runtime
    var downloadTask: URLSessionDownloadTask? = nil
    var progressObserver: NSKeyValueObservation? = nil
    
    // MARK: - Codable Conformance (Manual Implementation)
    
    // Define coding keys for persistent properties only
    enum CodingKeys: String, CodingKey {
        case videoId
        case localPath
        case status
    }
    
    // Custom decoder init
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        videoId = try container.decode(String.self, forKey: .videoId)
        localPath = try container.decodeIfPresent(String.self, forKey: .localPath)
        status = try container.decode(DownloadStatus.self, forKey: .status)
        // downloadTask and progressObserver are not decoded, remain nil
    }
    
    // Custom encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoId, forKey: .videoId)
        try container.encodeIfPresent(localPath, forKey: .localPath)
        try container.encode(status, forKey: .status)
        // downloadTask and progressObserver are not encoded
    }
    
    // Add a non-throwing initializer for convenience when creating new instances
    init(videoId: String, localPath: String? = nil, status: DownloadStatus = .notDownloaded) {
        self.videoId = videoId
        self.localPath = localPath
        self.status = status
        self.downloadTask = nil
        self.progressObserver = nil
    }
} 
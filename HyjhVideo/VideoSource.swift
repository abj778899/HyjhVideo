import Foundation

struct VideoSource: Identifiable, Codable, Equatable {
    let id: UUID
    let url: String
    let type: String // m3u8, mp4, flv, etc
    let quality: String?
    let title: String?
    let pageURL: String?
    let capturedAt: Date

    init(url: String, type: String, quality: String? = nil, title: String? = nil, pageURL: String? = nil) {
        self.id = UUID()
        self.url = url
        self.type = type
        self.quality = quality
        self.title = title
        self.pageURL = pageURL
        self.capturedAt = Date()
    }

    var isPlayable: Bool {
        let playableTypes = ["m3u8", "mp4", "m4v", "mov", "ts", "flv"]
        return playableTypes.contains(type.lowercased())
    }

    var fileExtension: String {
        return type.lowercased()
    }
}

enum DownloadStatus: String, Codable {
    case pending
    case downloading
    case completed
    case failed
    case paused
}

struct DownloadItem: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceURL: String
    let type: String
    var title: String
    var progress: Double
    var status: DownloadStatus
    var localPath: String?
    let createdAt: Date
    var totalBytes: Int64
    var downloadedBytes: Int64

    init(sourceURL: String, type: String, title: String) {
        self.id = UUID()
        self.sourceURL = sourceURL
        self.type = type
        self.title = title
        self.progress = 0
        self.status = .pending
        self.localPath = nil
        self.createdAt = Date()
        self.totalBytes = 0
        self.downloadedBytes = 0
    }
}

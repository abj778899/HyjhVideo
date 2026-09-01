import Foundation
import Combine
import AVFoundation

class DownloadManager: NSObject, ObservableObject {
    @Published var downloads: [DownloadItem] = []
    @Published var isDownloading = false

    private var session: URLSession!
    private var m3u8Downloaders: [UUID: M3U8Downloader] = [:]
    private let fileManager = FileManager.default

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        loadDownloads()
    }

    // MARK: - Public Methods
    func startDownload(source: VideoSource, title: String? = nil) {
        let downloadTitle = title ?? source.title ?? "视频_\(source.type.uppercased())"
        var item = DownloadItem(sourceURL: source.url, type: source.type, title: downloadTitle)
        item.status = .downloading
        downloads.append(item)

        if source.type.lowercased() == "m3u8" {
            startM3U8Download(item: item)
        } else {
            startFileDownload(item: item)
        }

        saveDownloads()
    }

    func pauseDownload(_ item: DownloadItem) {
        if let index = downloads.firstIndex(where: { $0.id == item.id }) {
            downloads[index].status = .paused
            if let downloader = m3u8Downloaders[item.id] {
                downloader.cancel()
                m3u8Downloaders.removeValue(forKey: item.id)
            }
            saveDownloads()
        }
    }

    func resumeDownload(_ item: DownloadItem) {
        if let index = downloads.firstIndex(where: { $0.id == item.id }) {
            downloads[index].status = .downloading
            if item.type.lowercased() == "m3u8" {
                startM3U8Download(item: downloads[index])
            } else {
                startFileDownload(item: downloads[index])
            }
            saveDownloads()
        }
    }

    func cancelDownload(_ item: DownloadItem) {
        if let index = downloads.firstIndex(where: { $0.id == item.id }) {
            if let downloader = m3u8Downloaders[item.id] {
                downloader.cancel()
                m3u8Downloaders.removeValue(forKey: item.id)
            }
            // 删除本地文件
            if let path = item.localPath {
                let url = URL(fileURLWithPath: path)
                try? fileManager.removeItem(at: url)
            }
            downloads.remove(at: index)
            saveDownloads()
        }
    }

    func deleteDownload(_ item: DownloadItem) {
        if let index = downloads.firstIndex(where: { $0.id == item.id }) {
            if let path = item.localPath {
                let url = URL(fileURLWithPath: path)
                try? fileManager.removeItem(at: url)
            }
            downloads.remove(at: index)
            saveDownloads()
        }
    }

    func getDownloadedVideos() -> [DownloadItem] {
        return downloads.filter { $0.status == .completed }
    }

    // MARK: - Private Methods
    private func startFileDownload(item: DownloadItem) {
        guard let url = URL(string: item.sourceURL) else {
            updateDownload(id: item.id, status: .failed, progress: 0)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        // 添加Referer
        if let referer = getReferer(for: item.sourceURL) {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }

        let task = session.downloadTask(with: request)
        task.taskDescription = item.id.uuidString
        task.resume()
    }

    private func startM3U8Download(item: DownloadItem) {
        let downloader = M3U8Downloader(url: item.sourceURL, title: item.title, session: session) { [weak self] progress, status, localURL in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let index = self.downloads.firstIndex(where: { $0.id == item.id }) {
                    self.downloads[index].progress = progress
                    self.downloads[index].status = status
                    if let localURL = localURL {
                        self.downloads[index].localPath = localURL.path
                    }
                    if status == .completed || status == .failed {
                        self.m3u8Downloaders.removeValue(forKey: item.id)
                    }
                    self.saveDownloads()
                }
            }
        }
        m3u8Downloaders[item.id] = downloader
        downloader.start()
    }

    private func updateDownload(id: UUID, status: DownloadStatus, progress: Double) {
        DispatchQueue.main.async {
            if let index = self.downloads.firstIndex(where: { $0.id == id }) {
                self.downloads[index].status = status
                self.downloads[index].progress = progress
                self.saveDownloads()
            }
        }
    }

    private func getReferer(for url: String) -> String? {
        if url.contains("douyin") || url.contains("douyinvod") || url.contains("douyincdn") {
            return "https://www.douyin.com/"
        } else if url.contains("kuaishou") || url.contains("ksyun") {
            return "https://www.kuaishou.com/"
        } else if url.contains("bilibili") || url.contains("hdslb") {
            return "https://www.bilibili.com/"
        }
        return nil
    }

    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let videoDir = documentsDirectory.appendingPathComponent("DownloadedVideos", isDirectory: true)
        if !fileManager.fileExists(atPath: videoDir.path) {
            try? fileManager.createDirectory(at: videoDir, withIntermediateDirectories: true)
        }
        return videoDir
    }

    private func saveDownloads() {
        do {
            let data = try JSONEncoder().encode(downloads)
            let url = getDocumentsDirectory().appendingPathComponent("downloads.json")
            try data.write(to: url)
        } catch {
            print("Failed to save downloads: \(error)")
        }
    }

    private func loadDownloads() {
        do {
            let url = getDocumentsDirectory().appendingPathComponent("downloads.json")
            if fileManager.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                downloads = try JSONDecoder().decode([DownloadItem].self, from: data)
            }
        } catch {
            print("Failed to load downloads: \(error)")
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let taskDescription = downloadTask.taskDescription,
              let uuid = UUID(uuidString: taskDescription),
              let index = downloads.firstIndex(where: { $0.id == uuid }) else {
            return
        }

        let item = downloads[index]
        let fileExtension = item.type.lowercased()
        let safeTitle = item.title
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "*", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "<", with: "_")
            .replacingOccurrences(of: ">", with: "_")
            .replacingOccurrences(of: "|", with: "_")

        let destinationURL = getDocumentsDirectory().appendingPathComponent("\(safeTitle).\(fileExtension)")

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)

            DispatchQueue.main.async {
                self.downloads[index].status = .completed
                self.downloads[index].progress = 1.0
                self.downloads[index].localPath = destinationURL.path
                self.saveDownloads()
            }
        } catch {
            DispatchQueue.main.async {
                self.downloads[index].status = .failed
                self.saveDownloads()
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let taskDescription = downloadTask.taskDescription,
              let uuid = UUID(uuidString: taskDescription),
              let index = downloads.firstIndex(where: { $0.id == uuid }) else {
            return
        }

        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0

        DispatchQueue.main.async {
            self.downloads[index].progress = progress
            self.downloads[index].downloadedBytes = totalBytesWritten
            self.downloads[index].totalBytes = totalBytesExpectedToWrite
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let taskDescription = downloadTask.taskDescription,
              let uuid = UUID(uuidString: taskDescription),
              let index = downloads.firstIndex(where: { $0.id == uuid }) else {
            return
        }

        if error != nil {
            DispatchQueue.main.async {
                self.downloads[index].status = .failed
                self.saveDownloads()
            }
        }
    }
}

// MARK: - M3U8 Downloader
class M3U8Downloader: NSObject {
    private let url: String
    private let title: String
    private let session: URLSession
    private let progressHandler: (Double, DownloadStatus, URL?) -> Void

    private var tempDir: URL!
    private var segments: [String] = []
    private var currentSegmentIndex = 0
    private var totalSegments = 0
    private var currentTask: URLSessionDownloadTask?
    private var isCancelled = false

    init(url: String, title: String, session: URLSession, progressHandler: @escaping (Double, DownloadStatus, URL?) -> Void) {
        self.url = url
        self.title = title
        self.session = session
        self.progressHandler = progressHandler
        super.init()
    }

    func start() {
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        guard let playlistURL = URL(string: url) else {
            progressHandler(0, .failed, nil)
            return
        }

        var request = URLRequest(url: playlistURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        if let referer = getReferer(for: url) {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }

        let task = session.downloadTask(with: request) { [weak self] location, response, error in
            guard let self = self, let location = location else {
                self?.progressHandler(0, .failed, nil)
                return
            }
            self.parseM3U8Playlist(at: location)
        }
        task.resume()
    }

    func cancel() {
        isCancelled = true
        currentTask?.cancel()
    }

    private func parseM3U8Playlist(at location: URL) {
        do {
            let content = try String(contentsOf: location, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)

            var segmentURLs: [String] = []
            var baseURL = URL(string: url)?.deletingLastPathComponent()

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("#") {
                    continue
                }

                if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                    segmentURLs.append(trimmed)
                } else if let base = baseURL {
                    let fullURL = base.appendingPathComponent(trimmed).absoluteString
                    segmentURLs.append(fullURL)
                }
            }

            if segmentURLs.isEmpty {
                progressHandler(0, .failed, nil)
                return
            }

            segments = segmentURLs
            totalSegments = segmentURLs.count
            currentSegmentIndex = 0
            downloadNextSegment()
        } catch {
            progressHandler(0, .failed, nil)
        }
    }

    private func downloadNextSegment() {
        guard !isCancelled else { return }
        guard currentSegmentIndex < totalSegments else {
            mergeSegments()
            return
        }

        let segmentURL = segments[currentSegmentIndex]
        guard let url = URL(string: segmentURL) else {
            currentSegmentIndex += 1
            downloadNextSegment()
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        if let referer = getReferer(for: segmentURL) {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }

        let task = session.downloadTask(with: request) { [weak self] location, response, error in
            guard let self = self else { return }
            guard let location = location, error == nil else {
                self.currentSegmentIndex += 1
                self.downloadNextSegment()
                return
            }

            let segmentFile = self.tempDir.appendingPathComponent("segment_\(self.currentSegmentIndex).ts")
            do {
                if FileManager.default.fileExists(atPath: segmentFile.path) {
                    try FileManager.default.removeItem(at: segmentFile)
                }
                try FileManager.default.moveItem(at: location, to: segmentFile)
            } catch {
                print("Failed to save segment: \(error)")
            }

            self.currentSegmentIndex += 1
            let progress = Double(self.currentSegmentIndex) / Double(self.totalSegments)
            self.progressHandler(progress, .downloading, nil)

            self.downloadNextSegment()
        }
        currentTask = task
        task.resume()
    }

    private func mergeSegments() {
        let safeTitle = title
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "*", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "<", with: "_")
            .replacingOccurrences(of: ">", with: "_")
            .replacingOccurrences(of: "|", with: "_")

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoDir = documentsDir.appendingPathComponent("DownloadedVideos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: videoDir.path) {
            try? FileManager.default.createDirectory(at: videoDir, withIntermediateDirectories: true)
        }

        let outputURL = videoDir.appendingPathComponent("\(safeTitle).ts")

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        FileManager.default.createFile(atPath: outputURL.path, contents: nil)

        guard let handle = try? FileHandle(forWritingTo: outputURL) else {
            progressHandler(0, .failed, nil)
            return
        }

        for i in 0..<totalSegments {
            let segmentFile = tempDir.appendingPathComponent("segment_\(i).ts")
            if let data = try? Data(contentsOf: segmentFile) {
                handle.write(data)
            }
        }

        handle.closeFile()

        try? FileManager.default.removeItem(at: tempDir)

        progressHandler(1.0, .completed, outputURL)
    }

    private func getReferer(for url: String) -> String? {
        if url.contains("douyin") || url.contains("douyinvod") || url.contains("douyincdn") {
            return "https://www.douyin.com/"
        } else if url.contains("kuaishou") || url.contains("ksyun") {
            return "https://www.kuaishou.com/"
        } else if url.contains("bilibili") || url.contains("hdslb") {
            return "https://www.bilibili.com/"
        }
        return nil
    }
}

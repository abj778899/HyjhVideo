import SwiftUI

struct DownloadListView: View {
    @ObservedObject var downloadManager: DownloadManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingLocalVideo = false
    @State private var selectedVideoURL: URL?

    var body: some View {
        NavigationView {
            List {
                if downloadManager.downloads.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("暂无下载任务")
                                .foregroundColor(.secondary)
                            Text("在视频播放页面点击下载按钮开始下载")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    ForEach(downloadManager.downloads) { item in
                        DownloadItemRow(item: item, downloadManager: downloadManager)
                    }
                }
            }
            .navigationTitle("下载管理")
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingLocalVideo) {
                if let url = selectedVideoURL {
                    LocalVideoPlayerView(fileURL: url, title: "本地视频")
                }
            }
        }
    }
}

struct DownloadItemRow: View {
    let item: DownloadItem
    let downloadManager: DownloadManager
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(item.type.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                statusView
            }

            if item.status == .downloading || item.status == .paused {
                ProgressView(value: item.progress)
                    .progressViewStyle(LinearProgressViewStyle())

                HStack {
                    Text("\(Int(item.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if item.totalBytes > 0 {
                        Text("\(formatBytes(item.downloadedBytes)) / \(formatBytes(item.totalBytes))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if item.status == .downloading {
                        Button(action: {
                            downloadManager.pauseDownload(item)
                        }) {
                            Image(systemName: "pause.circle")
                                .font(.title2)
                        }
                    } else if item.status == .paused {
                        Button(action: {
                            downloadManager.resumeDownload(item)
                        }) {
                            Image(systemName: "play.circle")
                                .font(.title2)
                        }
                    }

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.circle")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            } else if item.status == .completed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("下载完成")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let path = item.localPath {
                        let fileURL = URL(fileURLWithPath: path)
                        Button(action: {
                            // 播放本地视频
                            NotificationCenter.default.post(name: NSNotification.Name("PlayLocalVideo"), object: fileURL)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }

                        Button(action: {
                            // 分享视频
                            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootVC = windowScene.windows.first?.rootViewController {
                                rootVC.present(activityVC, animated: true)
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                        }
                    }

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.circle")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            } else if item.status == .failed {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("下载失败")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        downloadManager.resumeDownload(item)
                    }) {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.title2)
                    }

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.circle")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("确认删除"),
                message: Text("确定要删除这个下载任务吗？"),
                primaryButton: .destructive(Text("删除")) {
                    downloadManager.cancelDownload(item)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var statusView: some View {
        Group {
            switch item.status {
            case .pending:
                Text("等待中")
                    .font(.caption)
                    .foregroundColor(.secondary)
            case .downloading:
                Text("下载中")
                    .font(.caption)
                    .foregroundColor(.blue)
            case .paused:
                Text("已暂停")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .completed:
                Text("已完成")
                    .font(.caption)
                    .foregroundColor(.green)
            case .failed:
                Text("失败")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var viewModel = SourceCaptureViewModel()
    @StateObject private var downloadManager = DownloadManager()
    @State private var showSourceList = false
    @State private var showDownloadList = false
    @State private var showVideoPlayer = false
    @State private var selectedVideoURL = ""
    @State private var selectedVideoTitle = ""
    @State private var showDownloadDialog = false
    @State private var selectedDownloadSource: VideoSource?
    @State private var downloadTitle = ""
    @State private var showLocalVideoPlayer = false
    @State private var localVideoURL: URL?

    var body: some View {
        NavigationView {
            ZStack {
                WebView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.bottom)

                // 加载进度条
                if viewModel.isLoading {
                    VStack {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .padding(.horizontal)
                        Spacer()
                    }
                }

                // 错误提示
                if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button(action: {
                            viewModel.reload()
                        }) {
                            Text("重新加载")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }

                // 悬浮按钮 - 视频源
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // 下载管理按钮
                            Button(action: {
                                showDownloadList = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 50, height: 50)
                                        .shadow(radius: 4)
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                    if downloadManager.downloads.contains(where: { $0.status == .downloading }) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 12, height: 12)
                                            .offset(x: 18, y: -18)
                                    }
                                }
                            }

                            // 视频源按钮
                            Button(action: {
                                showSourceList = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 50, height: 50)
                                        .shadow(radius: 4)
                                    Image(systemName: "film")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                    if viewModel.capturedSources.count > 0 {
                                        Text("\(viewModel.capturedSources.count)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                            .offset(x: 18, y: -18)
                                    }
                                }
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle(viewModel.pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.canGoBack {
                        Button(action: {
                            viewModel.goBack()
                        }) {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if viewModel.canGoForward {
                            Button(action: {
                                viewModel.goForward()
                            }) {
                                Image(systemName: "chevron.right")
                            }
                        }
                        Button(action: {
                            viewModel.reload()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button(action: {
                            viewModel.goHome()
                        }) {
                            Image(systemName: "house")
                        }
                        Menu {
                            Button(action: {
                                viewModel.clearCapturedSources()
                            }) {
                                Label("清空视频源", systemImage: "trash")
                            }
                            Button(action: {
                                showDownloadList = true
                            }) {
                                Label("下载管理", systemImage: "arrow.down.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadInitialURL()
                NotificationCenter.default.addObserver(forName: NSNotification.Name("PlayLocalVideo"), object: nil, queue: .main) { notification in
                    if let url = notification.object as? URL {
                        localVideoURL = url
                        showLocalVideoPlayer = true
                    }
                }
            }
            .sheet(isPresented: $showSourceList) {
                SourceListView(
                    sources: viewModel.capturedSources,
                    onPlay: { source in
                        selectedVideoURL = source.url
                        selectedVideoTitle = source.title ?? "视频"
                        showVideoPlayer = true
                    },
                    onDownload: { source in
                        selectedDownloadSource = source
                        downloadTitle = source.title ?? "视频_\(source.type.uppercased())"
                        showDownloadDialog = true
                    }
                )
            }
            .sheet(isPresented: $showDownloadList) {
                DownloadListView(downloadManager: downloadManager)
            }
            .sheet(isPresented: $showVideoPlayer) {
                VideoPlayerView(url: selectedVideoURL, title: selectedVideoTitle)
            }
            .sheet(isPresented: $showLocalVideoPlayer) {
                if let url = localVideoURL {
                    LocalVideoPlayerView(fileURL: url, title: "本地视频")
                }
            }
            .alert("下载视频", isPresented: $showDownloadDialog) {
                TextField("视频标题", text: $downloadTitle)
                Button("下载") {
                    if let source = selectedDownloadSource {
                        downloadManager.startDownload(source: source, title: downloadTitle)
                    }
                    showDownloadDialog = false
                }
                Button("取消", role: .cancel) {
                    showDownloadDialog = false
                }
            } message: {
                Text("输入视频标题，开始下载")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SourceListView: View {
    let sources: [VideoSource]
    let onPlay: (VideoSource) -> Void
    let onDownload: (VideoSource) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                if sources.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "film")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("未捕获到视频源")
                                .foregroundColor(.secondary)
                            Text("请打开视频播放页面，系统会自动捕获视频源")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    ForEach(sources) { source in
                        SourceItemRow(source: source, onPlay: onPlay, onDownload: onDownload)
                    }
                }
            }
            .navigationTitle("视频源 (\(sources.count))")
            .navigationBarItems(trailing: Button("完成") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct SourceItemRow: View {
    let source: VideoSource
    let onPlay: (VideoSource) -> Void
    let onDownload: (VideoSource) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = source.title {
                        Text(title)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        Text(source.type.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeColor(for: source.type))
                            .cornerRadius(4)

                        if let quality = source.quality {
                            Text(quality)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                    Text(source.url)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    onPlay(source)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("播放")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }

                Button(action: {
                    onDownload(source)
                }) {
                    HStack {
                        Image(systemName: "arrow.down")
                        Text("下载")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    private func typeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "m3u8":
            return .orange
        case "mp4":
            return .blue
        case "flv":
            return .purple
        case "m4v":
            return .green
        default:
            return .gray
        }
    }
}

struct WebView: UIViewRepresentable {
    let viewModel: SourceCaptureViewModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.isOpaque = false
        webView.backgroundColor = .clear

        viewModel.setupWebView(webView)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

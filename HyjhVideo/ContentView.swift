import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var viewModel = WebViewModel()
    @State private var showBackButton = false

    var body: some View {
        NavigationView {
            ZStack {
                WebView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.bottom)

                if viewModel.isLoading {
                    VStack {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.horizontal)
                        Spacer()
                    }
                }

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
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.loadInitialURL()
        }
    }
}

class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var isLoading = false
    @Published var progress: Double = 0
    @Published var pageTitle = "视频"
    @Published var errorMessage: String?
    @Published var canGoBack = false
    @Published var canGoForward = false

    var webView: WKWebView?
    private let homeURL = "https://m.hyjhzstj.com"
    private var progressObserver: NSKeyValueObservation?

    func loadInitialURL() {
        guard let url = URL(string: homeURL) else { return }
        let request = URLRequest(url: url)
        webView?.load(request)
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        errorMessage = nil
        webView?.reload()
    }

    func goHome() {
        guard let url = URL(string: homeURL) else { return }
        let request = URLRequest(url: url)
        webView?.load(request)
    }

    func setupWebView(_ webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = false

        progressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, value in
            DispatchQueue.main.async {
                self?.progress = value.newValue ?? 0
            }
        }
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.progress = 1.0
            self.canGoBack = webView.canGoBack
            self.canGoForward = webView.canGoForward
            if let title = webView.title, !title.isEmpty {
                self.pageTitle = title
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = "无法访问该网站，请检查网络连接"
        }
    }

    // 处理新窗口打开的链接
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil || !navigationAction.targetFrame!.isMainFrame {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
        }
        return nil
    }

    // 允许所有导航
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}

struct WebView: UIViewRepresentable {
    let viewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true

        // 允许视频自动播放
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

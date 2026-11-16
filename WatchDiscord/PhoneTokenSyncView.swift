import SwiftUI
import WebKit
import WatchConnectivity

@MainActor
final class WebLoginCoordinator: NSObject, ObservableObject, WCSessionDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    @Published var statusText = "Sign in below to auto-sync to your Watch"
    @Published var isSynced = false
    @Published var reloadTrigger = UUID()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendTokenToWatch(_ rawToken: String) {
        let cleaned = rawToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        guard !cleaned.isEmpty, cleaned != "null", cleaned != "undefined", cleaned.count > 20 else { return }
        guard !isSynced else { return }

        isSynced = true
        let payload = ["discord_user_token": cleaned]
        do {
            try WCSession.default.updateApplicationContext(payload)
            statusText = "Synced! Open Discord on your Apple Watch."
        } catch {
            isSynced = false
            statusText = "Sync error: \(error.localizedDescription)"
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    func resetSession() {
        isSynced = false
        statusText = "Sign in below to auto-sync to your Watch"
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) {
            DispatchQueue.main.async {
                self.reloadTrigger = UUID()
            }
        }
    }

    nonisolated func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "tokenHandler", let token = message.body as? String {
            Task { @MainActor in
                self.sendTokenToWatch(token)
            }
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}

struct DiscordLoginWebView: UIViewRepresentable {
    @ObservedObject var coordinator: WebLoginCoordinator

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(coordinator, name: "tokenHandler")

        // Open-source client method: hook Storage.prototype.setItem + XHR before Discord boots
        let openSourceHook = """
        (function() {
            const origSetItem = Storage.prototype.setItem;
            Storage.prototype.setItem = function(key, value) {
                if (key === 'token' && value && value.length > 20) {
                    window.webkit.messageHandlers.tokenHandler.postMessage(value);
                }
                return origSetItem.apply(this, arguments);
            };

            const origOpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url) {
                this.addEventListener('load', function() {
                    try {
                        if (typeof url === 'string' && url.includes('/auth/')) {
                            const data = JSON.parse(this.responseText);
                            if (data && data.token) {
                                window.webkit.messageHandlers.tokenHandler.postMessage(data.token);
                            }
                        }
                    } catch (e) {}
                });
                return origOpen.apply(this, arguments);
            };
        })();
        """
        contentController.addUserScript(
            WKUserScript(source: openSourceHook, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        )

        let prefs = WKWebpagePreferences()
        prefs.preferredContentMode = .desktop
        prefs.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.defaultWebpagePreferences = prefs
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"

        // ptb.discord.com/login bypasses the mobile App Store splash page redirect completely
        if let url = URL(string: "https://ptb.discord.com/login") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct PhoneTokenSyncView: View {
    @StateObject private var coordinator = WebLoginCoordinator()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: coordinator.isSynced ? "checkmark.circle.fill" : "applewatch.radiowaves.left.and.right")
                        .foregroundStyle(coordinator.isSynced ? .green : .blue)
                    Text(coordinator.statusText)
                        .font(.caption)
                        .lineLimit(2)
                    Spacer()
                    Button("Reset") {
                        coordinator.resetSession()
                    }
                    .font(.caption.bold())
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))

                DiscordLoginWebView(coordinator: coordinator)
                    .id(coordinator.reloadTrigger)
            }
            .navigationTitle("WatchDiscord Login")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

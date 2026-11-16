import SwiftUI
import WebKit
import WatchConnectivity

@MainActor
final class WebLoginCoordinator: NSObject, ObservableObject, WCSessionDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    @Published var statusText = "Sign in on Discord below to auto-sync to your Watch"
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
        guard !cleaned.isEmpty, cleaned != "null", cleaned != "undefined" else { return }
        guard !isSynced else { return }

        isSynced = true
        let payload = ["discord_user_token": cleaned]
        do {
            try WCSession.default.updateApplicationContext(payload)
            statusText = "Logged in & synced! Open Discord on your Apple Watch."
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
        statusText = "Sign in on Discord below to auto-sync to your Watch"
        let dataStore = WKWebsiteDataStore.default()
        dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {
            DispatchQueue.main.async {
                self.reloadTrigger = UUID()
            }
        }
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

        let scriptSource = """
        setInterval(function() {
            try {
                var iframe = document.createElement('iframe');
                document.body.appendChild(iframe);
                var rawToken = iframe.contentWindow.localStorage.getItem('token');
                iframe.remove();
                if (rawToken && rawToken.length > 20) {
                    window.webkit.messageHandlers.tokenHandler.postMessage(rawToken);
                }
            } catch (e) {}
        }, 1500);
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(userScript)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"

        if let url = URL(string: "https://discord.com") {
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

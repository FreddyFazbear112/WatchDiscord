import SwiftUI
import WatchConnectivity

final class PhoneSessionSender: NSObject, ObservableObject, WCSessionDelegate {
    @Published var statusText = "Ready to sync"

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendToken(_ token: String) {
        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            statusText = "Paste a token first."
            return
        }

        let payload = ["discord_user_token": cleaned]
        do {
            try WCSession.default.updateApplicationContext(payload)
            statusText = "Synced to Watch! Open Discord on your Apple Watch."
        } catch {
            statusText = "Sync error: \(error.localizedDescription)"
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}

struct PhoneTokenSyncView: View {
    @StateObject private var sender = PhoneSessionSender()
    @State private var tokenInput = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Discord Authorization") {
                    SecureField("Paste token here", text: $tokenInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button("Send to Watch") {
                        sender.sendToken(tokenInput)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("Status") {
                    Text(sender.statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("WatchDiscord Setup")
        }
    }
}


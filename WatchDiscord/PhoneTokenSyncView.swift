import SwiftUI
import WatchConnectivity

@MainActor
final class PhoneLoginViewModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var email = ""
    @Published var password = ""
    @Published var twoFactorCode = ""
    @Published var manualToken = ""

    @Published var mfaTicket: String?
    @Published var isLoading = false
    @Published var statusText = "Sign in to sync with your Apple Watch"
    @Published var isError = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func login() async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            setStatus("Enter both email and password.", error: true)
            return
        }

        isLoading = true
        isError = false
        defer { isLoading = false }

        guard let url = URL(string: "https://discord.com") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Discord-iOS/250.0 (iPhone; iOS 17.5)", forHTTPHeaderField: "User-Agent")

        let body: [String: Any] = [
            "login": cleanEmail,
            "password": password,
            "undelete": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                setStatus("Invalid response from Discord.", error: true)
                return
            }

            if let token = json["token"] as? String, !token.isEmpty {
                sendTokenToWatch(token)
            } else if let ticket = json["ticket"] as? String {
                mfaTicket = ticket
                setStatus("Enter your 6-digit 2FA authenticator code.", error: false)
            } else if let captchaKey = json["captcha_key"] {
                _ = captchaKey
                setStatus("Discord requested a CAPTCHA. Use the Manual Token section below.", error: true)
            } else if let message = json["message"] as? String {
                setStatus(message, error: true)
            } else {
                setStatus("Login failed. Check your email and password.", error: true)
            }
        } catch {
            setStatus("Network error: \(error.localizedDescription)", error: true)
        }
    }

    func submitTwoFactor() async {
        guard let ticket = mfaTicket else { return }
        let cleanCode = twoFactorCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCode.isEmpty else {
            setStatus("Enter your 6-digit 2FA code.", error: true)
            return
        }

        isLoading = true
        isError = false
        defer { isLoading = false }

        guard let url = URL(string: "https://discord.com") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Discord-iOS/250.0 (iPhone; iOS 17.5)", forHTTPHeaderField: "User-Agent")

        let body: [String: Any] = [
            "code": cleanCode,
            "ticket": ticket
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                setStatus("Invalid 2FA response.", error: true)
                return
            }

            if let token = json["token"] as? String, !token.isEmpty {
                mfaTicket = nil
                twoFactorCode = ""
                sendTokenToWatch(token)
            } else if let message = json["message"] as? String {
                setStatus(message, error: true)
            } else {
                setStatus("Invalid 2FA code.", error: true)
            }
        } catch {
            setStatus("Network error: \(error.localizedDescription)", error: true)
        }
    }

    func sendTokenToWatch(_ rawToken: String) {
        let cleaned = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            setStatus("Token is empty.", error: true)
            return
        }

        let payload = ["discord_user_token": cleaned]
        do {
            try WCSession.default.updateApplicationContext(payload)
            setStatus("Logged in & synced to Apple Watch! Open Discord on your wrist.", error: false)
        } catch {
            setStatus("Logged in, but watch sync failed: \(error.localizedDescription)", error: true)
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    private func setStatus(_ text: String, error: Bool) {
        statusText = text
        isError = error
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}

struct PhoneTokenSyncView: View {
    @StateObject private var vm = PhoneLoginViewModel()

    var body: some View {
        NavigationStack {
            Form {
                if vm.mfaTicket == nil {
                    Section("Discord Login") {
                        TextField("Email or Phone", text: $vm.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $vm.password)

                        Button {
                            Task { await vm.login() }
                        } label: {
                            if vm.isLoading {
                                ProgressView()
                            } else {
                                Text("Log In & Sync to Watch")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isLoading)
                    }
                } else {
                    Section("Two-Factor Authentication") {
                        TextField("6-Digit Code", text: $vm.twoFactorCode)
                            .keyboardType(.numberPad)

                        Button {
                            Task { await vm.submitTwoFactor() }
                        } label: {
                            if vm.isLoading {
                                ProgressView()
                            } else {
                                Text("Verify & Sync to Watch")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isLoading)

                        Button("Back to Login", role: .cancel) {
                            vm.mfaTicket = nil
                        }
                    }
                }

                Section("Status") {
                    Text(vm.statusText)
                        .font(.footnote)
                        .foregroundStyle(vm.isError ? .red : .secondary)
                }

                Section("Fallback (If CAPTCHA Appears)") {
                    SecureField("Paste token manually", text: $vm.manualToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Send Token to Watch") {
                        vm.sendTokenToWatch(vm.manualToken)
                    }
                }
            }
            .navigationTitle("WatchDiscord")
        }
    }
}

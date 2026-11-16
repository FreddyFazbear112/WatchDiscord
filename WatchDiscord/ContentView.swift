import SwiftUI
import UIKit

private enum PhoneStyle {
    static let background = Color(red: 0.055, green: 0.063, blue: 0.09)
    static let panel = Color(red: 0.105, green: 0.12, blue: 0.17)
    static let accent = Color(red: 0.42, green: 0.38, blue: 0.98)
    static let muted = Color(red: 0.60, green: 0.64, blue: 0.73)
}

struct ContentView: View {
    @State private var showingSetup = false

    var body: some View {
        NavigationStack {
            ZStack {
                PhoneStyle.background.ignoresSafeArea()
                VStack(spacing: 22) {
                    Spacer()
                    Image(systemName: "applewatch.and.iphone")
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(PhoneStyle.accent)
                        .padding(24)
                        .background(PhoneStyle.panel, in: RoundedRectangle(cornerRadius: 28))

                    VStack(spacing: 8) {
                        Text("WATCHCORD")
                            .font(.caption.weight(.heavy))
                            .tracking(2.5)
                            .foregroundStyle(PhoneStyle.muted)
                        Text("Set up once.\nChat from your wrist.")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                    }

                    Text("Use your iPhone to securely connect Discord. Your Apple Watch is where the WatchCord experience lives.")
                        .font(.subheadline)
                        .foregroundStyle(PhoneStyle.muted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 310)

                    Button { showingSetup = true } label: {
                        Label("Sign in with Discord", systemImage: "person.crop.circle.badge.checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PhoneStyle.accent)
                    .padding(.horizontal, 28)

                    HStack(spacing: 8) {
                        Image(systemName: "applewatch")
                        Text("Open WatchCord on your Apple Watch for messages and activity.")
                    }
                    .font(.caption)
                    .foregroundStyle(PhoneStyle.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    Spacer()
                    Text("Connection status: Not configured")
                        .font(.caption2)
                        .foregroundStyle(PhoneStyle.muted)
                        .padding(.bottom, 10)
                }
                .padding(22)
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Discord sign-in setup", isPresented: $showingSetup) {
                Button("Open Developer Portal") {
                    UIApplication.shared.open(URL(string: "https://discord.com/developers/applications")!)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("A secure Discord OAuth authorization flow and a trusted backend are required. The app must not collect your Discord password or store a client secret on your iPhone.")
            }
        }
        .preferredColorScheme(.dark)
    }
}

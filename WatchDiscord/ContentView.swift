import SwiftUI
import UIKit

private enum SignInStyle {
    static let background = Color(red: 0.055, green: 0.063, blue: 0.09)
    static let panel = Color(red: 0.105, green: 0.12, blue: 0.17)
    static let accent = Color(red: 0.42, green: 0.38, blue: 0.98)
    static let muted = Color(red: 0.60, green: 0.64, blue: 0.73)
}

struct ContentView: View {
    @State private var showingSetup = false
    @State private var isConnected = false

    var body: some View {
        ZStack {
            SignInStyle.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "applewatch.and.arrow.forward")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 92, height: 92)
                        .background(SignInStyle.accent.gradient, in: RoundedRectangle(cornerRadius: 28))
                    Text("WATCHCORD")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(SignInStyle.muted)
                    Text(isConnected ? "You're connected." : "Connect once.\nUse it on your wrist.")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: isConnected ? "checkmark.circle.fill" : "person.crop.circle")
                            .font(.title2).foregroundStyle(isConnected ? .green : SignInStyle.accent)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(isConnected ? "Discord connected" : "Discord account")
                                .font(.headline)
                            Text(isConnected ? "You can continue on Apple Watch." : "Sign in here to set up your companion.")
                                .font(.caption).foregroundStyle(SignInStyle.muted)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(SignInStyle.panel, in: RoundedRectangle(cornerRadius: 18))

                    Button {
                        showingSetup = true
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text(isConnected ? "Account settings" : "Sign in with Discord")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.headline)
                        .padding(17)
                        .foregroundStyle(.white)
                        .background(SignInStyle.accent, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                Spacer()
                Text("Your Apple Watch is the main WatchCord experience.")
                    .font(.caption).foregroundStyle(SignInStyle.muted)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Discord sign-in setup", isPresented: $showingSetup) {
            Button("Open Developer Portal") {
                UIApplication.shared.open(URL(string: "https://discord.com/developers/applications")!)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("OAuth sign-in must be configured with your Discord application ID and a secure authorization-code exchange service. This screen does not store a Discord password or user token.")
        }
    }
}

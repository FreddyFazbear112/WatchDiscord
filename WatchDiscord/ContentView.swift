import SwiftUI
import UIKit

struct ContentView: View {
    @State private var showingLoginInfo = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("WatchDiscord", systemImage: "applewatch").font(.title2.bold())
                    Text("A companion interface for Discord.").foregroundStyle(.secondary)
                }
                Section("Account") {
                    Button { showingLoginInfo = true } label: {
                        Label("Connect Discord", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    Text("OAuth sign-in needs your Discord application ID and a secure authorization-code exchange endpoint.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Features") {
                    Label("Account and server overview", systemImage: "person.2")
                    Label("Chat interface foundation", systemImage: "bubble.left.and.bubble.right")
                    Label("Theme settings foundation", systemImage: "paintpalette")
                    Label("Calls: not yet available", systemImage: "phone.down")
                }
                Section {
                    Link(destination: URL(string: "https://discord.com/developers/applications")!) {
                        Label("Discord Developer Portal", systemImage: "arrow.up.right.square")
                    }
                }
            }
            .navigationTitle("WatchDiscord")
            .alert("Discord setup required", isPresented: $showingLoginInfo) {
                Button("Open Developer Portal") {
                    UIApplication.shared.open(URL(string: "https://discord.com/developers/applications")!)
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Create a Discord application, configure your OAuth2 redirect URI, and use a secure backend to exchange authorization codes. Never put a client secret in the iOS app.")
            }
        }
    }
}

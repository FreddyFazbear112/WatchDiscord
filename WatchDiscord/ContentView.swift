import SwiftUI
import UIKit

private enum WatchDiscordStyle {
    static let background = Color(red: 0.055, green: 0.063, blue: 0.09)
    static let panel = Color(red: 0.105, green: 0.12, blue: 0.17)
    static let accent = Color(red: 0.42, green: 0.38, blue: 0.98)
    static let muted = Color(red: 0.60, green: 0.64, blue: 0.73)
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingSetup = false

    var body: some View {
        TabView(selection: $selectedTab) {
            home.tag(0)
            messages.tag(1)
            profile.tag(2)
        }
        .tint(.white)
        .preferredColorScheme(.dark)
    }

    private var home: some View {
        NavigationStack {
            ZStack {
                WatchDiscordStyle.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WATCHCORD").font(.caption.weight(.heavy)).tracking(2.2).foregroundStyle(WatchDiscordStyle.muted)
                                Text("Your Discord,\ncloser.").font(.system(size: 34, weight: .bold, design: .rounded))
                            }
                            Spacer()
                            Image(systemName: "waveform")
                                .font(.title2.bold()).foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .background(WatchDiscordStyle.accent, in: RoundedRectangle(cornerRadius: 18))
                        }

                        Button { showingSetup = true } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "person.crop.circle.badge.plus").font(.title2)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Connect Discord").font(.headline)
                                    Text("Set up your account").font(.caption).foregroundStyle(.white.opacity(0.72))
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right").font(.caption.bold())
                            }
                            .padding(18)
                            .background(LinearGradient(colors: [WatchDiscordStyle.accent, Color(red: 0.30, green: 0.27, blue: 0.77)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(.plain)

                        HStack {
                            Text("QUICK ACCESS").font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(WatchDiscordStyle.muted)
                            Spacer()
                            Text("PREVIEW").font(.system(size: 9, weight: .heavy)).tracking(1).padding(.horizontal, 9).padding(.vertical, 5).background(.white.opacity(0.08), in: Capsule())
                        }

                        HStack(spacing: 12) {
                            quickCard("Messages", detail: "Your conversations", icon: "bubble.left.and.bubble.right.fill", tab: 1)
                            quickCard("Servers", detail: "Communities", icon: "person.3.fill", tab: 1)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Label("WATCH COMPANION", systemImage: "applewatch").font(.caption.weight(.bold)).tracking(1.2).foregroundStyle(WatchDiscordStyle.muted)
                            Text("A lighter way to keep up").font(.title3.bold())
                            Text("This build is the interface foundation. Live Discord messages and account sync still need an approved sign-in and backend connection.")
                                .font(.subheadline).foregroundStyle(WatchDiscordStyle.muted).fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(WatchDiscordStyle.panel, in: RoundedRectangle(cornerRadius: 22))
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Discord connection setup", isPresented: $showingSetup) {
                Button("Open Developer Portal") { UIApplication.shared.open(URL(string: "https://discord.com/developers/applications")!) }
                Button("Not now", role: .cancel) { }
            } message: {
                Text("Live sign-in requires a Discord OAuth application and a secure authorization-code exchange service. Never put a client secret in this app.")
            }
        }
        .tabItem { Label("Home", systemImage: "house.fill") }
    }

    private var messages: some View {
        NavigationStack {
            ZStack {
                WatchDiscordStyle.background.ignoresSafeArea()
                VStack(spacing: 14) {
                    Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 42)).foregroundStyle(WatchDiscordStyle.accent)
                    Text("Your conversations").font(.title2.bold())
                    Text("Connect an account to show your DMs and recent messages here.")
                        .font(.subheadline).foregroundStyle(WatchDiscordStyle.muted).multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                    Button("Connect Discord") { showingSetup = true }.buttonStyle(.borderedProminent).tint(WatchDiscordStyle.accent)
                }
                .padding(28)
            }
            .navigationTitle("Messages")
        }
        .tabItem { Label("Chats", systemImage: "bubble.left.fill") }
    }

    private var profile: some View {
        NavigationStack {
            ZStack {
                WatchDiscordStyle.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 70)).foregroundStyle(WatchDiscordStyle.muted)
                    Text("Not connected").font(.title2.bold())
                    Text("Your Discord profile will appear here after secure sign-in is configured.")
                        .font(.subheadline).foregroundStyle(WatchDiscordStyle.muted).multilineTextAlignment(.center)
                    Button("Connection setup") { showingSetup = true }.buttonStyle(.borderedProminent).tint(WatchDiscordStyle.accent)
                }
                .padding(28)
            }
            .navigationTitle("You")
        }
        .tabItem { Label("You", systemImage: "person.crop.circle.fill") }
    }

    private func quickCard(_ title: String, detail: String, icon: String, tab: Int) -> some View {
        Button { selectedTab = tab } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.title2).foregroundStyle(.white)
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(WatchDiscordStyle.muted)
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(15)
            .background(WatchDiscordStyle.panel, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

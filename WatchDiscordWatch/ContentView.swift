import SwiftUI

struct ContentView: View {
    @StateObject private var discord = DiscordService()
    @StateObject private var themeSync = NitroThemeSync()
    @AppStorage("discord_user_token") private var savedToken: String = ""

    var body: some View {
        NavigationStack {
            List {
                if savedToken.isEmpty {
                    Section("Setup Required") {
                        Text("Open the WatchDiscord app on your iPhone and tap 'Send to Watch' to sync your token.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if let error = discord.errorMessage {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }

                    // My Profile & Synced Nitro Theme
                    Section("Account") {
                        if let me = discord.currentUser {
                            NavigationLink {
                                ProfileView(token: savedToken, userID: me.id, isCurrentUser: true)
                            } label: {
                                Label(me.displayName, systemImage: "person.crop.circle")
                            }
                        }

                        NavigationLink {
                            ThemePickerView(themeSync: themeSync)
                        } label: {
                            Label("Nitro Theme", systemImage: "paintpalette.fill")
                        }
                    }

                    // Direct Messages
                    Section("Direct Messages") {
                        ForEach(discord.dmChannels) { dm in
                            NavigationLink {
                                ChatView(
                                    discord: discord,
                                    themeSync: themeSync,
                                    token: savedToken,
                                    channel: dm
                                )
                            } label: {
                                Text(dm.displayName)
                                    .lineLimit(1)
                            }
                        }
                    }

                    // Servers
                    Section("Servers") {
                        ForEach(discord.guilds) { guild in
                            NavigationLink {
                                GuildChannelsView(
                                    discord: discord,
                                    themeSync: themeSync,
                                    token: savedToken,
                                    guild: guild
                                )
                            } label: {
                                Text(guild.name)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeSync.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Discord")
            .refreshable {
                await startSession()
            }
            .task(id: savedToken) {
                await startSession()
            }
        }
    }

    private func startSession() async {
        guard !savedToken.isEmpty else { return }
        discord.configure(token: savedToken)
        themeSync.configure(token: savedToken)
        await discord.loadInitialData()
        await themeSync.fetchTheme()
    }
}

struct GuildChannelsView: View {
    @ObservedObject var discord: DiscordService
    @ObservedObject var themeSync: NitroThemeSync
    let token: String
    let guild: DiscordGuild

    var body: some View {
        List(discord.guildChannels) { channel in
            if channel.isVoice {
                NavigationLink {
                    CallView(
                        token: token,
                        guildID: guild.id,
                        channelID: channel.id,
                        channelName: channel.displayName,
                        isDM: false
                    )
                } label: {
                    Label(channel.displayName, systemImage: "speaker.wave.2.fill")
                }
            } else {
                NavigationLink {
                    ChatView(
                        discord: discord,
                        themeSync: themeSync,
                        token: token,
                        channel: channel
                    )
                } label: {
                    Label(channel.displayName, systemImage: "number")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeSync.backgroundGradient.ignoresSafeArea())
        .navigationTitle(guild.name)
        .task {
            await discord.loadChannels(for: guild.id)
        }
    }
}

struct ThemePickerView: View {
    @ObservedObject var themeSync: NitroThemeSync

    var body: some View {
        List(themeSync.presets) { preset in
            Button {
                Task {
                    await themeSync.applyAndSync(preset: preset)
                }
            } label: {
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: preset.primaryHex), Color(hex: preset.secondaryHex)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                    Text(preset.name)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(themeSync.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Nitro Themes")
    }
}

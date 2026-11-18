import SwiftUI

struct ContentView: View {
  @StateObject private var discord =
    DiscordService()
  @StateObject private var themeSync =
    NitroThemeSync()
  @AppStorage("discord_user_token")
  private var savedToken = ""

  private var isDemoMode: Bool {
    ProcessInfo.processInfo.arguments
      .contains("-DEMO_MODE")
  }

  private var effectiveToken: String {
    isDemoMode ? "demo_token" : savedToken
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 8) {
          if effectiveToken.isEmpty {
            setupCard
          } else {
            if let err = discord.errorMessage {
              Text(err)
                .font(.caption2)
                .foregroundStyle(.red)
                .padding(.horizontal, 4)
            }
            dmBannerButton
            ForEach(discord.guilds) { guild in
              guildRow(for: guild)
            }
            accountFooterRow
          }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 8)
      }
      .background(
        themeSync.backgroundGradient
          .ignoresSafeArea()
      )
      .navigationTitle("WatchDiscord")
      .refreshable { await startSession() }
      .task(id: effectiveToken) {
        await startSession()
      }
    }
  }

  private var setupCard: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(
        "Setup Required",
        systemImage: "iphone.and.arrow.forward"
      )
      .font(.footnote.weight(.semibold))
      .foregroundStyle(Color(hex: "5865F2"))

      Text(
        "Open WatchDiscord on iPhone and "
        + "tap 'Send to Watch'."
      )
      .font(.caption2)
      .foregroundStyle(.secondary)
    }
    .padding(10)
    .frame(
      maxWidth: .infinity,
      alignment: .leading
    )
    .background(
      Color.white.opacity(0.08),
      in: RoundedRectangle(
        cornerRadius: 14,
        style: .continuous
      )
    )
  }

  private var dmBannerButton: some View {
    NavigationLink {
      DirectMessagesListView(
        discord: discord,
        themeSync: themeSync,
        token: effectiveToken
      )
    } label: {
      HStack(spacing: 10) {
        ZStack {
          Circle()
            .fill(Color(hex: "5865F2"))
            .frame(width: 30, height: 30)
          Image(
            systemName: "bubble.left.fill"
          )
          .font(
            .system(size: 13, weight: .semibold)
          )
          .foregroundStyle(.white)
        }

        Text("Direct Messages")
          .font(
            .system(size: 14, weight: .semibold)
          )
          .foregroundStyle(.white)
          .lineLimit(1)

        Spacer(minLength: 4)

        if !discord.dmChannels.isEmpty {
          Text("\(discord.dmChannels.count)")
            .font(
              .system(size: 11, weight: .bold)
            )
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Color(hex: "ED4245"),
              in: Capsule()
            )
        }

        Image(systemName: "chevron.right")
          .font(
            .system(size: 11, weight: .semibold)
          )
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 9)
      .background(
        Color.white.opacity(0.10),
        in: RoundedRectangle(
          cornerRadius: 15,
          style: .continuous
        )
      )
    }
    .buttonStyle(.plain)
  }

  private func guildRow(
    for guild: DiscordGuild
  ) -> some View {
    NavigationLink {
      GuildChannelsView(
        discord: discord,
        themeSync: themeSync,
        token: effectiveToken,
        guild: guild
      )
    } label: {
      HStack(spacing: 10) {
        GuildAvatarView(guild: guild)

        Text(guild.name)
          .font(
            .system(size: 14, weight: .medium)
          )
          .foregroundStyle(.white)
          .lineLimit(1)

        Spacer(minLength: 4)

        Image(systemName: "chevron.right")
          .font(
            .system(size: 11, weight: .semibold)
          )
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 9)
      .background(
        Color.white.opacity(0.08),
        in: RoundedRectangle(
          cornerRadius: 15,
          style: .continuous
        )
      )
    }
    .buttonStyle(.plain)
  }

  private var accountFooterRow: some View {
    HStack(spacing: 6) {
      if let me = discord.currentUser {
        NavigationLink {
          ProfileView(
            token: effectiveToken,
            userID: me.id,
            isCurrentUser: true
          )
        } label: {
          HStack(spacing: 6) {
            Circle()
              .fill(Color(hex: "23A55A"))
              .frame(width: 8, height: 8)
            Text(me.displayName)
              .font(.caption2.weight(.semibold))
              .lineLimit(1)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity)
          .background(
            Color.white.opacity(0.08),
            in: Capsule()
          )
        }
        .buttonStyle(.plain)
      }

      NavigationLink {
        ThemePickerView(themeSync: themeSync)
      } label: {
        Image(systemName: "paintpalette.fill")
          .font(.caption)
          .foregroundStyle(.white)
          .padding(8)
          .background(
            Color(hex: "5865F2").opacity(0.85),
            in: Circle()
          )
      }
      .buttonStyle(.plain)
    }
    .padding(.top, 2)
  }

  private func startSession() async {
    guard !effectiveToken.isEmpty else {
      return
    }
    discord.configure(token: effectiveToken)
    if !isDemoMode {
      themeSync.configure(
        token: effectiveToken
      )
    }
    await discord.loadInitialData()
    if !isDemoMode {
      await themeSync.fetchTheme()
    }
  }
}

struct GuildAvatarView: View {
  let guild: DiscordGuild

  private var initials: String {
    let words = guild.name.split(
      separator: " "
    )
    let letters = words.prefix(2)
      .compactMap { $0.first }
    return letters.isEmpty
      ? "S" : String(letters).uppercased()
  }

  private var badgeColor: Color {
    let palette = [
      "5865F2", "EB459E", "57F287",
      "FEE75C", "ED4245", "3BA55C"
    ]
    let idx =
      abs(guild.id.hashValue) % palette.count
    return Color(hex: palette[idx])
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(badgeColor.opacity(0.28))
        .frame(width: 30, height: 30)
      Circle()
        .strokeBorder(
          badgeColor.opacity(0.75),
          lineWidth: 1.5
        )
        .frame(width: 30, height: 30)
      Text(initials)
        .font(
          .system(size: 11, weight: .bold)
        )
        .foregroundStyle(.white)
    }
  }
}

struct DirectMessagesListView: View {
  @ObservedObject var discord: DiscordService
  @ObservedObject var themeSync: NitroThemeSync
  let token: String

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        ForEach(discord.dmChannels) { dm in
          NavigationLink {
            ChatView(
              discord: discord,
              themeSync: themeSync,
              token: token,
              channel: dm
            )
          } label: {
            HStack(spacing: 10) {
              ZStack {
                Circle()
                  .fill(
                    Color(hex: "5865F2")
                      .opacity(0.3)
                  )
                  .frame(width: 28, height: 28)
                Text(
                  String(
                    dm.displayName.prefix(1)
                  ).uppercased()
                )
                .font(
                  .system(size: 12, weight: .bold)
                )
                .foregroundStyle(.white)
              }
              Text(dm.displayName)
                .font(
                  .system(size: 14, weight: .medium)
                )
                .foregroundStyle(.white)
                .lineLimit(1)
              Spacer()
              Image(systemName: "chevron.right")
                .font(
                  .system(
                    size: 11,
                    weight: .semibold
                  )
                )
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
              Color.white.opacity(0.08),
              in: RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
              )
            )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 2)
    }
    .background(
      themeSync.backgroundGradient
        .ignoresSafeArea()
    )
    .navigationTitle("Direct Messages")
  }
}

struct GuildChannelsView: View {
  @ObservedObject var discord: DiscordService
  @ObservedObject var themeSync: NitroThemeSync
  let token: String
  let guild: DiscordGuild

  var body: some View {
    ScrollView {
      VStack(spacing: 7) {
        ForEach(
          discord.guildChannels
        ) { channel in
          channelRow(for: channel)
        }
      }
      .padding(.horizontal, 2)
    }
    .background(
      themeSync.backgroundGradient
        .ignoresSafeArea()
    )
    .navigationTitle(guild.name)
    .task {
      await discord.loadChannels(
        for: guild.id
      )
    }
  }

  @ViewBuilder
  private func channelRow(
    for channel: DiscordChannel
  ) -> some View {
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
        HStack(spacing: 8) {
          Image(
            systemName: "speaker.wave.2.fill"
          )
.font(.caption)
.foregroundStyle(Color(hex: "23A55A"))
Text(channel.displayName)
.font(
.system(size: 14, weight: .medium)
)
.lineLimit(1)
Spacer()
Image(systemName: "chevron.right")
.font(.system(size: 11))
.foregroundStyle(.secondary)
}
.padding(.horizontal, 10)
.padding(.vertical, 9)
.background(
Color.white.opacity(0.08),
in: RoundedRectangle(
cornerRadius: 14,
style: .continuous
)
)
}
.buttonStyle(.plain)
} else {
NavigationLink {
ChatView(
discord: discord,
themeSync: themeSync,
token: token,
channel: channel
)
} label: {
HStack(spacing: 8) {
Text("#")
.font(
.system(size: 15, weight: .bold)
)
.foregroundStyle(.secondary)
Text(channel.displayName)
.font(
.system(size: 14, weight: .medium)
)
.lineLimit(1)
Spacer()
Image(systemName: "chevron.right")
.font(.system(size: 11))
.foregroundStyle(.secondary)
}
.padding(.horizontal, 10)
.padding(.vertical, 9)
.background(
Color.white.opacity(0.08),
in: RoundedRectangle(
cornerRadius: 14,
style: .continuous
)
)
}
.buttonStyle(.plain)
}
}
}
struct ThemePickerView: View {
@ObservedObject var themeSync: NitroThemeSync
var body: some View {
List(themeSync.presets) { preset in
Button {
Task {
await themeSync.applyAndSync(
preset: preset
)
}
} label: {
HStack {
Circle()
.fill(
LinearGradient(
colors: [
Color(hex: preset.primaryHex),
Color(
hex: preset.secondaryHex
)
],
startPoint: .topLeading,
endPoint: .bottomTrailing
)
)
.frame(width: 20, height: 20)
Text(preset.name)
}
}
}
.scrollContentBackground(.hidden)
.background(
themeSync.backgroundGradient
.ignoresSafeArea()
)
.navigationTitle("Nitro Themes")
}
}

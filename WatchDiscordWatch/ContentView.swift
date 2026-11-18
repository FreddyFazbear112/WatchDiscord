import SwiftUI

private extension Color {
  static let dcBlurple = Color(
    red: 88 / 255,
    green: 101 / 255,
    blue: 242 / 255
  )
  static let dcRed = Color(
    red: 242 / 255,
    green: 63 / 255,
    blue: 67 / 255
  )
  static let dcGreen = Color(
    red: 35 / 255,
    green: 165 / 255,
    blue: 90 / 255
  )
  static let dcCard = Color(
    red: 30 / 255,
    green: 31 / 255,
    blue: 34 / 255
  )
  static let dcBorder = Color(
    red: 49 / 255,
    green: 51 / 255,
    blue: 56 / 255
  )
  static let dcBg = Color(
    red: 17 / 255,
    green: 18 / 255,
    blue: 20 / 255
  )
}

struct ContentView: View {
  @StateObject private var discord =
    DiscordService()
  @StateObject private var themeSync =
    NitroThemeSync()
  @AppStorage("discord_user_token")
  private var savedToken = ""

  private var isDemo: Bool {
    ProcessInfo.processInfo.arguments
      .contains("-DEMO_MODE")
  }

  private var token: String {
    isDemo ? "demo_token" : savedToken
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 6) {
          if token.isEmpty {
            Text(
              "Open WatchDiscord on iPhone "
              + "and tap 'Send to Watch'."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(10)
            .background(
              Color.dcCard,
              in: RoundedRectangle(
                cornerRadius: 14
              )
            )
          } else {
            if let err = discord.errorMessage {
              Text(err)
                .font(.caption2)
                .foregroundStyle(Color.dcRed)
            }
            topProfileBar
            dmButton
            sectionHeader("SERVERS")
            ForEach(discord.guilds) { g in
              guildButton(g)
            }
          }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 8)
      }
      .background(bgView)
      .navigationTitle("WatchDiscord")
      .navigationBarTitleDisplayMode(.inline)
      .refreshable { await startSession() }
      .task(id: token) {
        await startSession()
      }
    }
  }

  private var bgView: some View {
    ZStack {
      Color.dcBg
      themeSync.backgroundGradient
        .opacity(0.45)
    }
    .ignoresSafeArea()
  }

  private func sectionHeader(
    _ title: String
  ) -> some View {
    HStack {
      Text(title)
        .font(
          .system(size: 10, weight: .heavy)
        )
        .foregroundStyle(.secondary)
      Spacer()
    }
    .padding(.horizontal, 6)
    .padding(.top, 2)
  }

  private var topProfileBar: some View {
    HStack(spacing: 6) {
      if let me = discord.currentUser {
        NavigationLink {
          ProfileView(
            token: token,
            userID: me.id,
            isCurrentUser: true
          )
        } label: {
          HStack(spacing: 7) {
            ZStack(
              alignment: .bottomTrailing
            ) {
              Circle()
                .fill(Color.dcBlurple)
                .frame(width: 22, height: 22)
              Text(
                String(
                  me.displayName.prefix(1)
                ).uppercased()
              )
              .font(
                .system(
                  size: 10,
                  weight: .bold
                )
              )
              .foregroundStyle(.white)
              .frame(width: 22, height: 22)
              Circle()
                .fill(Color.dcGreen)
                .frame(width: 7, height: 7)
            }
            VStack(
              alignment: .leading,
              spacing: 0
            ) {
              Text(me.displayName)
                .font(
                  .system(
                    size: 12,
                    weight: .semibold
                  )
                )
                .foregroundStyle(.white)
                .lineLimit(1)
              Text("You • Online")
                .font(.system(size: 9))
                .foregroundStyle(
                  Color.dcGreen
                )
            }
            Spacer(minLength: 2)
            Image(systemName: "chevron.right")
              .font(
                .system(
                  size: 9,
                  weight: .bold
                )
              )
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(
            Color.dcCard,
            in: RoundedRectangle(
              cornerRadius: 13
            )
          )
          .overlay(
            RoundedRectangle(
              cornerRadius: 13
            )
            .strokeBorder(
              Color.dcBorder,
              lineWidth: 1
            )
          )
        }
        .buttonStyle(.plain)
      }

      NavigationLink {
        ThemePickerView(themeSync: themeSync)
      } label: {
        Image(systemName: "paintpalette.fill")
          .font(.system(size: 13))
          .foregroundStyle(.white)
          .frame(width: 34, height: 34)
          .background(
            Color.dcBlurple,
            in: RoundedRectangle(
              cornerRadius: 12
            )
          )
      }
      .buttonStyle(.plain)
    }
  }

  private var dmButton: some View {
    NavigationLink {
      DirectMessagesListView(
        discord: discord,
        themeSync: themeSync,
        token: token
      )
    } label: {
      HStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(Color.dcBlurple)
            .frame(width: 28, height: 28)
          Image(
            systemName: "bubble.left.fill"
          )
          .font(
            .system(size: 12, weight: .bold)
          )
          .foregroundStyle(.white)
        }
        Text("Direct Messages")
          .font(
            .system(
              size: 13,
              weight: .semibold
            )
          )
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.82)
        Spacer(minLength: 2)
        if !discord.dmChannels.isEmpty {
          Text("\(discord.dmChannels.count)")
            .font(
              .system(
                size: 10,
                weight: .heavy
              )
            )
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Color.dcRed,
              in: Capsule()
            )
        }
        Image(systemName: "chevron.right")
          .font(
            .system(size: 10, weight: .bold)
          )
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 8)
      .background(
        Color.dcCard,
        in: RoundedRectangle(
          cornerRadius: 14
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .strokeBorder(
            Color.dcBlurple.opacity(0.45),
            lineWidth: 1
          )
      )
    }
    .buttonStyle(.plain)
  }

  private func guildButton(
    _ guild: DiscordGuild
  ) -> some View {
    NavigationLink {
      GuildChannelsView(
        discord: discord,
        themeSync: themeSync,
        token: token,
        guild: guild
      )
    } label: {
      HStack(spacing: 8) {
        ZStack {
          RoundedRectangle(cornerRadius: 9)
            .fill(Color.dcBlurple)
            .frame(width: 28, height: 28)
          Text(
            String(
              guild.name.prefix(2)
            ).uppercased()
          )
          .font(
            .system(size: 11, weight: .heavy)
          )
          .foregroundStyle(.white)
        }
        Text(guild.name)
          .font(
            .system(size: 13, weight: .medium)
          )
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
        Spacer(minLength: 2)
        Image(systemName: "chevron.right")
          .font(
            .system(size: 10, weight: .bold)
          )
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 8)
      .background(
        Color.dcCard,
        in: RoundedRectangle(
          cornerRadius: 14
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .strokeBorder(
            Color.dcBorder,
            lineWidth: 1
          )
      )
    }
    .buttonStyle(.plain)
  }

  private func startSession() async {
    guard !token.isEmpty else { return }
    discord.configure(token: token)
    if !isDemo {
      themeSync.configure(token: token)
    }
    await discord.loadInitialData()
    if !isDemo {
      await themeSync.fetchTheme()
    }
  }
}

struct DirectMessagesListView: View {
  @ObservedObject var discord: DiscordService
  @ObservedObject var themeSync: NitroThemeSync
  let token: String

  var body: some View {
    List(discord.dmChannels) { dm in
      NavigationLink(dm.displayName) {
        ChatView(
          discord: discord,
          themeSync: themeSync,
          token: token,
          channel: dm
        )
      }
    }
    .navigationTitle("Direct Messages")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct GuildChannelsView: View {
  @ObservedObject var discord: DiscordService
  @ObservedObject var themeSync: NitroThemeSync
  let token: String
  let guild: DiscordGuild

  var body: some View {
    List(discord.guildChannels) { ch in
      if ch.isVoice {
        NavigationLink {
          CallView(
            token: token,
            guildID: guild.id,
            channelID: ch.id,
            channelName: ch.displayName,
            isDM: false
          )
        } label: {
          Label(
            ch.displayName,
            systemImage: "speaker.wave.2.fill"
          )
        }
      } else {
        NavigationLink {
          ChatView(
            discord: discord,
            themeSync: themeSync,
            token: token,
            channel: ch
          )
} label: {
Label(
ch.displayName,
systemImage: "number"
)
}
}
}
.navigationTitle(guild.name)
.navigationBarTitleDisplayMode(.inline)
.task {
await discord.loadChannels(
for: guild.id
)
}
}
}
struct ThemePickerView: View {
@ObservedObject var themeSync: NitroThemeSync
var body: some View {
List(themeSync.presets) { preset in
Button(preset.name) {
Task {
await themeSync.applyAndSync(
preset: preset
)
}
}
}
.navigationTitle("Nitro Themes")
.navigationBarTitleDisplayMode(.inline)
}
}

import SwiftUI

private extension Color {
  static let discordBlurple = Color(
    red: 88 / 255,
    green: 101 / 255,
    blue: 242 / 255
  )
  static let discordRed = Color(
    red: 242 / 255,
    green: 63 / 255,
    blue: 67 / 255
  )
  static let discordGreen = Color(
    red: 35 / 255,
    green: 165 / 255,
    blue: 90 / 255
  )
  static let discordCard = Color(
    red: 30 / 255,
    green: 31 / 255,
    blue: 34 / 255
  )
  static let discordBorder = Color(
    red: 49 / 255,
    green: 51 / 255,
    blue: 56 / 255
  )
  static let discordBg = Color(
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
        VStack(spacing: 6) {
          if effectiveToken.isEmpty {
            setupCard
          } else {
            if let err = discord.errorMessage {
              Text(err)
                .font(.caption2)
                .foregroundStyle(
                  Color.discordRed
                )
                .padding(.horizontal, 4)
            }

            accountTopBar
            dmBannerButton

            HStack {
              Text("SERVERS")
                .font(
                  .system(
                    size: 10,
                    weight: .heavy
                  )
                )
                .foregroundStyle(.secondary)
                .tracking(0.8)
              Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.top, 2)

            ForEach(discord.guilds) { guild in
              guildRow(for: guild)
            }
          }
        }
        .padding(.horizontal, 2)
        .padding(.bottom, 8)
      }
      .background(
        ZStack {
          Color.discordBg
          themeSync.backgroundGradient
            .opacity(0.45)
        }
        .ignoresSafeArea()
      )
      .navigationTitle("WatchDiscord")
      .navigationBarTitleDisplayMode(
        .inline
      )
      .refreshable { await startSession() }
      .task(id: effectiveToken) {
        await startSession()
      }
    }
  }

  private var setupCard: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label(
        "Connect Account",
        systemImage: "iphone.and.arrow.forward"
      )
      .font(.footnote.weight(.bold))
      .foregroundStyle(Color.discordBlurple)

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
      Color.discordCard,
      in: RoundedRectangle(
        cornerRadius: 14,
        style: .continuous
      )
    )
    .overlay(
      RoundedRectangle(
        cornerRadius: 14,
        style: .continuous
      )
      .strokeBorder(
        Color.discordBorder,
        lineWidth: 1
      )
    )
  }

  private var accountTopBar: some View {
    HStack(spacing: 6) {
      if let me = discord.currentUser {
        NavigationLink {
          ProfileView(
            token: effectiveToken,
            userID: me.id,
            isCurrentUser: true
          )
        } label: {
          HStack(spacing: 7) {
            ZStack(alignment: .bottomTrailing) {
              Circle()
                .fill(Color.discordBlurple)
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
                .fill(Color.discordGreen)
                .frame(width: 7, height: 7)
                .overlay(
                  Circle().stroke(
                    Color.discordCard,
                    lineWidth: 1.5
                  )
                )
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
                  Color.discordGreen
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
            Color.discordCard,
            in: RoundedRectangle(
              cornerRadius: 13,
              style: .continuous
            )
          )
          .overlay(
            RoundedRectangle(
              cornerRadius: 13,
              style: .continuous
            )
            .strokeBorder(
              Color.discordBorder,
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
            Color.discordBlurple,
            in: RoundedRectangle(
              cornerRadius: 12,
              style: .continuous
            )
          )
      }
      .buttonStyle(.plain)
    }
  }

  private var dmBannerButton: some View {
    NavigationLink {
      DirectMessagesListView(
        discord: discord,
        themeSync: themeSync,
        token: effectiveToken
      )
    } label: {
      HStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(Color.discordBlurple)
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
              .system(size: 10, weight: .heavy)
            )
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Color.discordRed,
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
        Color.discordCard,
        in: RoundedRectangle(
          cornerRadius: 14,
          style: .continuous
        )
      )
      .overlay(
        RoundedRectangle(
          cornerRadius: 14,
          style: .continuous
        )
        .strokeBorder(
          Color.discordBlurple.opacity(0.45),
          lineWidth: 1
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
      HStack(spacing: 8) {
        GuildAvatarView(guild: guild)

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
        Color.discordCard,
        in: RoundedRectangle(
          cornerRadius: 14,
          style: .continuous
        )
      )
      .overlay(
        RoundedRectangle(
          cornerRadius: 14,
          style: .continuous
        )
        .strokeBorder(
          Color.discordBorder,
          lineWidth: 1
        )
      )
    }
    .buttonStyle(.plain)
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
    let palette: [Color] = [
      .discordBlurple,
Color(
red: 235 / 255,
green: 69 / 255,
blue: 158 / 255
),
.discordGreen,
Color(
red: 240 / 255,
green: 178 / 255,
blue: 50 / 255
),
.discordRed
]
let idx =
abs(guild.id.hashValue) % palette.count
return palette[idx]
}
var body: some View {
ZStack {
RoundedRectangle(
cornerRadius: 9,
style: .continuous
)
.fill(badgeColor)
.frame(width: 28, height: 28)
Text(initials)
.font(
.system(size: 11, weight: .heavy)
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
VStack(spacing: 6) {
ForEach(discord.dmChannels) { dm in
NavigationLink {
ChatView(
discord: discord,
themeSync: themeSync,
token: token,
channel: dm
)
} label: {
HStack(spacing: 8) {
ZStack(
alignment: .bottomTrailing
) {
Circle()
.fill(Color.discordBlurple)
.frame(
width: 26,
height: 26
)
Text(
String(
dm.displayName.prefix(1)
).uppercased()
)
.font(
.system(
size: 11,
weight: .bold
)
)
.foregroundStyle(.white)
.frame(
width: 26,
height: 26
)
Circle()
.fill(Color.discordGreen)
.frame(width: 8, height: 8)
.overlay(
Circle().stroke(
Color.discordCard,
lineWidth: 1.5
)
)
}
Text(dm.displayName)
.font(
.system(
size: 13,
weight: .medium
)
)
.foregroundStyle(.white)
.lineLimit(1)
Spacer()
Image(systemName: "chevron.right")
.font(
.system(
size: 10,
weight: .bold
)
)
.foregroundStyle(.secondary)
}
.padding(.horizontal, 8)
.padding(.vertical, 8)
.background(
Color.discordCard,
in: RoundedRectangle(
cornerRadius: 14,
style: .continuous
)
)
.overlay(
RoundedRectangle(
cornerRadius: 14,
style: .continuous
)
.strokeBorder(
Color.discordBorder,
lineWidth: 1
)
)
}
.buttonStyle(.plain)
}
}
.padding(.horizontal, 2)
}
.background(
ZStack {
Color.discordBg
themeSync.backgroundGradient
.opacity(0.45)
}
.ignoresSafeArea()
)
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
ScrollView {
VStack(spacing: 6) {
ForEach(
discord.guildChannels
) { channel in
channelRow(for: channel)
}
}
.padding(.horizontal, 2)
}
.background(
ZStack {
Color.discordBg
themeSync.backgroundGradient
.opacity(0.45)
}
.ignoresSafeArea()
)
.navigationTitle()
.navigationBarTitleDisplayMode(.inline)
.task {
await discord.loadChannels(
for: 
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
guildID: ,
channelID: ,
channelName: channel.displayName,
isDM: false
)
} label: {
HStack(spacing: 8) {
Image(
systemName: "speaker.wave.2.fill"
)
.font(.caption)
.foregroundStyle(Color.discordGreen)
Text(channel.displayName)
.font(
.system(size: 13, weight: .medium)
)
.lineLimit(1)
Spacer()
Image(systemName: "chevron.right")
.font(.system(size: 10))
.foregroundStyle(.secondary)
}
.padding(.horizontal, 8)
.padding(.vertical, 8)
.background(
Color.discordCard,
in: RoundedRectangle(
cornerRadius: 13,
style: .continuous
)
)
.overlay(
RoundedRectangle(
cornerRadius: 13,
style: .continuous
)
.strokeBorder(
Color.discordBorder,
lineWidth: 1
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
.system(size: 13, weight: .medium)
)
.lineLimit(1)
Spacer()
Image(systemName: "chevron.right")
.font(.system(size: 10))
.foregroundStyle(.secondary)
}
.padding(.horizontal, 8)
.padding(.vertical, 8)
.background(
Color.discordCard,
in: RoundedRectangle(
cornerRadius: 13,
style: .continuous
)
)
.overlay(
RoundedRectangle(
cornerRadius: 13,
style: .continuous
)
.strokeBorder(
Color.discordBorder,
lineWidth: 1
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
.fill(Color.discordBlurple)
.frame(width: 20, height: 20)
Text()
}
}
}
.scrollContentBackground(.hidden)
.background(
ZStack {
Color.discordBg
themeSync.backgroundGradient
.opacity(0.45)
}
.ignoresSafeArea()
)
.navigationTitle("Nitro Themes")
.navigationBarTitleDisplayMode(.inline)
}
}

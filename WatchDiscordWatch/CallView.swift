import SwiftUI

struct CallView: View {
    @StateObject private var callManager: VoiceCallManager
    @Environment(\.openURL) private var openURL

    let channelName: String
    let isDM: Bool

    init(
        token: String,
        guildID: String?,
        channelID: String,
        channelName: String,
        isDM: Bool = false
    ) {
        self.channelName = channelName
        self.isDM = isDM
        _callManager = StateObject(
            wrappedValue: VoiceCallManager(
                token: token,
                guildID: guildID,
                channelID: channelID
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: isDM ? "phone.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)

                Text(channelName)
                    .font(.headline)
                    .lineLimit(1)

                Text(callManager.status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let error = callManager.lastError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    guard let url = callManager.discordChannelURL else {
                        callManager.reportOpenFailure()
                        return
                    }
                    openURL(url) { accepted in
                        if accepted {
                            callManager.markDiscordOpened()
                        } else {
                            callManager.reportOpenFailure()
                        }
                    }
                } label: {
                    Label("Open in Discord", systemImage: "arrow.up.forward.app")
                        .font(.footnote.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Text("Join, mute, deafen, and leave using Discord's own call controls.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Voice")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            callManager.disconnect()
        }
    }
}

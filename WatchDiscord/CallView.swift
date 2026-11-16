import SwiftUI

struct CallView: View {
    @StateObject private var callManager: VoiceCallManager

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
                // Header & Connection Status
                VStack(spacing: 4) {
                    Image(systemName: isDM ? "phone.fill" : "speaker.wave.2.fill")
                        .font(.title2)
                        .foregroundStyle(callManager.isConnected ? .green : .secondary)

                    Text(channelName)
                        .font(.headline)
                        .lineLimit(1)

                    Text(callManager.status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 4)

                // Error Banner (if any)
                if let error = callManager.lastError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }

                // Call Controls
                HStack(spacing: 14) {
                    // Mute Button
                    Button {
                        callManager.toggleMute()
                    } label: {
                        Image(systemName: callManager.isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.body)
                            .frame(width: 44, height: 44)
                            .background(callManager.isMuted ? Color.red.opacity(0.8) : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!callManager.isConnected)

                    // Deafen Button
                    Button {
                        callManager.toggleDeafen()
                    } label: {
                        Image(systemName: callManager.isDeafened ? "speaker.slash.fill" : "headphones")
                            .font(.body)
                            .frame(width: 44, height: 44)
                            .background(callManager.isDeafened ? Color.red.opacity(0.8) : Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!callManager.isConnected)
                }

                // Ring Button (Only shown for DM calls)
                if isDM {
                    Button {
                        Task {
                            await callManager.ringDMCall()
                        }
                    } label: {
                        Label("Ring", systemImage: "bell.and.waves.left.and.right.fill")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .disabled(!callManager.isConnected)
                }

                // Join / Leave Button
                Button(role: callManager.isConnected ? .destructive : nil) {
                    if callManager.isConnected {
                        callManager.disconnect()
                    } else {
                        callManager.connect()
                    }
                } label: {
                    Label(
                        callManager.isConnected ? "Leave Call" : "Join Call",
                        systemImage: callManager.isConnected ? "phone.down.fill" : "phone.fill"
                    )
                    .font(.footnote.weight(.bold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(callManager.isConnected ? .red : .green)
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Voice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            callManager.connect()
        }
        .onDisappear {
            callManager.disconnect()
        }
    }
}

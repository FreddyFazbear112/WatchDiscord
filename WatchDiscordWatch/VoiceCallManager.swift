import Foundation
import Combine

@MainActor
final class VoiceCallManager: ObservableObject {
    @Published private(set) var status = "Ready to open Discord"
    @Published private(set) var lastError: String?
    @Published private(set) var isConnected = false

    private let guildID: String?
    private let channelID: String

    init(token: String = "", guildID: String?, channelID: String) {
        self.guildID = guildID
        self.channelID = channelID
    }

    var discordChannelURL: URL? {
        let server = (guildID?.isEmpty == false) ? guildID! : "@me"
        return URL(string: "https://discord.com/channels/\(server)/\(channelID)")
    }

    func markDiscordOpened() {
        isConnected = false
        lastError = nil
        status = "Discord opened — join the call in the Discord app"
    }

    func reportOpenFailure() {
        lastError = "Couldn't open the Discord link. Make sure Discord is installed."
        status = "Unable to open Discord"
        isConnected = false
    }

    func disconnect() {
        status = "Returned from Discord"
        isConnected = false
    }
}

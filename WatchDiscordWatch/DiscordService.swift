import Foundation
import Combine

struct DiscordUser: Codable, Identifiable, Sendable {
    let id: String
    let username: String
    let globalName: String?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id, username, avatar
        case globalName = "global_name"
    }

    var displayName: String {
        globalName ?? username
    }
}

struct DiscordGuild: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String?
}

struct DiscordChannel: Codable, Identifiable, Sendable {
    let id: String
    let type: Int
    let guildID: String?
    let name: String?
    let recipients: [DiscordUser]?

    enum CodingKeys: String, CodingKey {
        case id, type, name, recipients
        case guildID = "guild_id"
    }

    var displayName: String {
        if let name, !name.isEmpty {
            return name
        }
        if let recipients, !recipients.isEmpty {
            return recipients.map(\.displayName).joined(separator: ", ")
        }
        return "Direct Message"
    }

    var isVoice: Bool {
        type == 2 || type == 13
    }
}

struct DiscordMessage: Codable, Identifiable, Sendable {
    let id: String
    let channelID: String
    let content: String
    let timestamp: String
    let author: DiscordUser

    enum CodingKeys: String, CodingKey {
        case id, content, timestamp, author
        case channelID = "channel_id"
    }
}

@MainActor
final class DiscordService: ObservableObject {
    @Published var currentUser: DiscordUser?
    @Published var dmChannels: [DiscordChannel] = []
    @Published var guilds: [DiscordGuild] = []
    @Published var guildChannels: [DiscordChannel] = []
    @Published var messages: [DiscordMessage] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let baseURL = "https://discord.com"
    private let session = URLSession(configuration: .default)
    private var token: String = ""

    func configure(token: String) {
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeRequest(path: String, method: String = "GET", body: [String: Any]? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Discord-iOS/250.0 (iPhone; iOS 17.5)", forHTTPHeaderField: "User-Agent")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    func loadInitialData() async {
        guard !token.isEmpty else {
            errorMessage = "Missing token. Sync from iPhone first."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            currentUser = try await fetch(path: "/users/@me")
            dmChannels = try await fetch(path: "/users/@me/channels")
            guilds = try await fetch(path: "/users/@me/guilds")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadChannels(for guildID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let all: [DiscordChannel] = try await fetch(path: "/guilds/\(guildID)/channels")
            guildChannels = all.filter { $0.type == 0 || $0.type == 2 || $0.type == 5 }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMessages(for channelID: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched: [DiscordMessage] = try await fetch(path: "/channels/\(channelID)/messages?limit=30")
            messages = fetched.reversed()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage(to channelID: String, content: String) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            let request = try makeRequest(
                path: "/channels/\(channelID)/messages",
                method: "POST",
                body: ["content": trimmed]
            )
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)
            let sent = try JSONDecoder().decode(DiscordMessage.self, from: data)
            messages.append(sent)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addReaction(channelID: String, messageID: String, emoji: String) async {
        guard let encoded = emoji.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return }
        do {
            let request = try makeRequest(
                path: "/channels/\(channelID)/messages/\(messageID)/reactions/\(encoded)/@me",
                method: "PUT"
            )
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetch<T: Decodable>(path: String) async throws -> T {
        let request = try makeRequest(path: path)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "DiscordAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(body)"
            ])
        }
    }
}

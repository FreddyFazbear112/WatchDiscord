import Foundation
import Combine

struct VoiceMediaConfiguration: Sendable {
    let endpoint: String
    let ssrc: UInt32
    let port: UInt16
    let encryptionModes: [String]
}

struct VoiceUDPDiscovery: Sendable {
    let address: String
    let port: UInt16
    let mode: String
}

protocol VoiceMediaTransport: Sendable {
    func discover(configuration: VoiceMediaConfiguration) async throws -> VoiceUDPDiscovery
    func start(configuration: VoiceMediaConfiguration) async throws
    func stop() async
}

struct UnavailableVoiceMediaTransport: VoiceMediaTransport {
    func discover(configuration: VoiceMediaConfiguration) async throws -> VoiceUDPDiscovery {
        throw VoiceCallError.mediaTransportUnavailable
    }

    func start(configuration: VoiceMediaConfiguration) async throws {}
    func stop() async {}
}

enum VoiceCallError: LocalizedError {
    case invalidGatewayURL
    case invalidVoiceEndpoint
    case gatewayClosed
    case voiceGatewayClosed
    case missingReadyData
    case mediaTransportUnavailable
    case serverRejected(String)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidGatewayURL: return "The Discord Gateway URL is invalid."
        case .invalidVoiceEndpoint: return "The voice server endpoint is invalid."
        case .gatewayClosed: return "The Discord Gateway connection closed."
        case .voiceGatewayClosed: return "The voice Gateway connection closed."
        case .missingReadyData: return "Discord did not provide the required voice session data."
        case .mediaTransportUnavailable: return "The voice media transport has not been installed."
        case .serverRejected(let message): return message
        case .invalidPayload: return "Discord returned an invalid Gateway payload."
        }
    }
}

@MainActor
final class VoiceCallManager: ObservableObject {
    @Published private(set) var status = "Disconnected"
    @Published private(set) var isConnected = false
    @Published private(set) var currentUserID: String?
    @Published private(set) var isMuted = false
    @Published private(set) var isDeafened = false
    @Published private(set) var lastError: String?

    private let token: String
    private let guildID: String?
    private let channelID: String
    private let mediaTransport: any VoiceMediaTransport

    private let session: URLSession
    private var gatewayTask: URLSessionWebSocketTask?
    private var voiceTask: URLSessionWebSocketTask?
    private var gatewayHeartbeatTask: Task<Void, Never>?
    private var voiceHeartbeatTask: Task<Void, Never>?
    private var gatewayReceiveTask: Task<Void, Never>?
    private var voiceReceiveTask: Task<Void, Never>?

    private var gatewayHeartbeatInterval: TimeInterval = 0
    private var voiceHeartbeatInterval: TimeInterval = 0
    private var lastGatewaySequence: Int = -1
    private var lastVoiceSequence: Int = -1

    private var voiceSessionID: String?
    private var voiceToken: String?
    private var voiceEndpoint: String?
    private var voiceReady: VoiceMediaConfiguration?

    private var gatewayReady = false
    private var voiceStateReceived = false
    private var voiceServerReceived = false

    init(
        token: String,
        guildID: String?,
        channelID: String,
        mediaTransport: any VoiceMediaTransport = UnavailableVoiceMediaTransport()
    ) {
        self.token = token
        self.guildID = guildID
        self.channelID = channelID
        self.mediaTransport = mediaTransport
        self.session = URLSession(configuration: .ephemeral)
    }

    func connect() {
        guard gatewayTask == nil else { return }

        lastError = nil
        status = "Connecting to Discord…"

        guard let url = URL(string: "wss://gateway.discord.gg/?v=10&encoding=json") else {
            report(VoiceCallError.invalidGatewayURL)
            return
        }

        let task = session.webSocketTask(with: url)
        gatewayTask = task
        task.resume()

        gatewayReceiveTask = Task { [weak self] in
            await self?.receiveGatewayMessages()
        }
    }

    func disconnect() {
        if gatewayReady {
            let guildValue: Any = guildID ?? NSNull()
            let leavePayload: [String: Any] = [
                "op": 4,
                "d": [
                    "guild_id": guildValue,
                    "channel_id": NSNull(),
                    "self_mute": isMuted,
                    "self_deaf": isDeafened
                ]
            ]
            sendJSON(leavePayload, on: gatewayTask)
        }

        gatewayHeartbeatTask?.cancel()
        voiceHeartbeatTask?.cancel()
        gatewayReceiveTask?.cancel()
        voiceReceiveTask?.cancel()

        gatewayTask?.cancel(with: .normalClosure, reason: nil)
        voiceTask?.cancel(with: .normalClosure, reason: nil)

        gatewayTask = nil
        voiceTask = nil
        gatewayReady = false
        voiceStateReceived = false
        voiceServerReceived = false
        voiceSessionID = nil
        voiceToken = nil
        voiceEndpoint = nil
        voiceReady = nil

        Task {
            await mediaTransport.stop()
        }

        isConnected = false
        status = "Disconnected"
    }

    func toggleMute() {
        isMuted.toggle()
        sendVoiceStateUpdate()
    }

    func toggleDeafen() {
        isDeafened.toggle()
        if isDeafened { isMuted = true }
        sendVoiceStateUpdate()
    }

    func ringDMCall() async {
        guard guildID == nil,
              let url = URL(string: "https://discord.com\(channelID)/call/ring") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["recipients": NSNull()])
        _ = try? await session.data(for: request)
    }

    private func receiveGatewayMessages() async {
        guard let task = gatewayTask else { return }

        do {
            while !Task.isCancelled {
                let message = try await task.receive()
                let data = try messageData(message)
                try await handleGatewayPayload(data)
            }
        } catch {
            if !Task.isCancelled {
                report(error)
                disconnect()
            }
        }
    }

    private func handleGatewayPayload(_ data: Data) async throws {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let opcode = json["op"] as? Int
        else {
            throw VoiceCallError.invalidPayload
        }

        if let sequence = json["s"] as? Int {
            lastGatewaySequence = sequence
        }

        switch opcode {
        case 10:
            guard
                let payload = json["d"] as? [String: Any],
                let milliseconds = payload["heartbeat_interval"] as? Double
            else {
                throw VoiceCallError.invalidPayload
            }

            gatewayHeartbeatInterval = milliseconds / 1000
            sendGatewayIdentify()
            startGatewayHeartbeat()

        case 11:
            break

        case 0:
            let eventName = json["t"] as? String ?? ""
            let payload = json["d"] as? [String: Any] ?? [:]

            switch eventName {
            case "READY":
                if let user = payload["user"] as? [String: Any],
                   let id = user["id"] as? String {
                    currentUserID = id
                    gatewayReady = true
                    status = "Connected to Discord"
                    sendVoiceStateUpdate()
                }

            case "VOICE_STATE_UPDATE":
                let userID = payload["user_id"] as? String
                let eventGuildID = payload["guild_id"] as? String
                if userID == currentUserID,
                   eventGuildID == guildID,
                   let sessionID = payload["session_id"] as? String {
                    voiceSessionID = sessionID
                    voiceStateReceived = true
                    await connectVoiceIfReady()
                }

            case "VOICE_SERVER_UPDATE":
                let eventGuildID = payload["guild_id"] as? String
                let eventChannelID = payload["channel_id"] as? String
                if (eventGuildID == guildID || eventChannelID == channelID),
                   let vToken = payload["token"] as? String,
                   let endpoint = payload["endpoint"] as? String {
                    voiceToken = vToken
                    voiceEndpoint = endpoint
                    voiceServerReceived = true
                    await connectVoiceIfReady()
                }

            default:
                break
            }

        case 7:
            status = "Discord requested reconnect"
            disconnect()

        default:
            break
        }
    }

    private func sendGatewayIdentify() {
        let payload: [String: Any] = [
            "op": 2,
            "d": [
                "token": token,
                "properties": [
                    "os": "iOS",
                    "browser": "Discord iOS",
                    "device": "iPhone"
                ]
            ]
        ]

        sendJSON(payload, on: gatewayTask)
    }

    private func sendVoiceStateUpdate() {
        let guildValue: Any = guildID ?? NSNull()
        let payload: [String: Any] = [
            "op": 4,
            "d": [
                "guild_id": guildValue,
                "channel_id": channelID,
                "self_mute": isMuted,
                "self_deaf": isDeafened
            ]
        ]

        sendJSON(payload, on: gatewayTask)
        if !isConnected {
            status = "Requesting voice connection…"
}
}
private func startGatewayHeartbeat() {
gatewayHeartbeatTask?.cancel()
gatewayHeartbeatTask = Task { [weak self] in
guard let self else { return }
while !Task.isCancelled {
let delay = self.gatewayHeartbeatInterval
try? await Task.sleep(nanoseconds: UInt64(max(0.1, delay) * 1_000_000_000))
if Task.isCancelled { return }
let seqValue: Any = self.lastGatewaySequence >= 0 ? self.lastGatewaySequence : NSNull()
self.sendJSON([
"op": 1,
"d": seqValue
], on: self.gatewayTask)
}
}
}
private func connectVoiceIfReady() async {
guard
gatewayReady,
voiceStateReceived,
voiceServerReceived,
voiceTask == nil,
let endpoint = voiceEndpoint
else {
return
}
let cleanEndpoint = endpoint
.replacingOccurrences(of: "wss://", with: "")
.replacingOccurrences(of: "https://", with: "")
.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
guard let url = URL(string: "wss://(cleanEndpoint)/?v=8") else {
report(VoiceCallError.invalidVoiceEndpoint)
return
}
status = "Opening Voice Gateway…"
let task = session.webSocketTask(with: url)
voiceTask = task
task.resume()
voiceReceiveTask = Task { [weak self] in
await self?.receiveVoiceMessages()
}
}
private func receiveVoiceMessages() async {
guard let task = voiceTask else { return }
do {
while !Task.isCancelled {
let message = try await task.receive()
let data = try messageData(message)
try await handleVoicePayload(data)
}
} catch {
if !Task.isCancelled {
report(error)
disconnect()
}
}
}
private func handleVoicePayload(_ data: Data) async throws {
guard
let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
let opcode = json["op"] as? Int
else {
throw VoiceCallError.invalidPayload
}
if let sequence = json["seq"] as? Int {
lastVoiceSequence = sequence
}
let payload = json["d"] as? [String: Any] ?? [:]
switch opcode {
case 2:
guard
let ssrcValue = payload["ssrc"] as? UInt32,
let portValue = payload["port"] as? UInt16,
let modes = payload["modes"] as? [String],
let endpoint = voiceEndpoint
else {
throw VoiceCallError.missingReadyData
}
let configuration = VoiceMediaConfiguration(
endpoint: endpoint,
ssrc: ssrcValue,
port: portValue,
encryptionModes: modes
)
voiceReady = configuration
isConnected = true
status = "In Voice Channel"
case 4:
status = "Voice session active"
case 8:
guard let milliseconds = payload["heartbeat_interval"] as? Double else {
throw VoiceCallError.invalidPayload
}
voiceHeartbeatInterval = milliseconds / 1000
sendVoiceIdentify()
startVoiceHeartbeat()
case 9:
status = "Voice session resumed"
default:
break
}
}
private func sendVoiceIdentify() {
guard
let task = voiceTask,
let sessionID = voiceSessionID,
let token = voiceToken
else {
return
}
let serverIdentifier = guildID ?? channelID
let payload: [String: Any] = [
"op": 0,
"d": [
"server_id": serverIdentifier,
"user_id": currentUserID ?? "",
"session_id": sessionID,
"token": token,
"max_dave_protocol_version": 0
]
]
sendJSON(payload, on: task)
}
private func startVoiceHeartbeat() {
voiceHeartbeatTask?.cancel()
voiceHeartbeatTask = Task { [weak self] in
guard let self else { return }
while !Task.isCancelled {
try? await Task.sleep(
nanoseconds: UInt64(max(0.1, self.voiceHeartbeatInterval) * 1_000_000_000)
)
if Task.isCancelled { return }
self.sendJSON([
"op": 3,
"d": [
"t": Int(Date().timeIntervalSince1970 * 1000),
"seq_ack": self.lastVoiceSequence
]
], on: self.voiceTask)
}
}
}
func selectVoiceProtocol(discovery: VoiceUDPDiscovery) {
guard let task = voiceTask else { return }
let payload: [String: Any] = [
"op": 1,
"d": [
"protocol": "udp",
"data": [
"address": discovery.address,
"port": discovery.port,
"mode": discovery.mode
]
]
]
sendJSON(payload, on: task)
}
func sendSpeakingState(ssrc: UInt32, speaking: Bool) {
guard let task = voiceTask else { return }
sendJSON([
"op": 5,
"d": [
"speaking": speaking ? 1 : 0,
"delay": 0,
"ssrc": ssrc
]
], on: task)
}
private func sendJSON(_ object: [String: Any], on task: URLSessionWebSocketTask?) {
guard
let task,
let data = try? JSONSerialization.data(withJSONObject: object),
let string = String(data: data, encoding: .utf8)
else {
return
}
task.send(.string(string)) { [weak self] error in
if let error {
Task { @MainActor in
self?.report(error)
}
}
}
}
private func messageData(_ message: URLSessionWebSocketTask.Message) throws -> Data {
switch message {
case .data(let data):
return data
case .string(let string):
guard let data = string.data(using: .utf8) else {
throw VoiceCallError.invalidPayload
}
return data
@unknown default:
throw VoiceCallError.invalidPayload
}
}
private func report(_ error: Error) {
lastError = error.localizedDescription
status = "Error: (error.localizedDescription)"
}
}

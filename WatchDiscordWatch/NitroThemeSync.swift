import SwiftUI
import Combine

@MainActor
final class NitroThemeSync: ObservableObject {
    @Published var primaryColor: Color = Color(hex: 0x5865F2)
    @Published var secondaryColor: Color = Color(hex: 0x1E1F22)
    @Published var gradientAngle: Double = 45.0
    @Published var statusMessage: String?

    private let baseURL = "https://discord.com"
    private let session = URLSession(configuration: .default)
    private var token: String = ""

    struct ThemePreset: Identifiable {
        let id = UUID()
        let name: String
        let primaryHex: Int
        let secondaryHex: Int
    }

    let presets: [ThemePreset] = [
        ThemePreset(name: "Blurple Dark", primaryHex: 0x5865F2, secondaryHex: 0x1E1F22),
        ThemePreset(name: "Mint Apple", primaryHex: 0xB8F2E6, secondaryHex: 0x2A4D69),
        ThemePreset(name: "Citrus Sherbet", primaryHex: 0xFF9F1C, secondaryHex: 0x5C1A1B),
        ThemePreset(name: "Chroma Glow", primaryHex: 0x7209B7, secondaryHex: 0x10002B),
        ThemePreset(name: "Crimson Sunset", primaryHex: 0xD90429, secondaryHex: 0x2B2D42),
        ThemePreset(name: "Midnight", primaryHex: 0x0B0C10, secondaryHex: 0x000000)
    ]

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor.opacity(0.45), secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func configure(token: String) {
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func fetchTheme() async {
        guard !token.isEmpty,
              let url = URL(string: "\(baseURL)/users/@me/settings") else { return }

        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

            if let themeColors = json["theme_colors"] as? [Int], themeColors.count >= 2 {
                primaryColor = Color(hex: themeColors[0])
                secondaryColor = Color(hex: themeColors[1])
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func applyAndSync(preset: ThemePreset) async {
        primaryColor = Color(hex: preset.primaryHex)
        secondaryColor = Color(hex: preset.secondaryHex)

        guard !token.isEmpty,
              let url = URL(string: "\(baseURL)/users/@me/settings") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "theme_colors": [preset.primaryHex, preset.secondaryHex]
        ])

        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                statusMessage = "Synced \(preset.name)"
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

extension Color {
    init(hex: Int) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

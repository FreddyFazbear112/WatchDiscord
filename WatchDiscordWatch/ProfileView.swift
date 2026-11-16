import SwiftUI

struct DiscordFullProfile: Codable, Sendable {
    let user: DiscordUser
    let userProfile: ProfileMetadata?

    enum CodingKeys: String, CodingKey {
        case user
        case userProfile = "user_profile"
    }

    struct ProfileMetadata: Codable, Sendable {
        let bio: String?
        let pronouns: String?
        let banner: String?
        let themeColors: [Int]?

        enum CodingKeys: String, CodingKey {
            case bio, pronouns, banner
            case themeColors = "theme_colors"
        }
    }
}

struct ProfileView: View {
    let token: String
    let userID: String
    let isCurrentUser: Bool

    @State private var profile: DiscordFullProfile?
    @State private var bioInput = ""
    @State private var pronounsInput = ""
    @State private var isSaving = false
    @State private var feedbackMessage: String?

    private let baseURL = "https://discord.com"

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let profile {
                    avatarView(for: profile.user)

                    Text(profile.user.displayName)
                        .font(.headline)

                    Text("@\(profile.user.username)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let pronouns = profile.userProfile?.pronouns, !pronouns.isEmpty {
                        Text(pronouns)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    if !isCurrentUser {
                        if let bio = profile.userProfile?.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pronouns")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            TextField("Pronouns", text: $pronounsInput)

                            Text("Bio")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            TextField("About me", text: $bioInput)

                            Button {
                                Task { await saveProfile() }
                            } label: {
                                Text(isSaving ? "Saving…" : "Save Profile")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSaving)
                        }
                    }

                    if let feedbackMessage {
                        Text(feedbackMessage)
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                } else {
                    ProgressView("Loading Profile…")
                }
            }
            .padding(.horizontal, 6)
        }
        .background(profileGradient.ignoresSafeArea())
        .navigationTitle("Profile")
        .task {
            await loadProfile()
        }
    }

    private var profileGradient: LinearGradient {
        if let colors = profile?.userProfile?.themeColors, colors.count >= 2 {
            return LinearGradient(
                colors: [Color(hex: colors[0]).opacity(0.6), Color(hex: colors[1]).opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color(hex: 0x5865F2).opacity(0.35), Color.black],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private func avatarView(for user: DiscordUser) -> some View {
        if let avatar = user.avatar,
           let url = URL(string: "https://discordapp.com\(user.id)/\(avatar).png?size=128") {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.4))
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
        }
    }

    private func loadProfile() async {
        guard let url = URL(string: "\(baseURL)/users/\(userID)/profile") else { return }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return }
            let decoded = try JSONDecoder().decode(DiscordFullProfile.self, from: data)
            profile = decoded
            bioInput = decoded.userProfile?.bio ?? ""
            pronounsInput = decoded.userProfile?.pronouns ?? ""
        } catch {
            feedbackMessage = error.localizedDescription
        }
    }

    private func saveProfile() async {
        guard let url = URL(string: "\(baseURL)/users/@me/profile") else { return }
        isSaving = true
        defer { isSaving = false }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "bio": bioInput,
            "pronouns": pronounsInput
        ])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                feedbackMessage = "Profile synced!"
            }
        } catch {
            feedbackMessage = error.localizedDescription
        }
    }
}

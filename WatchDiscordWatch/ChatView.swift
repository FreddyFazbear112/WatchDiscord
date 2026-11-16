import SwiftUI

struct ChatView: View {
    @ObservedObject var discord: DiscordService
    @ObservedObject var themeSync: NitroThemeSync
    let token: String
    let channel: DiscordChannel

    @State private var draftMessage = ""
    @State private var selectedMessageForReaction: DiscordMessage?
    @State private var selectedUserForProfile: DiscordUser?

    private let quickReactions = ["👍", "❤️", "😂", "🔥", "😭", "💀"]

    var body: some View {
        VStack(spacing: 4) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(discord.messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                                .onTapGesture {
                                    selectedMessageForReaction = msg
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .onChange(of: discord.messages.count) { _, _ in
                    if let lastID = discord.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            // Native Watch Text Input (Dictation / Scribble / Keyboard)
            HStack(spacing: 6) {
                TextField("Message…", text: $draftMessage)
                    .font(.footnote)

                if !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        let textToSend = draftMessage
                        draftMessage = ""
                        Task {
                            await discord.sendMessage(to: channel.id, content: textToSend)
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(themeSync.primaryColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
        .background(themeSync.backgroundGradient.ignoresSafeArea())
        .navigationTitle(channel.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CallView(
                        token: token,
                        guildID: channel.guildID,
                        channelID: channel.id,
                        channelName: channel.displayName,
                        isDM: channel.guildID == nil
                    )
                } label: {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .sheet(item: $selectedMessageForReaction) { msg in
            VStack(spacing: 10) {
                Text("React to \(msg.author.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 38))], spacing: 8) {
                    ForEach(quickReactions, id: \.self) { emoji in
                        Button(emoji) {
                            selectedMessageForReaction = nil
                            Task {
                                await discord.addReaction(
                                    channelID: channel.id,
                                    messageID: msg.id,
                                    emoji: emoji
                                )
                            }
                        }
                        .font(.title3)
                    }
                }

                Button("View Profile") {
                    let author = msg.author
                    selectedMessageForReaction = nil
                    selectedUserForProfile = author
                }
                .font(.caption2)
            }
            .padding()
        }
        .sheet(item: $selectedUserForProfile) { user in
            ProfileView(token: token, userID: user.id, isCurrentUser: user.id == discord.currentUser?.id)
        }
        .task {
            await discord.loadMessages(for: channel.id)
        }
    }

    @ViewBuilder
    private func messageBubble(_ msg: DiscordMessage) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(msg.author.displayName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(themeSync.primaryColor)

            if let gifURL = extractImageURL(from: msg.content) {
                AsyncImage(url: gifURL) { img in
                    img.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 90)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if !msg.content.isEmpty {
                Text(msg.content)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func extractImageURL(from text: String) -> URL? {
        let lower = text.lowercased()
        guard lower.hasPrefix("http"),
              (lower.contains(".gif") || lower.contains(".png") || lower.contains(".jpg") || lower.contains("tenor.com")) else {
            return nil
        }
        return URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

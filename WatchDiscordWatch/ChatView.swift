import SwiftUI

/// A presentation view for messages supplied by a supported data source.
struct ChatView: View {
    let channelName: String
    let messages: [ChatMessage]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if messages.isEmpty {
                    ContentUnavailableView(
                        "No messages to show",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Messages will appear here when a supported Discord data source is connected.")
                    )
                    .padding(.top, 24)
                } else {
                    ForEach(messages) { message in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 5) {
                                Text(message.author)
                                    .font(.caption.weight(.semibold))
                                Spacer(minLength: 4)
                                Text(message.timestamp, style: .time)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            Text(message.content)
                                .font(.footnote)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
                    }
                }
            }
            .padding(10)
        }
        .background(Color(red: 0.045, green: 0.052, blue: 0.075))
        .navigationTitle(channelName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatMessage: Identifiable, Hashable {
    let id: String
    let author: String
    let content: String
    let timestamp: Date
}

import SwiftUI

private enum WatchPalette {
    static let background = Color(red: 0.045, green: 0.052, blue: 0.075)
    static let accent = Color(red: 0.48, green: 0.43, blue: 1.0)
}

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 5) {
                        Image(systemName: "waveform").font(.system(size: 27, weight: .bold)).foregroundStyle(WatchPalette.accent)
                        Text("WATCHCORD").font(.system(size: 13, weight: .black, design: .rounded)).tracking(1.8)
                        Text("Discord at a glance").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)

                    NavigationLink {
                        WatchInfoView(title: "Messages", symbol: "bubble.left.and.bubble.right.fill", detail: "Your recent DMs and server conversations will appear here once account sync is connected.")
                    } label: {
                        WatchTile(title: "Messages", subtitle: "Open conversations", symbol: "bubble.left.and.bubble.right.fill")
                    }
                    NavigationLink {
                        WatchInfoView(title: "Servers", symbol: "person.3.fill", detail: "Your servers and channels will appear here after secure Discord sign-in is available.")
                    } label: {
                        WatchTile(title: "Servers", subtitle: "Browse communities", symbol: "person.3.fill")
                    }
                    NavigationLink {
                        WatchInfoView(title: "Voice", symbol: "phone.fill", detail: "Use Discord's official app for voice calls. This companion does not connect to Discord voice directly.")
                    } label: {
                        WatchTile(title: "Voice", subtitle: "Open call handoff info", symbol: "phone.fill")
                    }

                    Text("Connect from iPhone to get started.")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.top, 3)
                }
                .padding(.horizontal, 8)
            }
            .background(WatchPalette.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

private struct WatchTile: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.headline).foregroundStyle(WatchPalette.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(subtitle).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct WatchInfoView: View {
    let title: String
    let symbol: String
    let detail: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 30)).foregroundStyle(WatchPalette.accent)
            Text(title).font(.headline)
            Text(detail).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(12)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(WatchPalette.background)
    }
}

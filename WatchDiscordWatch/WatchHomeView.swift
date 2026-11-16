import SwiftUI

private enum WatchPalette {
    static let background = Color(red: 0.045, green: 0.052, blue: 0.075)
    static let accent = Color(red: 0.48, green: 0.43, blue: 1.0)
    static let panel = Color.white.opacity(0.075)
}

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 13) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WATCHCORD")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(WatchPalette.accent)
                        Text("Your wrist. Your Discord.")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text("Companion dashboard")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 3)

                    NavigationLink {
                        WatchSectionView(title: "Inbox", symbol: "bubble.left.and.bubble.right.fill", description: "Your direct messages and recent conversations will appear here when the supported account connection is available.")
                    } label: {
                        WatchDashboardTile(title: "Inbox", subtitle: "Direct messages", symbol: "bubble.left.and.bubble.right.fill", tint: .indigo)
                    }

                    NavigationLink {
                        WatchSectionView(title: "Servers", symbol: "person.3.fill", description: "Your servers and channels will be organized here after account setup and supported data access.")
                    } label: {
                        WatchDashboardTile(title: "Servers", subtitle: "Communities and channels", symbol: "person.3.fill", tint: .purple)
                    }

                    NavigationLink {
                        WatchSectionView(title: "Activity", symbol: "bell.badge.fill", description: "WatchCord can show notifications delivered to WatchCord. It cannot intercept or replace notifications mirrored from the official Discord iPhone app.")
                    } label: {
                        WatchDashboardTile(title: "Activity", subtitle: "Mentions and updates", symbol: "bell.badge.fill", tint: .orange)
                    }

                    NavigationLink {
                        WatchSectionView(title: "Voice", symbol: "phone.fill", description: "For voice calls, open the relevant conversation in Discord's official app. WatchCord does not connect to Discord voice as a personal-account client.")
                    } label: {
                        WatchDashboardTile(title: "Voice", subtitle: "Call handoff", symbol: "phone.fill", tint: .green)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Label("IPHONE CONNECTION", systemImage: "iphone")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(WatchPalette.accent)
                        Text("Finish Discord sign-in in the iPhone app.")
                            .font(.system(size: 11, weight: .medium))
                        Text("Live messages will appear once secure sync is connected.")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(11)
                    .background(WatchPalette.panel, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
            }
            .background(WatchPalette.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

private struct WatchDashboardTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .bold))
                Text(subtitle).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(WatchPalette.panel, in: RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
    }
}

private struct WatchSectionView: View {
    let title: String
    let symbol: String
    let description: String

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(WatchPalette.accent)
                Text(title).font(.headline)
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(12)
        }
        .background(WatchPalette.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

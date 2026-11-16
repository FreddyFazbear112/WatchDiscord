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
                        Text("Discord on your wrist")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text("Personal-account companion")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 3)

                    NavigationLink {
                        WatchGuideView(
                            title: "Get Discord alerts",
                            symbol: "bell.badge.fill",
                            steps: [
                                "On iPhone, open Settings → Notifications → Discord.",
                                "Turn on Allow Notifications and choose the alert types you want.",
                                "Open the Watch app on iPhone → Notifications.",
                                "Find Discord and enable notification mirroring."
                            ],
                            note: "When your iPhone is locked or asleep, eligible Discord alerts can appear on your watch. Tap an alert to view it. Reply options depend on the notification actions Discord and watchOS provide."
                        )
                    } label: {
                        WatchDashboardTile(title: "Discord notifications", subtitle: "Read alerts and use available replies", symbol: "bell.badge.fill", tint: .orange)
                    }

                    NavigationLink {
                        WatchGuideView(
                            title: "What WatchCord can do",
                            symbol: "applewatch",
                            steps: [
                                "Use your existing Discord account in the official Discord app on iPhone.",
                                "Let Apple Watch mirror eligible Discord notifications.",
                                "Use any reply actions shown on a notification, when available."
                            ],
                            note: "WatchCord does not currently have access to your personal DM inbox. Discord does not provide third-party apps a supported API for reading personal DMs or sending as your user account."
                        )
                    } label: {
                        WatchDashboardTile(title: "How it works", subtitle: "Your account, with platform limits", symbol: "info.circle.fill", tint: .indigo)
                    }

                    NavigationLink {
                        WatchGuideView(
                            title: "Voice calls",
                            symbol: "phone.fill",
                            steps: [
                                "Start or answer Discord voice calls in the official Discord app.",
                                "Use the audio device controls available on your iPhone or connected headset."
                            ],
                            note: "WatchCord cannot act as an independent Discord voice client or control a personal-account call."
                        )
                    } label: {
                        WatchDashboardTile(title: "Voice", subtitle: "Use Discord's official call experience", symbol: "phone.fill", tint: .green)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Label("NO FAKE INBOX", systemImage: "checkmark.shield")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(WatchPalette.accent)
                        Text("This app won't show invented conversations or pretend your DMs are synced.")
                            .font(.system(size: 11, weight: .medium))
                        Text("Your actual Discord alerts are handled by iOS and watchOS notification mirroring.")
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
                Text(subtitle).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(2)
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

private struct WatchGuideView: View {
    let title: String
    let symbol: String
    let steps: [String]
    let note: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(WatchPalette.accent)
                    .frame(maxWidth: .infinity)
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(WatchPalette.accent)
                        Text(step)
                            .font(.caption2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(note)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(WatchPalette.panel, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(12)
        }
        .background(WatchPalette.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

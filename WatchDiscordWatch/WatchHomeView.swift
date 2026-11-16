import SwiftUI

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("WatchDiscord", systemImage: "message").font(.headline)
                }
                Section("Companion") {
                    Text("Connect your Discord account from the iPhone app.")
                    Label("Messages", systemImage: "bubble.left")
                    Label("Servers", systemImage: "person.2")
                    Label("Calls unavailable", systemImage: "phone.down").foregroundStyle(.secondary)
                }
                Section {
                    Text("Starter shell only. Live Discord data requires supported API access and secure credential handling.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("WatchDiscord")
        }
    }
}

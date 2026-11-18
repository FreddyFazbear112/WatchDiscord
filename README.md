# WatchDiscord

A native SwiftUI Discord client built specifically for Apple Watch, paired with an iOS companion app that handles authentication and session syncing in the background.

Designed to keep things fast, minimal, and easy to navigate on a small screen without relying on heavy web wrappers.

---

## Features

- **Servers & Channels:** Navigate through your joined servers, categories, and text channels with a clean watchOS list layout.
- **Direct Messages:** View recent DM conversations, group chats, and unread message indicators directly from your wrist.
- **Live Messaging:** Read message history, view attachments/embeds, and send replies using watchOS dictation, Scribble, or the on-screen keyboard.
- **Voice Channels:** Connect to voice channels and manage mute/deafen controls right from your Apple Watch.
- **iOS Companion Sync:** Log in once on your iPhone and automatically transfer your active session to your Apple Watch via WatchConnectivity.
- **Lightweight Footprint:** Built purely with native Swift and SwiftUI for smooth scrolling and low battery impact.

---

## Project Structure

```text
WatchDiscord/
├── WatchDiscord/                 # iOS companion app (login, settings, WatchConnectivity sync)
├── WatchDiscordWatch/            # watchOS app & WatchKit extension (UI, Discord API & Gateway)
│   ├── WatchApp-Info.plist
│   └── WatchExt-Info.plist
├── project.yml                   # XcodeGen project specification
└── .github/workflows/build.yml   # Automated CI workflow to build an unsigned .ipa
```

---

## Requirements

- **iOS:** 17.0 or later
- **watchOS:** 10.0 or later
- **Build Tools (if compiling locally):** macOS with Xcode 15+ and [XcodeGen](https://github.com)

---

## Installation

### Method 1: Install via Sideloadly (Recommended)
1. Download the latest `WatchDiscord.ipa` from the **Releases** page or the latest **GitHub Actions** build artifact.
2. Open **Sideloadly** on your PC or Mac and connect your iPhone (via USB or Wi-Fi).
3. Drag `WatchDiscord.ipa` into Sideloadly and enter your Apple ID.
4. Expand **Advanced Options**, enable **Use automatic bundle ID**, and make sure **Remove Watch app** is unchecked.
5. Click **Start** to sign and install the app onto your iPhone.
6. Open the **Watch** app on your iPhone, scroll down to **Available Apps**, and tap **Install** next to **WatchDiscord**.

### Method 2: Build From Source
1. Clone the repository:
   ```bash
   git clone https://github.com
   cd WatchDiscord
   ```
2. Install XcodeGen (if not already installed) and generate the `.xcodeproj`:
   ```bash
   brew install xcodegen
   xcodegen generate
   ```
3. Open `WatchDiscord.xcodeproj` in Xcode.
4. Under **Signing & Capabilities**, select your personal or paid Apple Developer team for all three targets (`WatchDiscord`, `WatchDiscordWatch`, and `WatchDiscordWatchExtension`).
5. Select your iPhone as the run destination and press **Cmd + R** to build and install both the iOS and watchOS apps.

---

## Troubleshooting

- **App doesn't appear in the Apple Watch app:** Make sure **Use automatic bundle ID** was checked in Sideloadly and that **Remove Watch app** was disabled. Force-close and reopen the Apple Watch app on your iPhone while your Watch is unlocked.
- **"Integrity could not be verified" on Apple Watch:** Ensure **Developer Mode** is turned on under **Settings > Privacy & Security** on your Apple Watch (if prompted), and re-sign using Sideloadly so nested watchOS bundles are properly signed.
- **Session not syncing to Watch:** Open **WatchDiscord** on both your iPhone and Apple Watch at the same time while Bluetooth is active to complete the initial session handshake.

---

## Disclaimer

This project is an independent, unofficial client built for personal and educational use. It is not affiliated with, endorsed by, or connected to Discord Inc. Use third-party clients at your own discretion.

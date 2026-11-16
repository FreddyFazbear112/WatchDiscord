# WatchDiscord

SwiftUI starter project for iOS and watchOS.

## Current status

- iOS and watchOS app shells.
- GitHub Actions workflow for unsigned iOS IPA packaging and watchOS archive.
- Discord OAuth, live messages, themes, and voice calls are not implemented yet.
- OAuth must use a Discord application and secure authorization-code exchange; do not embed a client secret or personal user token.
- Use supported bot APIs for server integrations. Ordinary user OAuth does not provide unrestricted channel message access.
- Discord voice requires separate voice signaling, UDP media, Opus, transport encryption, and DAVE end-to-end encryption. A simple WebSocket/UDP placeholder is not a working call implementation.

## Build locally

Install Xcode and XcodeGen, then run:

```sh
xcodegen generate
xcodebuild -project WatchDiscord.xcodeproj -scheme WatchDiscord -destination 'generic/platform=iOS' archive CODE_SIGNING_ALLOWED=NO
```

The GitHub workflow runs on pushes, pull requests, and manual dispatch. The IPA is unsigned; SideStore must sign it before installation.

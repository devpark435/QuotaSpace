# QuotaSpace

A native macOS app, menu bar monitor, and desktop widget for AI quotas and system capacity.

## Requirements

- macOS 26
- Xcode 26.2 or later

## Run

Open `QuotaSpace.xcodeproj`, select the `QuotaSpace` scheme, and run.

On first launch, QuotaSpace finds the active Claude Code account, Codex, and local disk capacity. Each monitored item can have its own menu bar status item.

Claude usage is read with the current Claude Code credential in macOS Keychain. Codex usage is read from the local `codex app-server`. QuotaSpace does not store access tokens or account email addresses.

While QuotaSpace is running, local Claude and Codex session activity triggers a debounced refresh. A periodic refresh runs as a fallback.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for trademark notices.

# QuotaSpace

A native macOS app, menu bar monitor, and desktop widget for AI quotas and system capacity.

## Requirements

- macOS 26
- Xcode 26.2 or later

## Run

Open `QuotaSpace.xcodeproj`, select the `QuotaSpace` scheme, and run.

On first launch, QuotaSpace finds Claude profiles referenced by `CLAUDE_CONFIG_DIR`, the default Claude profile, Codex, and local disk capacity. Each monitored item can have its own menu bar status item. Claude uses the signed-in profile's OAuth usage endpoint; Codex uses the local `codex app-server` rate-limit RPC.

import AppKit
import SwiftUI

struct DashboardView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let disk = (try? DiskCapacity.current()) ?? .unavailable

            VStack(alignment: .leading, spacing: 16) {
                header(updatedAt: context.date)

                GlassEffectContainer(spacing: 12) {
                    VStack(spacing: 12) {
                        DiskCard(capacity: disk)
                        IntegrationCard(name: "Claude Code", icon: "sparkles", tint: .orange)
                        IntegrationCard(name: "Codex", icon: "chevron.left.forwardslash.chevron.right", tint: .green)
                    }
                }

                footer
            }
            .padding(18)
            .frame(width: 340)
        }
    }

    private func header(updatedAt: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("QuotaSpace")
                    .font(.title2.bold())
                Text(updatedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Last updated")
            }
            Spacer()
            Image(systemName: "circle.grid.2x2.fill")
                .font(.title2)
                .foregroundStyle(.tint)
        }
    }

    private var footer: some View {
        HStack {
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.glass)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
}

private struct DiskCard: View {
    let capacity: DiskCapacity

    var body: some View {
        HStack(spacing: 14) {
            Gauge(value: capacity.availableFraction) {
                Text("Disk")
            } currentValueLabel: {
                Text("\(capacity.availablePercent)")
                    .font(.caption.bold())
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.blue)
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("Macintosh HD")
                    .font(.headline)
                Text(capacity.total > 0
                     ? "\(capacity.availableText) free of \(capacity.totalText)"
                     : "Capacity unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

private struct IntegrationCard: View {
    let name: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .glassEffect(.clear, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.headline)
                Text("Integration coming soon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("—")
                .font(.title3)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}


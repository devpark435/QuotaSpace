import AppKit
import SwiftUI

@main
struct QuotaSpaceApp: App {
    var body: some Scene {
        MenuBarExtra {
            DashboardView()
        } label: {
            Label("QuotaSpace", systemImage: "gauge.with.dots.needle.33percent")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Integrations") {
                LabeledContent("Claude Code", value: "Coming soon")
                LabeledContent("Codex", value: "Coming soon")
            }
            Section {
                Text("QuotaSpace currently reads disk capacity locally. AI quota connections will be added when a reliable provider API is available.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 230)
    }
}


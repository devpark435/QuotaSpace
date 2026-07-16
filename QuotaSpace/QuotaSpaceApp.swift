import AppKit
import SwiftUI

@main
struct QuotaSpaceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("QuotaSpace", id: "main") {
            AppRootView()
                .environmentObject(MonitorStore.shared)
        }
        .defaultSize(width: 760, height: 560)

        Settings {
            DisplaySettingsView()
                .environmentObject(MonitorStore.shared)
                .frame(width: 560, height: 420)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        StatusBarController.shared.start()
        UsageRefreshCoordinator.shared.start()
        Task { await MonitorStore.shared.refresh() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        UsageRefreshCoordinator.shared.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

struct AppRootView: View {
    @AppStorage("completedOnboarding") private var completedOnboarding = false

    var body: some View {
        if completedOnboarding {
            DashboardView()
        } else {
            OnboardingView(completedOnboarding: $completedOnboarding)
        }
    }
}

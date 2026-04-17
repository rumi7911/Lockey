import AppKit
import LockeyKit
import SwiftUI

@main
struct LockeyApp: App {
    @NSApplicationDelegateAdaptor(LockeyAppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Lockey", systemImage: menuBarSymbolName) {
            MenuBarContentView(controller: appDelegate.controller)
                .frame(width: 280)
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarSymbolName: String {
        switch appDelegate.controller.state {
        case .active:
            return "keyboard.badge.ellipsis"
        case .permissionNeeded:
            return "exclamationmark.triangle"
        case .error:
            return "keyboard.chevron.compact.down"
        case .idle:
            return "keyboard"
        }
    }
}

@MainActor
final class LockeyAppDelegate: NSObject, NSApplicationDelegate {
    let controller: CleaningModeController

    override init() {
        let permissionCoordinator = AccessibilityPermissionCoordinator()
        let keyboardService = KeyboardInterceptionService()
        self.controller = CleaningModeController(
            permissionCoordinator: permissionCoordinator,
            keyboardService: keyboardService
        )
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.cancelCleaningMode()
    }
}

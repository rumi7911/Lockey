import ApplicationServices
import AppKit

public struct AccessibilityPermissionCoordinator: PermissionCoordinating {
    public init() {}

    public func currentStatus() -> PermissionStatus {
        AXIsProcessTrusted() ? .granted : .accessibilityDenied
    }

    public func openSystemSettingsGuidance() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

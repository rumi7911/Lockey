import AppKit
import LockeyKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var controller: CleaningModeController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lockey")
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            statusCard

            controls

            Divider()

            Button("Quit Lockey") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: String {
        switch controller.state {
        case .idle:
            return "Lock your keyboard before cleaning."
        case .permissionNeeded:
            return "Allow Accessibility access to lock keys."
        case .active:
            return "Keyboard is locked. Unlock anytime from here."
        case let .error(error):
            return error.message
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(statusTitle, systemImage: statusSymbolName)
                .font(.headline)
            Text(statusDetail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var statusTitle: String {
        switch controller.state {
        case .idle:
            return "Unlocked"
        case .permissionNeeded:
            return "Permission Required"
        case .active:
            return "Locked"
        case .error:
            return "Could Not Lock"
        }
    }

    private var statusDetail: String {
        switch controller.state {
        case .idle:
            return "Click to lock your keyboard."
        case let .permissionNeeded(status):
            switch status {
            case .granted:
                return "Access granted. Retry locking."
            case .accessibilityDenied:
                return "Enable Lockey in System Settings > Privacy & Security > Accessibility."
            }
        case .active:
            return "Typing is blocked until you unlock."
        case let .error(error):
            return error.message
        }
    }

    private var statusSymbolName: String {
        switch controller.state {
        case .idle:
            return "keyboard"
        case .permissionNeeded:
            return "hand.raised"
        case .active:
            return "lock.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch controller.state {
        case .idle:
            Button("Lock Keyboard") {
                controller.startCleaningMode()
            }
            .buttonStyle(.borderedProminent)
        case .permissionNeeded:
            VStack(alignment: .leading, spacing: 8) {
                Button("Open Accessibility Settings") {
                    controller.openSystemSettingsGuidance()
                }
                .buttonStyle(.borderedProminent)

                Button("Retry Lock") {
                    controller.handlePermissionResult()
                }
                .buttonStyle(.bordered)
            }
        case .active:
            Button("Unlock Keyboard") {
                controller.requestUnlock()
            }
            .buttonStyle(.borderedProminent)
        case .error:
            VStack(alignment: .leading, spacing: 8) {
                Button("Retry Lock") {
                    controller.startCleaningMode()
                }
                .buttonStyle(.borderedProminent)

                Button("Open Accessibility Settings") {
                    controller.openSystemSettingsGuidance()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private extension CleaningModeError {
    var message: String {
        switch self {
        case let .interceptionFailed(error):
            switch error {
            case .tapCreationFailed:
                return "macOS refused to start keyboard interception. Check permissions and close any conflicting input-monitoring tools."
            }
        }
    }
}

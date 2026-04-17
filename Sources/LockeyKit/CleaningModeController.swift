import Foundation
import Combine

@MainActor
public final class CleaningModeController: ObservableObject {
    @Published public private(set) var state: CleaningModeState = .idle
    public var statePublisher: Published<CleaningModeState>.Publisher { $state }

    private let permissionCoordinator: PermissionCoordinating
    private let keyboardService: KeyboardInterceptionServing

    public init(
        permissionCoordinator: PermissionCoordinating,
        keyboardService: KeyboardInterceptionServing
    ) {
        self.permissionCoordinator = permissionCoordinator
        self.keyboardService = keyboardService
    }

    public func startCleaningMode() {
        let permissionStatus = permissionCoordinator.currentStatus()
        guard permissionStatus == .granted else {
            state = .permissionNeeded(permissionStatus)
            return
        }

        do {
            try keyboardService.start()
            state = .active
        } catch let error as KeyboardInterceptionError {
            state = .error(.interceptionFailed(error))
        } catch {
            state = .error(.interceptionFailed(.tapCreationFailed))
        }
    }

    public func requestUnlock() {
        guard state == .active else { return }
        cancelCleaningMode()
    }

    public func cancelCleaningMode() {
        keyboardService.stop()
        state = .idle
    }

    public func handlePermissionResult() {
        let permissionStatus = permissionCoordinator.currentStatus()
        if permissionStatus == .granted {
            startCleaningMode()
        } else {
            state = .permissionNeeded(permissionStatus)
        }
    }

    public func openSystemSettingsGuidance() {
        permissionCoordinator.openSystemSettingsGuidance()
    }
}

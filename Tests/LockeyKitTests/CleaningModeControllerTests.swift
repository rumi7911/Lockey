import XCTest
@testable import LockeyKit

@MainActor
final class CleaningModeControllerTests: XCTestCase {
    func testStartsCleaningModeWhenPermissionIsGrantedAndInterceptionSucceeds() async {
        let permissions = StubPermissionCoordinator(status: .granted)
        let keyboard = StubKeyboardInterceptionService()
        let controller = CleaningModeController(
            permissionCoordinator: permissions,
            keyboardService: keyboard
        )

        controller.startCleaningMode()

        XCTAssertEqual(controller.state, .active)
        XCTAssertEqual(keyboard.startCalls, 1)
    }

    func testMovesToPermissionNeededWhenPermissionsAreMissing() async {
        let permissions = StubPermissionCoordinator(status: .accessibilityDenied)
        let keyboard = StubKeyboardInterceptionService()
        let controller = CleaningModeController(
            permissionCoordinator: permissions,
            keyboardService: keyboard
        )

        controller.startCleaningMode()

        XCTAssertEqual(controller.state, .permissionNeeded(.accessibilityDenied))
        XCTAssertEqual(keyboard.startCalls, 0)
    }

    func testUnlockRequestImmediatelyReturnsToIdle() async {
        let permissions = StubPermissionCoordinator(status: .granted)
        let keyboard = StubKeyboardInterceptionService()
        let controller = CleaningModeController(
            permissionCoordinator: permissions,
            keyboardService: keyboard
        )

        controller.startCleaningMode()
        controller.requestUnlock()

        XCTAssertEqual(controller.state, .idle)
        XCTAssertEqual(keyboard.stopCalls, 1)
    }

    func testMovesToErrorStateWhenInterceptionFailsAfterActivationIsRequested() async {
        let permissions = StubPermissionCoordinator(status: .granted)
        let keyboard = StubKeyboardInterceptionService(startError: .tapCreationFailed)
        let controller = CleaningModeController(
            permissionCoordinator: permissions,
            keyboardService: keyboard
        )

        controller.startCleaningMode()

        XCTAssertEqual(controller.state, .error(.interceptionFailed(.tapCreationFailed)))
        XCTAssertEqual(keyboard.stopCalls, 0)
    }

    func testHandlesPermissionResultByRetryingActivation() async {
        let permissions = StubPermissionCoordinator(status: .accessibilityDenied)
        let keyboard = StubKeyboardInterceptionService()
        let controller = CleaningModeController(
            permissionCoordinator: permissions,
            keyboardService: keyboard
        )

        controller.startCleaningMode()
        permissions.status = .granted

        controller.handlePermissionResult()

        XCTAssertEqual(controller.state, .active)
        XCTAssertEqual(keyboard.startCalls, 1)
    }
}

private final class StubPermissionCoordinator: PermissionCoordinating {
    var status: PermissionStatus

    init(status: PermissionStatus) {
        self.status = status
    }

    func currentStatus() -> PermissionStatus {
        status
    }

    func openSystemSettingsGuidance() {}
}

private final class StubKeyboardInterceptionService: KeyboardInterceptionServing {
    let startError: KeyboardInterceptionError?
    private(set) var startCalls = 0
    private(set) var stopCalls = 0
    private(set) var isRunning = false

    init(startError: KeyboardInterceptionError? = nil) {
        self.startError = startError
    }

    func start() throws {
        startCalls += 1
        if let startError {
            throw startError
        }
        isRunning = true
    }

    func stop() {
        stopCalls += 1
        isRunning = false
    }
}

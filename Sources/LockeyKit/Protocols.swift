public protocol PermissionCoordinating {
    func currentStatus() -> PermissionStatus
    func openSystemSettingsGuidance()
}

public protocol KeyboardInterceptionServing: AnyObject {
    var isRunning: Bool { get }
    func start() throws
    func stop()
}

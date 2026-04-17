public enum CleaningModeState: Equatable {
    case idle
    case permissionNeeded(PermissionStatus)
    case active
    case error(CleaningModeError)
}

public enum PermissionStatus: Equatable {
    case granted
    case accessibilityDenied
}

public enum CleaningModeError: Equatable, Error {
    case interceptionFailed(KeyboardInterceptionError)
}

public enum KeyboardInterceptionError: Equatable, Error {
    case tapCreationFailed
}

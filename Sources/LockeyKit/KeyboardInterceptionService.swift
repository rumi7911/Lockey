import ApplicationServices
import Foundation

public final class KeyboardInterceptionService: KeyboardInterceptionServing {
    static let systemDefinedEventTypeRawValue: UInt32 = 14

    public private(set) var isRunning = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public init() {}

    public func start() throws {
        guard !isRunning else { return }

        let mask = interceptionEventMask()

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let service = Unmanaged<KeyboardInterceptionService>.fromOpaque(userInfo).takeUnretainedValue()
            return service.handle(eventType: type, event: event)
        }

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            throw KeyboardInterceptionError.tapCreationFailed
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        isRunning = true
    }

    func interceptionEventMask() -> CGEventMask {
        let keyboardEvents: [CGEventType] = [.keyDown, .keyUp, .flagsChanged]
        let keyboardMask = keyboardEvents.reduce(CGEventMask(0)) { partialResult, eventType in
            partialResult | (CGEventMask(1) << eventType.rawValue)
        }
        let systemDefinedMask = CGEventMask(1) << Self.systemDefinedEventTypeRawValue
        return keyboardMask | systemDefinedMask
    }

    public func stop() {
        guard isRunning else { return }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        runLoopSource = nil
        eventTap = nil
        isRunning = false
    }

    private func handle(eventType: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch eventType {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        default:
            if shouldSuppress(eventType: eventType) {
                return nil
            }
            return Unmanaged.passUnretained(event)
        }
    }

    func shouldSuppress(eventType: CGEventType) -> Bool {
        switch eventType {
        case .keyDown, .keyUp, .flagsChanged:
            return true
        default:
            // Event type 14 is NX_SYSDEFINED (media/function row keys like volume/brightness).
            return eventType.rawValue == Self.systemDefinedEventTypeRawValue
        }
    }
}

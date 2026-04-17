import ApplicationServices
import XCTest
@testable import LockeyKit

final class KeyboardInterceptionServiceTests: XCTestCase {
    func testInterceptionMaskIncludesSystemDefinedEvents() {
        let service = KeyboardInterceptionService()
        let mask = service.interceptionEventMask()
        let systemDefinedBit = CGEventMask(1) << KeyboardInterceptionService.systemDefinedEventTypeRawValue

        XCTAssertNotEqual(mask & systemDefinedBit, 0)
    }

    func testShouldSuppressSystemDefinedMediaEvents() {
        let service = KeyboardInterceptionService()
        guard let systemDefinedType = CGEventType(rawValue: KeyboardInterceptionService.systemDefinedEventTypeRawValue) else {
            XCTFail("Expected CGEventType(rawValue: 14) for NX_SYSDEFINED media keys.")
            return
        }

        XCTAssertTrue(service.shouldSuppress(eventType: systemDefinedType))
    }

    func testShouldSuppressKeyboardEvents() {
        let service = KeyboardInterceptionService()

        XCTAssertTrue(service.shouldSuppress(eventType: .keyDown))
        XCTAssertTrue(service.shouldSuppress(eventType: .keyUp))
        XCTAssertTrue(service.shouldSuppress(eventType: .flagsChanged))
    }

    func testShouldNotSuppressMouseEvents() {
        let service = KeyboardInterceptionService()

        XCTAssertFalse(service.shouldSuppress(eventType: .leftMouseDown))
    }
}

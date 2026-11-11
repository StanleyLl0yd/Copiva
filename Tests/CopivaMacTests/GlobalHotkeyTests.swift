import AppKit
import Carbon
import XCTest
@testable import CopivaMac

@MainActor
final class GlobalHotkeyTests: XCTestCase {
    func testShortcutValidationAndDisplay() throws {
        XCTAssertTrue(GlobalShortcut.standard.isValid)
        XCTAssertEqual(GlobalShortcut.standard.displayLabel, "⌃⌥V")
        let encoded = try JSONEncoder().encode(GlobalShortcut.standard)
        XCTAssertEqual(try JSONDecoder().decode(GlobalShortcut.self, from: encoded), .standard)
        for shortcut in [
            GlobalShortcut(keyCode: 9, modifiers: 0, keyLabel: "V"),
            GlobalShortcut(keyCode: 9, modifiers: UInt32(shiftKey), keyLabel: "V"),
            GlobalShortcut(keyCode: 55, modifiers: UInt32(cmdKey), keyLabel: "Command"),
            GlobalShortcut(keyCode: 128, modifiers: UInt32(cmdKey), keyLabel: "Invalid"),
            GlobalShortcut(keyCode: 9, modifiers: UInt32(cmdKey), keyLabel: "\n")
        ] {
            XCTAssertFalse(shortcut.isValid)
        }
    }

    func testConflictKeepsPreviousRegistrationAndStopReleasesIt() throws {
        let modifiers = UInt32(cmdKey | controlKey | optionKey | shiftKey)
        let firstKey = GlobalShortcut(keyCode: 79, modifiers: modifiers, keyLabel: "F18")
        let occupiedKey = GlobalShortcut(keyCode: 80, modifiers: modifiers, keyLabel: "F19")
        let first = try GlobalHotkey(onPress: {})
        let second = try GlobalHotkey(onPress: {})
        defer { first.stop(); second.stop() }
        try first.register(firstKey)
        try first.register(firstKey)
        try second.register(occupiedKey)
        XCTAssertThrowsError(try first.register(occupiedKey))
        XCTAssertEqual(first.shortcut, firstKey)
        let contender = try GlobalHotkey(onPress: {})
        defer { contender.stop() }
        XCTAssertThrowsError(try contender.register(firstKey))
        first.stop()
        try contender.register(firstKey)
        XCTAssertEqual(contender.shortcut, firstKey)
    }

    func testInvalidCandidateDoesNotDropWorkingShortcut() throws {
        let key = GlobalShortcut(keyCode: 90, modifiers: UInt32(cmdKey | controlKey | optionKey),
                                 keyLabel: "F20")
        let hotkey = try GlobalHotkey(onPress: {})
        defer { hotkey.stop() }
        try hotkey.register(key)
        XCTAssertThrowsError(try hotkey.register(
            GlobalShortcut(keyCode: 9, modifiers: 0, keyLabel: "V"))) {
            XCTAssertEqual($0 as? HotkeyError, .invalidShortcut)
        }
        XCTAssertEqual(hotkey.shortcut, key)
    }
}

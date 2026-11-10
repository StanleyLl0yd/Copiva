import XCTest
@testable import CopivaCore

final class AppInfoTests: XCTestCase {
    func testAppIdentity() {
        XCTAssertEqual(AppInfo.displayName, "Copiva")
        XCTAssertEqual(AppInfo.minimumMacOSMajorVersion, 26)
    }

    func testPasteModesAreDistinctAndRoundTrip() throws {
        XCTAssertEqual(PasteMode.allCases.count, 2)
        for mode in PasteMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(PasteMode.self, from: data)
            XCTAssertEqual(decoded, mode)
        }
    }
}

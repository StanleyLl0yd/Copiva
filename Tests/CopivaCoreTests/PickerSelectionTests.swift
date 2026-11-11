import XCTest
@testable import CopivaCore

final class PickerSelectionTests: XCTestCase {
    func testRefreshKeepsStableIdentityAndDropsRemovedSelection() {
        var selection = PickerSelection()
        selection.update(ids: [3, 2, 1])
        XCTAssertEqual(selection.selectedID, 3)
        selection.select(2)
        selection.update(ids: [4, 3, 2, 1])
        XCTAssertEqual(selection.selectedID, 2)
        selection.update(ids: [4, 1])
        XCTAssertEqual(selection.selectedID, 4)
        selection.select(99)
        XCTAssertEqual(selection.selectedID, 4)
        selection.update(ids: [])
        XCTAssertNil(selection.selectedID)
    }

    func testNavigationClampsAtEdgesIncludingExtremeOffsets() {
        var selection = PickerSelection()
        selection.move(by: 1)
        XCTAssertNil(selection.selectedID)
        selection.update(ids: [3, 2, 1])
        selection.move(by: 1)
        XCTAssertEqual(selection.selectedID, 2)
        selection.move(by: Int.max)
        XCTAssertEqual(selection.selectedID, 1)
        selection.move(by: Int.min)
        XCTAssertEqual(selection.selectedID, 3)
    }
}

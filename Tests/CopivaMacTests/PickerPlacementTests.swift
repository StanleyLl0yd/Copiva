import AppKit
import XCTest
@testable import CopivaMac

final class PickerPlacementTests: XCTestCase {
    func testPointerFallbackStaysInsideEachScreenIncludingNegativeOrigins() {
        for screen in [CGRect(x: 0, y: 40, width: 1440, height: 850),
                       CGRect(x: -1920, y: -400, width: 1920, height: 1050),
                       CGRect(x: 0, y: 0, width: 320, height: 240)] {
            for pointer in [CGPoint(x: screen.minX, y: screen.minY),
                            CGPoint(x: screen.maxX, y: screen.maxY),
                            CGPoint(x: screen.midX, y: screen.midY)] {
                let frame = PickerPlacement.frame(size: CGSize(width: 440, height: 440),
                                                   pointer: pointer, visibleFrame: screen)
                XCTAssertTrue(screen.contains(frame))
            }
        }
    }
}

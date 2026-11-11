import Foundation
import XCTest
@testable import CopivaCore
@testable import CopivaMac

@MainActor
final class PasteCoordinatorTests: XCTestCase {
    private let clip = TextClip(id: 1, text: "synthetic paste text",
                                copiedAt: Date(timeIntervalSince1970: 1))

    func testPermissionIsRequestedOnlyByPasteAndFallsBackToCopy() async {
        let access = SyntheticPasteAccess()
        access.isTrusted = false
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        XCTAssertEqual(access.permissionRequests, 0)
        var copies = 0
        var dismissals = 0
        let result = await coordinator.paste(clip, dismiss: { dismissals += 1 }, copy: { _ in
            copies += 1
            return access.clipboardChangeCount
        })
        XCTAssertEqual(result, .copiedPermissionRequired)
        XCTAssertEqual(copies, 1)
        XCTAssertEqual(dismissals, 0)
        XCTAssertEqual(access.permissionRequests, 1)
        XCTAssertEqual(access.posts, 0)
    }

    func testUnverifiedDestinationOnlyCopiesWithoutPosting() async {
        let access = SyntheticPasteAccess()
        access.hasTarget = false
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        var copies = 0
        let result = await coordinator.paste(clip, dismiss: {}, copy: { _ in
            copies += 1
            return access.clipboardChangeCount
        })
        XCTAssertEqual(result, .copiedFocusChanged)
        XCTAssertEqual(copies, 1)
        XCTAssertEqual(access.posts, 0)
        XCTAssertEqual(access.permissionRequests, 0)
    }

    func testVerifiedTargetCopiesOnceAndRequestsPaste() async {
        let access = SyntheticPasteAccess()
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        var copies = 0
        var dismissals = 0
        let result = await coordinator.paste(clip, dismiss: { dismissals += 1 }, copy: { _ in
            copies += 1
            return access.clipboardChangeCount
        })
        XCTAssertEqual(result, .pasteRequested)
        XCTAssertEqual(copies, 1)
        XCTAssertEqual(dismissals, 1)
        XCTAssertEqual(access.posts, 1)
        XCTAssertEqual(access.permissionRequests, 0)
    }

    func testFocusChangeAfterDismissalNeverPostsToNewField() async {
        let access = SyntheticPasteAccess()
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        let result = await coordinator.paste(clip, dismiss: { access.targetIsFocused = false },
                                              copy: { _ in access.clipboardChangeCount })
        XCTAssertEqual(result, .copiedFocusChanged)
        XCTAssertEqual(access.posts, 0)
    }

    func testClipboardReplacementAfterCopyPreventsPasteAndIsNotRestored() async {
        let access = SyntheticPasteAccess()
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        let result = await coordinator.paste(clip, dismiss: {}, copy: { _ in
            access.clipboardChangeCount = 2
            return 1
        })
        XCTAssertEqual(result, .copiedUnavailable)
        XCTAssertEqual(access.clipboardChangeCount, 2)
        XCTAssertEqual(access.posts, 0)
    }

    func testCopyFailureNeverPosts() async {
        let access = SyntheticPasteAccess()
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        let result = await coordinator.paste(clip, dismiss: {}, copy: { _ in nil })
        XCTAssertEqual(result, .copyFailed)
        XCTAssertEqual(access.posts, 0)
    }

    func testCancellationInvalidatesPendingIntentWithoutWritingClipboard() async {
        let access = SyntheticPasteAccess()
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        var copies = 0
        let result = await coordinator.paste(clip, dismiss: { coordinator.cancel() }, copy: { _ in
            copies += 1
            return access.clipboardChangeCount
        })
        XCTAssertEqual(result, .cancelled)
        XCTAssertEqual(copies, 0)
        XCTAssertEqual(access.posts, 0)
    }

    func testHeldModifiersTimeOutToCopyWithoutPosting() async {
        let access = SyntheticPasteAccess()
        access.modifiersAreReleased = false
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        let result = await coordinator.paste(clip, dismiss: {},
                                              copy: { _ in access.clipboardChangeCount })
        XCTAssertEqual(result, .copiedUnavailable)
        XCTAssertEqual(access.posts, 0)
    }

    func testPermissionRevocationAfterDismissalPreventsPosting() async {
        let access = SyntheticPasteAccess()
        let coordinator = PasteCoordinator(access: access)
        coordinator.prepare()
        let result = await coordinator.paste(clip, dismiss: { access.isTrusted = false },
                                              copy: { _ in access.clipboardChangeCount })
        XCTAssertEqual(result, .copiedFocusChanged)
        XCTAssertEqual(access.posts, 0)
    }
}

@MainActor
private final class SyntheticPasteAccess: PasteAccess {
    var isTrusted = true
    var hasTarget = true
    var targetIsFocused = true
    var modifiersAreReleased = true
    var clipboardChangeCount = 1
    var permissionRequests = 0
    var posts = 0
    func requestPermission() { permissionRequests += 1 }
    func captureTarget() {}
    func postCommandV(expectedClipboardChangeCount: Int) -> Bool {
        guard clipboardChangeCount == expectedClipboardChangeCount else { return false }
        posts += 1
        return true
    }
}

import XCTest
@testable import CodeIsland

/// #327 — Qoder IDE 1.25.1 (2026-08-19) renamed the macOS bundle to
/// `Qoder IDE.app` and its executable from `Electron` to `Qoder`. Every path
/// CodeIsland matched the IDE by was spelled with the old name, so an updated
/// install stopped being recognised as Qoder at all.
final class QoderIDEBundleTests: XCTestCase {
    func testRecognisesTheRenamedBundle() {
        XCTAssertTrue(AppState.isQoderIDEBundlePath(
            "/Applications/Qoder IDE.app/Contents/MacOS/Qoder"))
        XCTAssertTrue(AppState.isQoderIDEBundlePath(
            "/Applications/Qoder IDE.app/Contents/Frameworks/Qoder Helper (Renderer).app/Contents/MacOS/Qoder Helper (Renderer)"))
    }

    /// The rename doesn't reach installs that haven't updated, so both names
    /// have to keep working — this is not a migration.
    func testStillRecognisesThePreRenameBundle() {
        XCTAssertTrue(AppState.isQoderIDEBundlePath(
            "/Applications/Qoder.app/Contents/MacOS/Electron"))
        XCTAssertTrue(AppState.isQoderIDEBundlePath(
            "/Applications/Qoder.app/Contents/Frameworks/Qoder Helper (GPU).app/Contents/MacOS/Qoder Helper (GPU)"))
    }

    /// QoderWork is a different product with its own source and its own card.
    /// Neither IDE prefix may swallow it.
    func testDoesNotMatchQoderWork() {
        XCTAssertFalse(AppState.isQoderIDEBundlePath(
            "/Applications/QoderWork.app/Contents/MacOS/QoderWork"))
    }

    func testDoesNotMatchTheStandaloneCLI() {
        XCTAssertFalse(AppState.isQoderIDEBundlePath(
            "/Users/someone/.qoder/bin/qodercli/qodercli-1.1.39"))
    }
}

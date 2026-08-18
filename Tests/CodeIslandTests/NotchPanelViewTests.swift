import XCTest
@testable import CodeIsland

final class NotchPanelViewTests: XCTestCase {
    func testEffectiveNotchWidthAppliesCollapsedWidthScaleOnNonNotchScreens() {
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 50, hasNotch: false),
            100,
            accuracy: 0.001
        )
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 150, hasNotch: false),
            300,
            accuracy: 0.001
        )
    }

    func testEffectiveNotchWidthNeverShrinksUnderPhysicalNotch() {
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 50, hasNotch: true),
            200,
            accuracy: 0.001
        )
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 100, hasNotch: true),
            200,
            accuracy: 0.001
        )
    }

    func testEffectiveNotchWidthWidensBeyondPhysicalNotch() {
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 150, hasNotch: true),
            300,
            accuracy: 0.001
        )
    }

    func testEffectiveNotchWidthClampsOutOfRangeScale() {
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: -5, hasNotch: false),
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 250, hasNotch: false),
            300,
            accuracy: 0.001
        )
    }

    func testEffectiveNotchWidthAllowsZeroScaleOnNonNotchScreens() {
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 0, hasNotch: false),
            0,
            accuracy: 0.001
        )
        // Physical notch stays floored at hardware width even at 0%.
        XCTAssertEqual(
            NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 0, hasNotch: true),
            200,
            accuracy: 0.001
        )
    }

    func testCompactToolNameKeepsShortNamesUnchanged() {
        XCTAssertEqual(ToolNameDisplay.compact("Bash"), "Bash")
        XCTAssertEqual(ToolNameDisplay.compact("  Read  "), "Read")
    }

    func testCompactToolNameTruncatesLongNamesWithoutLosingSuffix() {
        let compact = ToolNameDisplay.compact("mcp__very_long_server_name__fetch_document_page", maxCharacters: 24)

        XCTAssertLessThanOrEqual(compact.count, 24)
        XCTAssertTrue(compact.hasPrefix("mcp"))
        XCTAssertTrue(compact.hasSuffix("document_page"))
        XCTAssertTrue(compact.contains("..."))
    }

    func testShouldTriggerJumpFailureFeedbackWhenAllAttemptsFail() {
        XCTAssertTrue(shouldTriggerJumpFailureFeedback([false, false, false]))
    }

    func testShouldNotTriggerJumpFailureFeedbackWhenAnyAttemptSucceeds() {
        XCTAssertFalse(shouldTriggerJumpFailureFeedback([false, true, false]))
    }

    func testJumpFailureShakeSequenceUsesFastAlternatingOffsets() {
        XCTAssertEqual(JumpAnimationHelper.shakeSequence, [8, -8, 6, -6, 3, -3, 0])
    }

    func testEvaluateJumpValidationReturnsSuccessWhenCheckSucceeds() async {
        var callCount = 0
        let outcome = await evaluateJumpValidation(
            delays: [1, 1, 1],
            isCancelled: { false },
            sleep: { _ in },
            checkSucceeded: {
                callCount += 1
                return callCount == 2
            }
        )

        XCTAssertEqual(outcome, .success)
    }

    func testEvaluateJumpValidationReturnsFailedWhenAllChecksFail() async {
        let outcome = await evaluateJumpValidation(
            delays: [1, 1, 1],
            isCancelled: { false },
            sleep: { _ in },
            checkSucceeded: { false }
        )

        XCTAssertEqual(outcome, .failed)
    }

    func testEvaluateJumpValidationReturnsCancelledBeforeCheckRuns() async {
        var checksRan = 0
        let outcome = await evaluateJumpValidation(
            delays: [1, 1, 1],
            isCancelled: { true },
            sleep: { _ in },
            checkSucceeded: {
                checksRan += 1
                return false
            }
        )

        XCTAssertEqual(outcome, .cancelled)
        XCTAssertEqual(checksRan, 0)
    }

    func testClickJumpCollapseTimelineShowsClickRingWhenCursorReachesClickPoint() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.26)

        XCTAssertGreaterThan(timeline.expand, 0.95)
        XCTAssertTrue(timeline.showClickRing)
        XCTAssertEqual(timeline.cursorX, 0, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 0, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineMovesCursorToClickPointFaster() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.08)

        XCTAssertEqual(timeline.cursorX, 0, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 0, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineMovesCursorFullyOffscreenBeforeExpandStarts() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.80)

        XCTAssertEqual(timeline.cursorX, 34, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 28, accuracy: 0.001)
        XCTAssertLessThanOrEqual(timeline.expand, 0.001)
    }

    func testClickJumpCollapseTimelineStartsExpandAfterCursorIsAlreadyOffscreen() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.85)

        XCTAssertGreaterThan(timeline.expand, 0.3)
        XCTAssertEqual(timeline.cursorX, 34, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 28, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineUsesMouseLeaveLikeCollapseSpeed() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.38)

        XCTAssertGreaterThan(timeline.expand, 0.5)
        XCTAssertLessThan(timeline.expand, 0.7)
    }

    func testClickJumpCollapseTimelineUsesMouseLeaveLikeExpandSpeed() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.93)

        XCTAssertGreaterThanOrEqual(timeline.expand, 0.999)
    }

    func testClickJumpCollapseTimelineHoldsCollapsedStateForMiddleWindow() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.60)

        XCTAssertLessThanOrEqual(timeline.expand, 0.001)
        XCTAssertEqual(timeline.cursorX, 0, accuracy: 0.001)
        XCTAssertEqual(timeline.cursorY, 0, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineLoopSeamIsSmooth() {
        let start = clickJumpCollapsePreviewTimeline(progress: 0)
        let end = clickJumpCollapsePreviewTimeline(progress: 1)

        XCTAssertEqual(start.expand, end.expand, accuracy: 0.001)
        XCTAssertEqual(start.cursorX, end.cursorX, accuracy: 0.001)
        XCTAssertEqual(start.cursorY, end.cursorY, accuracy: 0.001)
    }

    func testClickJumpCollapseTimelineLowersClickPoint() {
        let timeline = clickJumpCollapsePreviewTimeline(progress: 0.26)
        XCTAssertEqual(timeline.clickPointY, 16.0, accuracy: 0.1)
    }

}

// MARK: - Hover phase state machine (PR #208)

final class NotchHoverInteractionTests: XCTestCase {
    func testQuickPassThroughReversesPrehoverWithoutExpanding() {
        var phase = NotchHoverInteraction.nextPhase(from: .collapsed, event: .mouseEntered)
        XCTAssertEqual(phase, .prehover)

        phase = NotchHoverInteraction.nextPhase(from: phase, event: .mouseExited)
        XCTAssertEqual(phase, .collapsed)

        // The stale expand timer firing after the mouse left must not expand.
        phase = NotchHoverInteraction.nextPhase(from: phase, event: .expandDelayElapsed)
        XCTAssertEqual(phase, .collapsed)
    }

    func testDwellExpandsThenCollapsesAfterLeaveDelay() {
        var phase = NotchHoverInteraction.nextPhase(from: .collapsed, event: .mouseEntered)
        phase = NotchHoverInteraction.nextPhase(from: phase, event: .expandDelayElapsed)
        XCTAssertEqual(phase, .expanded)

        // Leaving alone doesn't collapse an expanded panel — the delay does.
        phase = NotchHoverInteraction.nextPhase(from: phase, event: .mouseExited)
        XCTAssertEqual(phase, .expanded)

        phase = NotchHoverInteraction.nextPhase(from: phase, event: .collapseDelayElapsed)
        XCTAssertEqual(phase, .collapsed)
    }

    func testCollapseDelayWhileNotExpandedIsANoOp() {
        XCTAssertEqual(NotchHoverInteraction.nextPhase(from: .collapsed, event: .collapseDelayElapsed), .collapsed)
        XCTAssertEqual(NotchHoverInteraction.nextPhase(from: .prehover, event: .collapseDelayElapsed), .prehover)
    }

    func testHoverExpandDelayClampsToSliderBounds() {
        XCTAssertEqual(NotchHoverInteraction.clampedExpandDelay(0.3), 0.3, accuracy: 0.0001)
        // Zero is a valid choice — it means expand without waiting.
        XCTAssertEqual(NotchHoverInteraction.clampedExpandDelay(0), 0, accuracy: 0.0001)
        // A stale or hand-edited value must not strand the panel.
        XCTAssertEqual(NotchHoverInteraction.clampedExpandDelay(-5), NotchHoverInteraction.minExpandDelay, accuracy: 0.0001)
        XCTAssertEqual(NotchHoverInteraction.clampedExpandDelay(30), NotchHoverInteraction.maxExpandDelay, accuracy: 0.0001)
    }

    func testHoverExpandDelayDefaultSitsInsideTheBounds() {
        XCTAssertGreaterThanOrEqual(SettingsDefaults.hoverExpandDelay, NotchHoverInteraction.minExpandDelay)
        XCTAssertLessThanOrEqual(SettingsDefaults.hoverExpandDelay, NotchHoverInteraction.maxExpandDelay)
        // Unchanged default keeps the behaviour users are used to.
        XCTAssertEqual(SettingsDefaults.hoverExpandDelay, NotchHoverInteraction.expandDelay, accuracy: 0.0001)
    }

    func testWidthScaleQuantizesAndClampsSliderValues() {
        XCTAssertEqual(NotchWidthScale.quantized(72.4), 72)
        XCTAssertEqual(NotchWidthScale.quantized(72.6), 73)
        XCTAssertEqual(NotchWidthScale.quantized(-10), NotchWidthScale.min)
        XCTAssertEqual(NotchWidthScale.quantized(999), NotchWidthScale.max)
    }

    func testWidthScaleSliderUsesOnePercentSteps() {
        XCTAssertEqual(NotchWidthScale.min, 0)
        XCTAssertEqual(NotchWidthScale.max, 150)
        XCTAssertEqual(NotchWidthScale.step, 1)
    }

    func testEffectiveNotchWidthClampsToSharedBounds() {
        // Physical notch is never scaled.
        XCTAssertEqual(NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 80, hasNotch: true), 200)
        // Simulated notch scales and clamps to NotchWidthScale bounds.
        XCTAssertEqual(NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 75, hasNotch: false), 150)
        XCTAssertEqual(NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 10, hasNotch: false), 20)
        XCTAssertEqual(NotchWidthMetrics.effectiveNotchWidth(notchW: 200, collapsedWidthScale: 900, hasNotch: false), 300)
    }

    func testFocusRampKeepsTheBottomBlockOpaque() {
        XCTAssertEqual(SessionMessageFocus.opacity(indexFromBottom: 0), 1.0)
        // Defensive: a negative index can only come from a layout mistake.
        XCTAssertEqual(SessionMessageFocus.opacity(indexFromBottom: -1), 1.0)
    }

    func testFocusRampFadesMonotonicallyUpwardToAReadableFloor() {
        let steps = (0...4).map { SessionMessageFocus.opacity(indexFromBottom: $0) }
        for (upper, lower) in zip(steps.dropFirst(), steps) {
            XCTAssertLessThanOrEqual(upper, lower, "opacity must not grow going up the card")
        }
        // Beyond the ramp everything shares one floor, never invisible.
        XCTAssertEqual(steps[3], steps[4])
        XCTAssertGreaterThan(steps[4], 0.25)
    }

    // MARK: - Session list contents

    private static let listBase = Date(timeIntervalSince1970: 1_700_000_000)

    private func visibleIds(
        _ ids: [String],
        active: Set<String>,
        activity: [String: Date],
        graceMinutes: Int = 3,
        now: Date? = nil,
        neverRan: Set<String> = []
    ) -> [String] {
        SessionListOrder.visibleIds(
            ids: ids,
            graceMinutes: graceMinutes,
            now: now ?? Self.listBase.addingTimeInterval(600),
            isActive: { active.contains($0) },
            hasRunATurn: { !neverRan.contains($0) },
            lastActivity: { activity[$0] ?? .distantPast }
        )
    }

    func testSessionListSkipsSessionsThatNeverRanAnything() {
        let now = Self.listBase.addingTimeInterval(600)
        let activity = ["just-opened": now, "finished": now.addingTimeInterval(-30)]

        // Opening a conversation in an IDE registers a session right away; it is
        // idle with a fresh timestamp, but there is nothing to show yet.
        XCTAssertEqual(
            visibleIds(["just-opened", "finished"], active: [], activity: activity,
                       now: now, neverRan: ["just-opened"]),
            ["finished"]
        )
        // "Never clean up" does not resurrect empty placeholders either.
        XCTAssertEqual(
            visibleIds(["just-opened"], active: [], activity: activity,
                       graceMinutes: 0, now: now, neverRan: ["just-opened"]),
            []
        )
        // Once it starts working it shows regardless of having no history yet.
        XCTAssertEqual(
            visibleIds(["just-opened"], active: ["just-opened"], activity: activity,
                       now: now, neverRan: ["just-opened"]),
            ["just-opened"]
        )
    }

    func testSessionListKeepsActiveSessionsOldestFirst() {
        let now = Self.listBase.addingTimeInterval(600)
        let activity = [
            "idle-stale": Self.listBase,                        // 10 min idle
            "busy-old": Self.listBase.addingTimeInterval(60),
            "busy-new": Self.listBase.addingTimeInterval(120),
        ]

        // Working sessions stay however long they have been running, and the
        // freshest lands last so it renders at the bottom.
        XCTAssertEqual(
            visibleIds(["idle-stale", "busy-new", "busy-old"],
                       active: ["busy-old", "busy-new"],
                       activity: activity,
                       now: now),
            ["busy-old", "busy-new"]
        )
    }

    func testSessionListKeepsFinishedSessionsUntilTheGraceExpires() {
        let now = Self.listBase.addingTimeInterval(600)
        let activity = [
            "just-finished": now.addingTimeInterval(-100),   // idle 1m40s
            "long-done": now.addingTimeInterval(-400),       // idle 6m40s
        ]

        // 3-minute grace: the fresh one lingers, the stale one is gone.
        XCTAssertEqual(
            visibleIds(["long-done", "just-finished"], active: [], activity: activity, now: now),
            ["just-finished"]
        )
        // 10-minute grace covers both.
        XCTAssertEqual(
            visibleIds(["long-done", "just-finished"], active: [], activity: activity,
                       graceMinutes: 10, now: now),
            ["long-done", "just-finished"]
        )
    }

    func testSessionListKeepsEverythingWhenGraceIsDisabled() {
        let now = Self.listBase.addingTimeInterval(600)
        let activity = ["ancient": Date(timeIntervalSince1970: 0), "recent": now]

        XCTAssertEqual(
            visibleIds(["recent", "ancient"], active: [], activity: activity,
                       graceMinutes: 0, now: now),
            ["ancient", "recent"]
        )
    }

    func testSessionListBreaksTimestampTiesByIdForStableOrder() {
        XCTAssertEqual(
            visibleIds(["c", "a", "b"],
                       active: ["a", "b", "c"],
                       activity: ["a": Self.listBase, "b": Self.listBase, "c": Self.listBase]),
            ["a", "b", "c"]
        )
    }
}

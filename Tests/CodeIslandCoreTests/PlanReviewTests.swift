//
//  PlanReviewTests.swift
//  CodeIslandCoreTests
//
//  Created by huangxiaofeng on 2026/10/14.
//

import XCTest
@testable import CodeIslandCore

/// Claude's ExitPlanMode request: which ones are a plan to review, and the
/// deny that sends a plan back with feedback.
final class PlanReviewTests: XCTestCase {
    func testOnlyExitPlanModeWithAPlanIsReviewed() {
        XCTAssertEqual(PlanReview.plan(toolName: "ExitPlanMode", toolInput: ["plan": "  ## Steps\n1. Edit\n "]),
                       "## Steps\n1. Edit")
        XCTAssertNil(PlanReview.plan(toolName: "ExitPlanMode", toolInput: ["plan": "  \n "]))
        XCTAssertNil(PlanReview.plan(toolName: "ExitPlanMode", toolInput: [:]))
        XCTAssertNil(PlanReview.plan(toolName: "ExitPlanMode", toolInput: nil))
        XCTAssertNil(PlanReview.plan(toolName: "Bash", toolInput: ["plan": "rm -rf"]))
        XCTAssertTrue(PlanReview.isPlanReview(toolName: "ExitPlanMode", toolInput: ["plan": "x"]))
        XCTAssertFalse(PlanReview.isPlanReview(toolName: "EnterPlanMode", toolInput: ["plan": "x"]))
    }

    func testSendingBackCarriesTheFeedbackAsTheDenyMessage() throws {
        let decision = try decision(in: PlanReview.denyResponse(feedback: "  Split step 2 \n"))
        XCTAssertEqual(decision["behavior"] as? String, "deny")
        XCTAssertEqual(decision["message"] as? String, "Split step 2")
    }

    func testAPlainDenyHasNoMessage() throws {
        for feedback in [nil, "", "   "] as [String?] {
            let decision = try decision(in: PlanReview.denyResponse(feedback: feedback))
            XCTAssertEqual(decision["behavior"] as? String, "deny")
            XCTAssertNil(decision["message"])
        }
    }

    private func decision(in data: Data) throws -> [String: Any] {
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let output = try XCTUnwrap(object["hookSpecificOutput"] as? [String: Any])
        XCTAssertEqual(output["hookEventName"] as? String, "PermissionRequest")
        return try XCTUnwrap(output["decision"] as? [String: Any])
    }
}

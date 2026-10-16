//
//  PlanReview.swift
//  CodeIslandCore
//
//  Created by huangxiaofeng on 2026/10/14.
//

import Foundation

/// Claude's plan mode ends with an `ExitPlanMode` permission request whose
/// `plan` input is the whole plan in Markdown. Reviewing it is reading that
/// plan, then either letting Claude start or sending it back with feedback.
public enum PlanReview {
    public static let toolName = "ExitPlanMode"

    /// The plan to review, or nil when the request carries none worth showing.
    public static func plan(toolName: String?, toolInput: [String: Any]?) -> String? {
        guard toolName == Self.toolName,
              let plan = toolInput?["plan"] as? String else { return nil }
        let trimmed = plan.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public static func isPlanReview(toolName: String?, toolInput: [String: Any]?) -> Bool {
        plan(toolName: toolName, toolInput: toolInput) != nil
    }

    /// A deny that keeps Claude in plan mode. With feedback, the message is
    /// what Claude reads as the reason, so it revises the plan along it.
    public static func denyResponse(feedback: String?) -> Data {
        var decision: [String: Any] = ["behavior": "deny"]
        if let feedback = feedback?.trimmingCharacters(in: .whitespacesAndNewlines), !feedback.isEmpty {
            decision["message"] = feedback
        }
        let object: [String: Any] = [
            "hookSpecificOutput": [
                "hookEventName": "PermissionRequest",
                "decision": decision,
            ] as [String: Any],
        ]
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data("{}".utf8)
    }
}

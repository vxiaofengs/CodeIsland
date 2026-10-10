//
//  SessionListFilter.swift
//  CodeIsland
//
//  Created by huangxiaofeng on 2026/10/10.
//

import Foundation

/// Who appears in the expanded session list. The order is upstream's
/// (`AppState.sessionListOrder()`: what waits on you, then what is working,
/// then by recent activity) — this only removes rows from it, preserving
/// whatever order it was handed.
///
/// Two kinds of noise go:
///   * a session idle longer than the grace period — its result has been read;
///   * a session that never ran a turn — opening a conversation in an IDE
///     registers one immediately, and those empty placeholders are what made
///     the list unreadable once a few projects had been touched.
enum SessionListFilter {
    /// `graceMinutes <= 0` keeps every session that has run a turn, however
    /// long ago; the "never ran anything" rule applies either way.
    static func visibleIds(
        ids: [String],
        graceMinutes: Int,
        now: Date = Date(),
        isActive: (String) -> Bool,
        hasRunATurn: (String) -> Bool,
        lastActivity: (String) -> Date
    ) -> [String] {
        let cutoff = graceMinutes > 0
            ? now.addingTimeInterval(-Double(graceMinutes) * 60)
            : Date.distantPast
        return ids.filter { id in
            if isActive(id) { return true }
            return hasRunATurn(id) && lastActivity(id) >= cutoff
        }
    }
}

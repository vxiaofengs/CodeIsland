//
//  HighRiskCommand.swift
//  CodeIslandCore
//
//  Created by huangxiaofeng on 2026/09/03.
//

import Foundation

/// The carve-out for session-wide "always allow".
///
/// Once a session is trusted for the rest of its life, CodeIsland answers its
/// approvals itself and the user stops seeing cards — which is the point, and
/// also the risk. These are the operations that keep asking anyway: the ones
/// whose damage is immediate and cannot be undone by re-running something.
///
/// Deliberately conservative in scope, not in matching: it is a keyword list,
/// so an obfuscated command (a variable holding "rm -rf", a base64 pipe) will
/// pass. Session-wide allow is a convenience for a session you are supervising,
/// never a sandbox.
public enum HighRiskCommand {
    /// Only Bash carries a command string worth screening; the other tools edit
    /// files inside the project the agent was already trusted with.
    public static func isHighRisk(toolName: String?, toolInput: [String: Any]?) -> Bool {
        guard let toolName, toolName == "Bash" || toolName == "bash" else { return false }
        guard let command = toolInput?["command"] as? String else { return false }
        return isHighRisk(command: command)
    }

    public static func isHighRisk(command: String) -> Bool {
        let normalized = command.lowercased()

        // Elevation: whatever follows runs outside the user's own blast radius.
        if containsWord(normalized, "sudo") || containsWord(normalized, "doas") { return true }

        // Recursive force delete, in any flag order (`rm -rf`, `rm -fr`, `rm -r -f`).
        if containsWord(normalized, "rm"), hasFlag(normalized, "r"), hasFlag(normalized, "f") { return true }

        // Whole-disk and filesystem writes.
        for token in ["mkfs", "diskutil erase", "newfs_", "fdisk"] where normalized.contains(token) {
            return true
        }
        if containsWord(normalized, "dd"), normalized.contains("of=") { return true }
        if normalized.contains("> /dev/disk") || normalized.contains("of=/dev/") { return true }

        // Git operations that discard work or rewrite what others have pulled.
        if normalized.contains("git push") && (hasFlag(normalized, "f") || normalized.contains("--force")) {
            return true
        }
        if normalized.contains("git reset") && normalized.contains("--hard") { return true }
        if normalized.contains("git clean"), hasFlag(normalized, "f") { return true }

        // Piping a download straight into a shell.
        if normalized.contains("curl") || normalized.contains("wget") {
            for shell in ["| sh", "|sh", "| bash", "|bash", "| zsh", "|zsh"] where normalized.contains(shell) {
                return true
            }
        }

        // Permission changes on system locations, or the blanket 777.
        if containsWord(normalized, "chmod") || containsWord(normalized, "chown") {
            if normalized.contains("777") { return true }
            for path in [" /system", " /usr", " /etc", " /library", " /bin", " /var"]
            where normalized.contains(path) {
                return true
            }
        }

        // Fork bomb.
        if normalized.replacingOccurrences(of: " ", with: "").contains(":(){") { return true }

        return false
    }

    /// Whole-word match, so `format` never reads as `mkfs` and a path segment
    /// named "sudoku" never reads as `sudo`.
    private static func containsWord(_ text: String, _ word: String) -> Bool {
        text.split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "_" })
            .contains { $0 == Substring(word) }
    }

    /// Whether a short flag is set, in any grouping: `-rf`, `-fr`, `-r -f`.
    private static func hasFlag(_ text: String, _ flag: Character) -> Bool {
        for token in text.split(separator: " ") where token.hasPrefix("-") && !token.hasPrefix("--") {
            if token.dropFirst().contains(flag) { return true }
        }
        return false
    }
}

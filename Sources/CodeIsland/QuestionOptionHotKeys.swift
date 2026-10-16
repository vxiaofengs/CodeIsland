//
//  QuestionOptionHotKeys.swift
//  CodeIsland
//
//  Created by huangxiaofeng on 2026/10/14.
//

import AppKit
import Carbon.HIToolbox

/// ⌘1…⌘9 pick a question card's options from any app.
///
/// Registered only while a question card is on screen: ⌘1…⌘9 switch tabs in
/// browsers, terminals and editors, and holding them for good would take that
/// from every other app. The card on screen owns the keys; a card that
/// replaces it takes them over, so the old card leaving afterwards must not
/// release the new card's keys.
@MainActor
final class QuestionOptionHotKeys {
    static let shared = QuestionOptionHotKeys()

    /// The most options the digits reach.
    static let maxOptions = 9

    /// ⌘ plus the digit key for option `index` (0-based), or nil past ⌘9.
    static func keyCode(forOptionAt index: Int) -> UInt16? {
        let digits = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5,
                      kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9]
        guard digits.indices.contains(index) else { return nil }
        return UInt16(digits[index])
    }

    /// The hint beside option `index` (0-based), or nil when it has no key.
    static func hint(forOptionAt index: Int) -> String? {
        keyCode(forOptionAt: index) == nil ? nil : "⌘\(index + 1)"
    }

    // "CISQ" — CodeISland Question; apart from the user's shortcuts ("CISL").
    private let manager = GlobalHotKeyManager(signature: "CISQ")
    private var owner: UUID?

    /// Hand ⌘1…⌘`count` to `owner`, replacing whatever card held them.
    func activate(owner: UUID, count: Int, onPick: @escaping (Int) -> Void) {
        manager.unregisterAll()
        self.owner = owner
        guard SettingsManager.shared.questionOptionShortcuts else { return }
        for index in 0..<min(count, Self.maxOptions) {
            guard let keyCode = Self.keyCode(forOptionAt: index) else { break }
            manager.register(keyCode: keyCode, modifiers: .command) {
                onPick(index)
            }
        }
    }

    /// Release the keys, if `owner` still holds them.
    func deactivate(owner: UUID) {
        guard self.owner == owner else { return }
        manager.unregisterAll()
        self.owner = nil
    }
}

//
//  QuestionOptionHotKeysTests.swift
//  CodeIslandTests
//
//  Created by huangxiaofeng on 2026/10/14.
//

import Carbon.HIToolbox
import XCTest
@testable import CodeIsland

/// ⌘1…⌘9 on a question card: which key each option gets, and its hint.
@MainActor
final class QuestionOptionHotKeysTests: XCTestCase {
    func testOptionsMapToTheDigitKeysInOrder() {
        XCTAssertEqual(QuestionOptionHotKeys.keyCode(forOptionAt: 0), UInt16(kVK_ANSI_1))
        XCTAssertEqual(QuestionOptionHotKeys.keyCode(forOptionAt: 4), UInt16(kVK_ANSI_5))
        // The ANSI digit keycodes are not in numeric order past 4.
        XCTAssertEqual(QuestionOptionHotKeys.keyCode(forOptionAt: 5), UInt16(kVK_ANSI_6))
        XCTAssertEqual(QuestionOptionHotKeys.keyCode(forOptionAt: 8), UInt16(kVK_ANSI_9))
    }

    func testOptionsPastTheNinthGetNoKey() {
        XCTAssertNil(QuestionOptionHotKeys.keyCode(forOptionAt: 9))
        XCTAssertNil(QuestionOptionHotKeys.keyCode(forOptionAt: -1))
        XCTAssertNil(QuestionOptionHotKeys.hint(forOptionAt: 9))
    }

    func testHintNamesTheKey() {
        XCTAssertEqual(QuestionOptionHotKeys.hint(forOptionAt: 0), "⌘1")
        XCTAssertEqual(QuestionOptionHotKeys.hint(forOptionAt: 8), "⌘9")
    }
}

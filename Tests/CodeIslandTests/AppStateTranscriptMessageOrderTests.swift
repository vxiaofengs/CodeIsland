//
//  AppStateTranscriptMessageOrderTests.swift
//  CodeIsland
//
//  Created by huangxiaofeng on 2026/08/12.
//

import XCTest
@testable import CodeIsland
import CodeIslandCore

@MainActor
final class AppStateTranscriptMessageOrderTests: XCTestCase {
    private let sessionId = "order-test"

    private func makeAppState() -> AppState {
        let appState = AppState()
        var session = SessionSnapshot()
        session.source = "claude"
        session.status = .processing
        appState.sessions[sessionId] = session
        return appState
    }

    /// A chunk holding the tail of one turn plus the head of the next must not
    /// park the new question above the previous answer.
    func testLateReplyLandsBeforeTheNewerPrompt() {
        let appState = makeAppState()

        appState.applyTranscriptDelta(ConversationTailDelta(
            sessionId: sessionId,
            lastUserPrompt: "next question",
            lastAssistantMessage: "answer to the previous question",
            promptIsNewer: true
        ))

        let messages = appState.sessions[sessionId]?.recentMessages ?? []
        XCTAssertEqual(messages.map(\.isUser), [false, true])
        XCTAssertEqual(messages.map(\.text), ["answer to the previous question", "next question"])
    }

    func testFullTurnInOneChunkKeepsPromptThenReply() {
        let appState = makeAppState()

        appState.applyTranscriptDelta(ConversationTailDelta(
            sessionId: sessionId,
            lastUserPrompt: "the question",
            lastAssistantMessage: "its answer",
            promptIsNewer: false
        ))

        let messages = appState.sessions[sessionId]?.recentMessages ?? []
        XCTAssertEqual(messages.map(\.isUser), [true, false])
        XCTAssertEqual(messages.map(\.text), ["the question", "its answer"])
    }

    func testLatestFieldsTrackTheNewestOfEachRoleRegardlessOfOrder() {
        let appState = makeAppState()

        appState.applyTranscriptDelta(ConversationTailDelta(
            sessionId: sessionId,
            lastUserPrompt: "next question",
            lastAssistantMessage: "previous answer",
            promptIsNewer: true
        ))

        XCTAssertEqual(appState.sessions[sessionId]?.lastUserPrompt, "next question")
        XCTAssertEqual(appState.sessions[sessionId]?.lastAssistantMessage, "previous answer")
    }
}

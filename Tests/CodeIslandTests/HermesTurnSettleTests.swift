import XCTest
@testable import CodeIsland
import CodeIslandCore

/// Hermes runs behind a long-lived daemon and has no per-turn terminal event:
/// `on_session_end` only fires on /reset, and the process never exits. Every
/// card therefore stayed "running" forever (#303).
final class HermesTurnSettleTests: XCTestCase {

    func testPostLLMCallNormalizesToItsOwnTurnEvent() {
        // NOT Stop: post_llm_call also fires mid-turn, before tool calls, so
        // treating it as a completion would pop a card on every model response.
        XCTAssertEqual(EventNormalizer.normalize("post_llm_call"), "AgentTurnSettled")
        XCTAssertEqual(EventNormalizer.normalize("pre_llm_call"), "UserPromptSubmit")
    }

    @MainActor
    func testPostLLMCallClearsToolChromeAndKeepsTheAssistantReply() throws {
        let appState = AppState()
        var session = SessionSnapshot()
        session.source = "hermes"
        session.status = .running
        session.currentTool = "Bash"
        session.toolDescription = "npm test"
        appState.sessions["hermes-1"] = session

        appState.handleEvent(try makePostLLMCall(sessionId: "hermes-1", response: "All tests pass."))

        let updated = try XCTUnwrap(appState.sessions["hermes-1"])
        XCTAssertNil(updated.currentTool, "the model spoke — no tool is in flight anymore")
        XCTAssertNil(updated.toolDescription)
        XCTAssertEqual(updated.status, .processing)
        XCTAssertEqual(updated.lastAssistantMessage, "All tests pass.")
    }

    @MainActor
    func testAssistantResponseIsReadFromHermesExtraEnvelope() throws {
        let appState = AppState()
        var session = SessionSnapshot()
        session.source = "hermes"
        session.status = .processing
        appState.sessions["hermes-extra"] = session

        appState.handleEvent(try makePostLLMCall(sessionId: "hermes-extra", response: "Done."))

        XCTAssertEqual(appState.sessions["hermes-extra"]?.lastAssistantMessage, "Done.")
    }

    func testHermesIsTreatedAsDaemonBackedAndOtherAgentsAreNot() {
        XCTAssertTrue(AppState.isDaemonBackedSource("hermes"))
        XCTAssertTrue(AppState.isDaemonBackedSource("hermes-agent"), "alias must resolve too")
        XCTAssertFalse(AppState.isDaemonBackedSource("claude"))
        XCTAssertFalse(AppState.isDaemonBackedSource(nil))
    }

    @MainActor
    func testInstallerRegistersThePerTurnHook() throws {
        let cli = try XCTUnwrap(ConfigInstaller.allCLIs.first { $0.source == "hermes" })
        XCTAssertTrue(
            cli.events.contains { $0.0 == "post_llm_call" },
            "without this hook a Hermes card can only ever be settled by a timeout"
        )
    }

    // MARK: - Helpers

    private func makePostLLMCall(sessionId: String, response: String) throws -> HookEvent {
        let payload: [String: Any] = [
            "hook_event_name": "post_llm_call",
            "session_id": sessionId,
            "_source": "hermes",
            "cwd": "/tmp/project",
            "extra": [
                "assistant_response": response,
                "model": "hermes-4",
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        return try XCTUnwrap(HookEvent(from: data))
    }
}

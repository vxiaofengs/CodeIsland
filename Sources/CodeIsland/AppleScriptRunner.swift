import Foundation
import os.log

private let log = Logger(subsystem: "com.codeisland", category: "Jump")

/// Runs the AppleScript behind click-to-jump (`TerminalActivator`) and the
/// tab-level Smart Suppress check (`TerminalVisibilityDetector`).
///
/// Always out of process, in `/usr/bin/osascript`. NSAppleScript is one of the
/// classes Apple's Thread Programming Guide ("Thread Safety Summary") says may
/// only be used from the main thread, yet both paths ran it on background
/// queues — a jump, its validation retries and a Smart Suppress probe could be
/// executing scripts on several threads at once. A child process has its own
/// main thread and shares nothing with ours.
///
/// Automation permission is unaffected: macOS attributes a child's Apple Events
/// to its responsible process, the app that spawned it, so the consent prompt
/// still names CodeIsland (with its NSAppleEventsUsageDescription) and the
/// grants users already gave keep applying. The Ghostty jump has worked this
/// way since it moved to osascript.
struct AppleScriptRunner: Sendable {
    /// Start a script and return at once; nobody waits for its result. `purpose`
    /// names the jump it belongs to, so a script that fails can be reported
    /// against something the reader recognises.
    let launch: @Sendable (_ source: String, _ purpose: String) -> Void
    /// Run a script to completion and return its result as text, or nil when
    /// it fails to compile, throws, or is still running after `timeout`.
    let evaluate: @Sendable (_ source: String, _ timeout: TimeInterval) -> String?
}

extension AppleScriptRunner {
    private static let osascriptPath = "/usr/bin/osascript"

    static let osascript = AppleScriptRunner(
        launch: { source, purpose in
            // Not waited on: osascript's own Apple Event timeouts bound it, as
            // they bounded NSAppleScript, and a first-use consent prompt can
            // stay up as long as the user needs. Foundation reaps the child.
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: osascriptPath)
            proc.arguments = ["-e", source]
            proc.standardOutput = FileHandle.nullDevice
            // Kept rather than sent to /dev/null: a refused script is the whole
            // reason a jump silently degrades to app-level activation, and with
            // the error discarded that is indistinguishable from an inaccurate
            // jump. osascript writes one short line here, so reading it after
            // exit cannot fill the pipe buffer.
            let errors = Pipe()
            proc.standardError = errors
            proc.terminationHandler = { finished in
                guard finished.terminationStatus != 0 else { return }
                let text = ((try? errors.fileHandleForReading.readToEnd())
                    .flatMap { String(data: $0, encoding: .utf8) } ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                report(failure: text, purpose: purpose)
            }
            try? proc.run()
        },
        evaluate: { source, timeout in
            // osascript prints the result as text (strings unquoted) and exits
            // non-zero on an error, which ProcessRunner turns into nil — the
            // same nil `NSAppleScript`'s stringValue gave for a failed script.
            guard let data = ProcessRunner.run(path: osascriptPath, args: ["-e", source], timeout: timeout) else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
    )

    /// Runs nothing and returns nothing. What a test process gets unless the
    /// test installs a fake, so no test can script the terminal of whoever
    /// runs the suite.
    static let inert = AppleScriptRunner(launch: { _, _ in }, evaluate: { _, _ in nil })

    /// Turn osascript's error text into something the reader can act on. The
    /// two that matter name a missing grant, and both are easy to misread as
    /// "the app is broken": the Accessibility entry in particular can look
    /// enabled in System Settings while a stale record keeps refusing.
    private static func report(failure text: String, purpose: String) {
        let hint: String
        if text.contains("-25211") || text.contains("-1728") {
            hint = " — no Accessibility grant: toggle CodeIsland off and on under "
                + "Privacy & Security → Accessibility (replacing the app bundle leaves a stale entry)"
        } else if text.contains("-1743") {
            hint = " — approve CodeIsland under Privacy & Security → Automation"
        } else {
            hint = ""
        }
        log.error("\(purpose, privacy: .public): script failed \(text, privacy: .public)\(hint, privacy: .public)")
    }

    /// The runner both paths use. Read from any thread; tests swap it.
    static var current: AppleScriptRunner {
        get {
            lock.lock()
            defer { lock.unlock() }
            return installed
        }
        set {
            lock.lock()
            installed = newValue
            lock.unlock()
        }
    }

    private static let lock = NSLock()
    private static var installed: AppleScriptRunner = RuntimeEnvironment.isRunningTests ? .inert : .osascript
}

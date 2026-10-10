//
//  TextWidth.swift
//  CodeIsland
//
//  Created by huangxiaofeng on 2026/10/10.
//

import AppKit

/// Measures a monospaced label, the way the panel sizes its columns and pills.
///
/// Two reasons it is not a plain `size(withAttributes:)` at each call site:
///
///   * `NSFont.monospacedSystemFont(ofSize:weight:)` is imported as
///     non-optional and returns nil anyway when the font server cannot answer
///     (restarting fontd, a damaged font cache, memory pressure). The nil goes
///     straight into the attributes dictionary, AppKit raises
///     NSInvalidArgumentException — "attempt to insert nil object from
///     objects[0]" — and nothing catches it, so the app aborts. A class
///     reference's Optional is just its pointer, so binding the result to an
///     optional detects the nil the type system said could not happen.
///   * These measurements run inside `body`, so every re-render of the panel
///     re-measures strings that have not changed.
enum TextWidth {
    /// Width of `text` in the monospaced system font, or an estimate when the
    /// font is unavailable. Callable from any thread: the panel measures from
    /// SwiftUI bodies on the main thread, the list's column maths from tests.
    static func monospaced(_ text: String, size: CGFloat, weight: NSFont.Weight) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let key = Key(text: text, size: size, weight: weight)
        lock.lock()
        let cached = cache[key]
        lock.unlock()
        if let cached { return cached }

        let width = measure(text, size: size, weight: weight)
        lock.lock()
        // Bounded: session titles and tool descriptions are unbounded in
        // principle, and a cache nobody prunes is a leak with extra steps.
        if cache.count >= maxEntries { cache.removeAll(keepingCapacity: true) }
        cache[key] = width
        lock.unlock()
        return width
    }

    private static func measure(_ text: String, size: CGFloat, weight: NSFont.Weight) -> CGFloat {
        let font: NSFont? = NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        guard let font else { return estimate(text, size: size) }
        return (text as NSString).size(withAttributes: [.font: font]).width
    }

    /// Fallback when there is no font to measure with. The system monospaced
    /// face advances at ~0.6 em; a label an estimate sizes is slightly off, far
    /// better than no label at all.
    private static func estimate(_ text: String, size: CGFloat) -> CGFloat {
        CGFloat(text.count) * size * 0.6
    }

    private struct Key: Hashable {
        let text: String
        let size: CGFloat
        let weight: NSFont.Weight
    }

    private static let maxEntries = 512
    private static let lock = NSLock()
    nonisolated(unsafe) private static var cache: [Key: CGFloat] = [:]
}

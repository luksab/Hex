//
//  PasteboardClient.swift
//  Hex
//
//  Created by Kit Langton on 1/24/25.
//

import Dependencies
import DependenciesMacros
import Sauce
import SwiftUI

@DependencyClient
struct PasteboardClient {
    var paste: @Sendable (String) async -> Void
}

extension PasteboardClient: DependencyKey {
    static var liveValue: Self {
        let live = PasteboardClientLive()
        return .init { text in
            await live.paste(text: text)
        }
    }
}

extension DependencyValues {
    var pasteboard: PasteboardClient {
        get { self[PasteboardClient.self] }
        set { self[PasteboardClient.self] = newValue }
    }
}

struct PasteboardClientLive {
    @MainActor
    func paste(text: String) async {
        let pasteboard = NSPasteboard.general
        let originalContents = pasteboard.string(forType: .string)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let source = CGEventSource(stateID: .combinedSessionState)

        let vKeyCode = Sauce.shared.keyCode(for: .v)
        let cmdKeyCode: CGKeyCode = 55 // Command key

        // Create cmd down event
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: cmdKeyCode, keyDown: true)

        // Create v down event
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        vDown?.flags = .maskCommand

        // Create v up event
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        vUp?.flags = .maskCommand

        // Create cmd up event
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: cmdKeyCode, keyDown: false)

        // Post the events
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        // Restore original pasteboard contents
        try? await Task.sleep(for: .seconds(0.1))
        pasteboard.clearContents()
        if let originalContents {
            pasteboard.setString(originalContents, forType: .string)
        }
    }
}

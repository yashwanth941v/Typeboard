//
//  AppSettings.swift
//  Typeboard
//

import Combine
import Foundation

enum TypingSpeed: String, CaseIterable, Identifiable {
    case instant, auto, fast, medium, slow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instant: return "Instant"
        case .auto: return "Auto"
        case .fast: return "Fast"
        case .medium: return "Medium"
        case .slow: return "Slow"
        }
    }

    var footerDescription: String {
        let controls = "Esc cancels mid-type; Cmd+Z right after undoes the whole block."
        switch self {
        case .instant:
            return "Pastes clipboard text with no visible animation. \(controls)"
        case .auto:
            return "Paces typing by content size — shorter text types letter-by-letter, longer text types in larger chunks. \(controls)"
        case .fast:
            return "Types quickly and ramps up toward the end so long text doesn't keep you waiting. \(controls)"
        case .medium:
            return "Types at a moderate, human-like pace and speeds up as it finishes. \(controls)"
        case .slow:
            return "Types slowly at first, then accelerates toward the end so you aren't waiting on the last stretch. \(controls)"
        }
    }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var typingSpeed: TypingSpeed {
        didSet {
            UserDefaults.standard.set(typingSpeed.rawValue, forKey: "typingSpeed")
        }
    }

    private init() {
        let storedSpeed = UserDefaults.standard.string(forKey: "typingSpeed") ?? ""

        if storedSpeed == "normal" {
            typingSpeed = .medium
        } else if let speed = TypingSpeed(rawValue: storedSpeed) {
            typingSpeed = speed
        } else if UserDefaults.standard.object(forKey: "instant") as? Bool == true
                    || (UserDefaults.standard.object(forKey: "instant") == nil
                        && !UserDefaults.standard.bool(forKey: "animateTyping")) {
            typingSpeed = .instant
        } else {
            typingSpeed = .auto
        }
    }
}

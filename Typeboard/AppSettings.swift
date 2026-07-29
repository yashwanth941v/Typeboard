//
//  AppSettings.swift
//  Typeboard
//

import Combine
import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var animateTyping: Bool {
        didSet {
            UserDefaults.standard.set(animateTyping, forKey: "animateTyping")
        }
    }

    private init() {
        animateTyping = UserDefaults.standard.bool(forKey: "animateTyping")
    }
}

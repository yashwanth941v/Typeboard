//
//  KeyboardTyper.swift
//  Typeboard
//
//  Created by Yashwanth V on 29/07/26.
//

import Foundation

final class KeyboardTyper {
    static let shared = KeyboardTyper()

    private init() {}

    func type(_ text: String) {
        print("Typing:")
        print(text)
    }
}

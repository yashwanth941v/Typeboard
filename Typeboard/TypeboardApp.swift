//
//  TypeboardApp.swift
//  Typeboard
//
//  Created by Yashwanth V on 29/07/26.
//

import SwiftUI

@main
struct TypeboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 160)
    }
}

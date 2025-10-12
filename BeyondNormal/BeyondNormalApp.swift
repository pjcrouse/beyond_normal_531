//
//  BeyondNormalApp.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/6/25.
//

import SwiftUI

@main
struct BeyondNormalApp: App {
    @StateObject private var assistanceLibrary = AssistanceLibrary.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(assistanceLibrary)
        }
    }
}

//
//  BeyondNormalApp.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/6/25.
//

import SwiftUI

@main
struct BeyondNormalApp: App {
    @StateObject private var purchases = PurchaseManager.shared
    @StateObject private var assistanceLibrary = AssistanceLibrary.shared
    @StateObject private var settings = ProgramSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchases)
                .task { purchases.start() }
                .environmentObject(assistanceLibrary)
                .environmentObject(settings)
                .tint(Color.accentColor)
        }
    }
}

//
//  BeyondNormalApp.swift
//  BeyondNormal
//
//  Created by Pat Crouse on 10/6/25.
//

import SwiftUI
import UserNotifications

@main
struct BeyondNormalApp: App {
    @StateObject private var purchases = PurchaseManager.shared
    @StateObject private var assistanceLibrary = AssistanceLibrary.shared
    @StateObject private var settings = ProgramSettings()
    
    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = LocalNotifDelegate.shared   // ⬅️ ensure delegate is set ASAP
        center.getNotificationSettings { s in
            if s.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
            }
        }
    }
    
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

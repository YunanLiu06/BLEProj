//
//  bleSensorApp.swift
//  bleSensor
//
//  Created by Louis Lew on 12/22/25.
//

import SwiftUI

@main
struct bleSensorApp: App {
    init() {
        requestNotificationPermission()
        logNotificationStatus()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            print("Permission granted:", granted)
        }
    }
    
    private func logNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification authorization status:",
                  settings.authorizationStatus.rawValue)
        }
    }
}

//
//  RequestPermissions.swift
//  macaccord
//
//  Created by đỗ quyên on 17/9/25.
//

import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            Log.general.error("Error requesting permission: \(error)")
        } else {
            Log.general.info("Permission granted: \(granted)")
        }
    }
}

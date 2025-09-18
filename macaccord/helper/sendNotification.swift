//
//  sendNotification.swift
//  macaccord
//
//  Created by đỗ quyên on 17/9/25.
//

import UserNotifications

func sendNotification(title: String, body: String, sound: UNNotificationSound = .default) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = sound
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    
    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            Log.general.error("Error adding notification: \(error)")
        }
    }
}

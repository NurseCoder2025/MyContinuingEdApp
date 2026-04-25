//
//  AppDelegate.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/16/26.
//

import CloudKit
import Foundation
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - DELEGATE METHODS
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }//: application(_)
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }//: usserNotificationCenter()
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult
        ) -> Void) {
        
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
         
        if notification?.notificationType == .database,
            let dbNotification = notification as? CKDatabaseNotification {
            
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    handleCloudKitNotification(dbNotification)
                }//: MAIN ACTOR
                completionHandler(.newData)
            }//: TASK
            
        } else {
            completionHandler(.noData)
        }//: IF (notificationType == .database, notification as CKDatabaseNotification)
    }//: application(_, didReceiveRemoteNotification, fetchCompletionHandler)
    
    // MARK: - HELPERS
    
    private func handleCloudKitNotification(
        _ notification: CKDatabaseNotification
    ) {
        let nc = NotificationCenter.default
        nc.post(name: .cloudDBChangeNotification, object: nil)
    }//: handleCloudKitNotification
    
    
}//: CLASS

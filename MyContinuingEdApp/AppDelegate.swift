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
         
        if notification?.notificationType == .query,
            let queryNotification = notification as? CKQueryNotification {
            
            Task {
                await handleCloudKitNotification(queryNotification)
                completionHandler(.newData)
            }//: TASK
            
        } else {
            completionHandler(.noData)
        }//: IF (notificationType == .query, notification as CKQueryNotification)
    }//: application(_, didReceiveRemoteNotification, fetchCompletionHandler)
    
    // MARK: - HELPERS
    
    private func handleCloudKitNotification(_ notification: CKQueryNotification) async {
        guard let recordID = notification.recordID else { return }
        
        switch notification.queryNotificationReason {
        case .recordCreated:
            NotificationCenter.default.post(
                name: .cloudKitRecordAdded,
                object: nil,
                userInfo: [String.userInfoNotificationKey : notification]
            )//: post
        case .recordUpdated:
            NotificationCenter.default.post(
                name: .cloudKitRecordChanged,
                object: nil,
                userInfo: [String.userInfoNotificationKey : notification]
            )//: post
        case .recordDeleted:
            NotificationCenter.default.post(
                name: .cloudKitRecordDeleted,
                object: nil,
                userInfo: [String.userInfoNotificationKey : notification]
            )//: post
        @unknown default:
            NotificationCenter.default.post(
                name: .cloudKitUknownRecChange,
                object: nil,
                userInfo: [String.userInfoNotificationKey : notification]
            )//: post
        }//: SWITCH
        
    }//: handleCloudKitNotification
    
    
}//: CLASS

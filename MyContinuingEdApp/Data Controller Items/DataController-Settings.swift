//
//  DataController-Settings.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 11/18/25.
//

// This file extending DataController contains computed properties which
// retrieve and set various app settings within the sharedSettings published
// property in the main DataController file.  This property automatically
// syncs with iCloud (if the user is signed in) due to it being a
// NSUbiquitiousKeyValueStore object.

import Foundation

// ** Important **
// If adding or removing any keys in the sharedSettings NSUbiquitousKeyValueStore
// then it is critical to update the settingsKeys property in the
// handleKeyValueStoreChanges method in order to ensure that any new keys will
// be updated in the future when iCloud pushes updated values for those new
// keys.
extension DataController {
    // MARK: - Setting Keys
    var primaryNotificationDays: Double {
        get {
            sharedSettings.double(forKey: "primaryNotificationDays")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "primaryNotificationDays")
        }
    } //: primaryNotificationDays
    
    var secondaryNotificationDays: Double {
        get {
            sharedSettings.double(forKey: "secondaryNotificationDays")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "secondaryNotificationDays")
        }
    }//: secondaryNotificationDays
    
    var showExpiringCesNotification: Bool {
        get {
            sharedSettings.bool(forKey: "showExpiringCesNotification")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showExpiringCesNotification")
        }
    }//: showExpiringCesNotification
    
    var showRenewalEndingNotification: Bool {
        get {
            sharedSettings.bool(forKey: "showRenewalEndingNotification")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showRenewalEndingNotification")
        }
    }//: showRenewalEndingNotification
    
    var showRenewalLateFeeNotification: Bool {
        get {
            sharedSettings.bool(forKey: "showRenewalLateFeeNotification")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showRenewalLateFeeNotification")
        }
    }//: showRenewalLateFeeNotification
    
    var showDAINotifications: Bool {
        get {
            sharedSettings.bool(forKey: "showDAINotifications")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showDAINotifications")
        }
    }//: showDAINotifications
    
    
    // MARK: - Methods
    /// This method is used to trigger the objectWillChange.send() method whenever iCloud pushes
    /// changes to any of the keys in the DataController's sharedSettings (NSUbiquitousKeyValueStore)
    /// property. This will ensure that the UI on each device is updated whenever a key is updated
    /// on a different one.
    /// - Parameter notification: Notification coming in from iCloud that is from the
    ///     NSUbiquitousKeyValueStore
    @objc func handleKeyValueStoreChanges(_ notification: Notification) {
        let settingsKeys: Set<String> = [
            "purchaseStatus",
            "primaryNotificationDays",
            "secondaryNotificationDays",
            "showExpiringCesNotification",
            "showRenewalEndingNotification",
            "showRenewalLateFeeNotification",
            "showDAINotifications"
        ]
        
        guard let userInfo = notification.userInfo, let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String], settingsKeys.contains(where: { changedKeys.contains($0) }) else {return}
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }//: handleKeyValueStoreChanges()
    
    
}//: DATACONTROLLER

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
    // MARK: FIRST RUN
    var showOnboardingScreen: Bool {
        get {
            sharedSettings.bool(forKey: "showOnboardingScreen")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showOnboardingScreen")
        }
    }//: showOnboardingScreen
    
    // MARK: Notification Timing
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
    
    /// Computed Settings property that gets and sets the value (Double) for how many minutes the user wishes
    /// to be notified about an upcoming live CE activity that they are interested in attending.  This is the first of two
    /// notifications that will be sent if the user permits it.
    var firstLiveEventAlert: Double {
        get {
            sharedSettings.double(forKey: "firstLiveEventAlert")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "firstLiveEventAlert")
        }
        
    }//: firstLiveEventAlert
    
    /// Computed Settings property that gets and sets the value (Double) for how many minutes the user wishes
    /// to be notified about an upcoming live CE activity that they are interested in attending.  This is the second of two
    /// notifications that will be sent if the user permits it.
    var secondLiveEventAlert: Double {
        get {
            sharedSettings.double(forKey: "secondLiveEventAlert")
        }
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "secondLiveEventAlert")
        }
    }//: secondLiveEventAlert
    
    // MARK: Notification ON/OFF Settings
    /// Computed Settings property that gets and sets the value (Bool) for whether the user wishes to recieve any
    /// notifications regarding live events, including CE activities, that have a specified starting time.
    ///
    /// Each individual CeActivity object has its own reminder property that allows the user to customize which activiies
    /// (with start times) they wish to be reminded about.  If, however, this property is set to false then no notifications
    /// will be scheduled for CeActivities with starting times.
    ///
    /// This setting can also be used to set reminders for other live events, such as interviews and tests that are part of the
    /// credential reinstatement process (see ReinstatementInfo object for relevant properties).
    var showAllLiveEventAlerts: Bool {
        get {
            sharedSettings.bool(forKey: "showAllLiveEventAlerts")
        }
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showAllLiveEventAlerts")
        }
    }//: showActivityStartNotifications
    
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
    

    var showReinstatementAlerts: Bool {
        get {
            sharedSettings.bool(forKey: "showCredentialReinstatementAlerts")
        }
        set {
            objectWillChange.send( )
            sharedSettings.set(newValue, forKey: "showCredentialReinstatementAlerts")
        }
    }//: showReinstatementAlerts
    
    // MARK: - Methods
    /// This method is used to trigger the objectWillChange.send() method whenever iCloud pushes
    /// changes to any of the keys in the DataController's sharedSettings (NSUbiquitousKeyValueStore)
    /// property. This will ensure that the UI on each device is updated whenever a key is updated
    /// on a different one.
    /// - Parameter notification: Notification coming in from iCloud that is from the
    ///     NSUbiquitousKeyValueStore
    @objc func handleKeyValueStoreChanges(_ notification: Notification) {
        let settingsKeys: Set<String> = [
            "showOnboardingScreen",
            "purchaseStatus",
            "primaryNotificationDays",
            "secondaryNotificationDays",
            "showExpiringCesNotification",
            "showRenewalEndingNotification",
            "showRenewalLateFeeNotification",
            "showDAINotifications",
            "showAllLiveEventAlerts",
            "showCredentialReinstatementAlerts",
            "firstLiveEventAlert",
            "secondLiveEventAlert",
        ]
        
        guard let userInfo = notification.userInfo, let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String], settingsKeys.contains(where: { changedKeys.contains($0) }) else {return}
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }//: handleKeyValueStoreChanges()
    
    
}//: DATACONTROLLER

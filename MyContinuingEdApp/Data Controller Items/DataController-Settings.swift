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
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls how far ahead (in days) the user gets a notification for anything that is scheduled.
    /// This is the 1st of 2 notifications created for events and alerts within the app.
    /// - Note: This is a Double, but the intended value range is between 30 - 180.  Initial value for this setting is
    /// set to 60 upon app's first launch.
    /// - Important: Key name is "primaryNotificationDays" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    var primaryNotificationDays: Double {
        get {
            sharedSettings.double(forKey: "primaryNotificationDays")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "primaryNotificationDays")
        }
    } //: primaryNotificationDays
    
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls how far ahead (in days) the user gets a notification for anything that is scheduled.
    /// This is for the 2nd of 2 notifications created for events and alerts within the app.
    /// - Note: This is a Double, but the intended value range is between 2 - 29.  Initial value for this setting is
    /// set to 14 upon app's first launch.
    /// - Important: Key name is "secondaryNotificationDays" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    var secondaryNotificationDays: Double {
        get {
            sharedSettings.double(forKey: "secondaryNotificationDays")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "secondaryNotificationDays")
        }
    }//: secondaryNotificationDays
    
    
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls how far ahead (in minutes) the user gets a notification for any live event.
    /// This is for the 1st of 2 notifications created for events and alerts within the app.
    /// - Note: This is a Double, but the intended value range is between 0 - 480.  Initial value for this setting is
    /// set to 120 upon app's first launch. If the user sets the value to 0 then the notification will NOT be created.
    /// - Important: Key name is "firstLiveEventAlert" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    var firstLiveEventAlert: Double {
        get {
            sharedSettings.double(forKey: "firstLiveEventAlert")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "firstLiveEventAlert")
        }
        
    }//: firstLiveEventAlert
    
    
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls how far ahead (in minutes) the user gets a notification for any live event.
    /// This is for the 2nd of 2 notifications created for events and alerts within the app.
    /// - Note: This is a Double, but the intended value range is between 0 - 120.  Initial value for this setting is
    /// set to 30 upon app's first launch. If the user sets the value to 0 then the notification will NOT be created.
    /// - Important: Key name is "secondLiveEventAlert" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
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
    
    /// Computed Settings property that gets and sets the value for whether the user wishes to recieve any
    /// notifications regarding live events, including CE activities, that have a specified starting time.
    ///
    /// Specifically, this setting is saved in the @Published property sharedSettings within DataController.
    /// - Note: This is a BOOL, with a default value set to true.
    /// - Important: Key name is "showAllLiveEVentAlerts" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
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
    
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls whether the app will create notifications for CE activities that are set to expire
    /// within a designated period of time.
    ///
    /// - Note: This is a BOOL, with a default value set to true upon initial app launch, that controls the
    /// creation of expiration notices globally, but the user can elect to be notified on an actiivty-by-activity basis.
    /// - Important: Key name is "showExpiringCesNotifications" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    ///
    /// Most types of CE activities are "live events", meaning that the learner must be present (in-person or virtually) in order
    /// to earn CE contact hours.  However, many live events are recorded and posted to a website so that additional
    /// people can earn CEs from the activity later on - months or even a year after the fact.  In other cases, CEs can be
    /// obtained from written articles that are specifically planned to award CE.  In both of these cases, the activity in
    /// question is usually given an expiration date after which CEs can no longer be earned due to how quickly knowledge
    /// changes (especially in fields like healthcare and law).
    var showExpiringCesNotifications: Bool {
        get {
            sharedSettings.bool(forKey: "showExpiringCesNotifications")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showExpiringCesNotifications")
        }
    }//: showExpiringCesNotification
    
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls whether the app creates notifications in advance of when a renewal period is ending,
    /// as well as for related dates such as the renewal application window opens for the next period.
    ///
    /// - Note: This is a BOOL with a default value of true upon initial app launch.
    /// - Important: Key name is "showRenewalEndingNotifications" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    var showRenewalEndingNotifications: Bool {
        get {
            sharedSettings.bool(forKey: "showRenewalEndingNotifications")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showRenewalEndingNotifications")
        }
    }//: showRenewalEndingNotification
    
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls whether notifications are created to alert users of when any late fee periods start
    /// during the renewal process for a given credential.
    ///
    /// - Note: This is a BOOL with a default value set to true upon initial app launch
    /// - Important: Key name is "showRenewalLateFeeNotifications" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    var showRenewalLateFeeNotifications: Bool {
        get {
            sharedSettings.bool(forKey: "showRenewalLateFeeNotifications")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showRenewalLateFeeNotifications")
        }
    }//: showRenewalLateFeeNotification
    
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls whether any notifications for current DisciplinaryActionItems are created.
    ///
    /// - Note: This is a BOOL with a default value set to true upon initial app launch.  Only users who are
    /// currently Pro subscribers (annual or monthly) will be impacted by this value as the ability to create and save
    /// DisciplinaryActionItems is restricted to the Pro subscription level.
    /// - Important: Key name is "showDAINotifications" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    ///
    /// The DisciplinaryActionItem is a CoreData entity that tracks any actions taken by a licensing board or credential
    /// governing body against a user's credential. Several different types of notifications are created for this object,
    /// including notifications regarding remedial CE deadlines, fine deadlines, community service deadlines, etc.  Setting
    /// this setting to false prevents any notifications from being created.
    var showDAINotifications: Bool {
        get {
            sharedSettings.bool(forKey: "showDAINotifications")
        }
        
        set {
            objectWillChange.send()
            sharedSettings.set(newValue, forKey: "showDAINotifications")
        }
    }//: showDAINotifications
    
    
    /// Computed getter & setter for the @Published property sharedSettings that retrieves and sets values for
    /// the setting that controls whether any notifications for ReinstatementInfo objects are created.
    ///
    /// - Note: This is a BOOL set to a default value of true upon initial app launch.  This setting will only be shown
    /// to, and impact, Pro subscription users as the object is only made available to them.
    /// - Important: Key name is "showCredentialReinstatementAlerts" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    var showReinstatementAlerts: Bool {
        get {
            sharedSettings.bool(forKey: "showCredentialReinstatementAlerts")
        }
        set {
            objectWillChange.send( )
            sharedSettings.set(newValue, forKey: "showCredentialReinstatementAlerts")
        }
    }//: showReinstatementAlerts
    
    // MARK: Badge Indicators
    // TODO: Add UI controls in Settings for these properties
    /// Computed getter & setter for the @Published property sharedSettings for a key
    /// that controls the numerical value shown in the badge in each tag row in SidebarView.
    ///
    /// - Note: This is a String set to a default value of "allItems" (which comes from the BadgeCountOption enum raw value) upon initial app launch. Will also get a string value of "allItems" if the key is nil.
    /// - Important: Key name is "tagBadgeCountOf" and is part of the NSUbiquitousKeyValueStore.  Any
    /// changes to the name of the key should also be made to the settingsKeys array in handleKeyValueStoreChanges.
    /// Otherwise, proper syncing of changes in this setting will not occur between devices.
    var tagBadgeCountOf: String {
        get {
            sharedSettings.string(forKey: "tagBadgeCountOf") ?? "allItems"
        }
        set {
            objectWillChange.send( )
            sharedSettings.set(newValue, forKey: "tagBadgeCountOf")
        }
    }//: tagBadgeIndicator
    
    
    // MARK: - Methods
    
    /// This method is used to trigger the objectWillChange.send() method whenever iCloud pushes
    /// changes to any of the keys in the DataController's sharedSettings (NSUbiquitousKeyValueStore)
    /// property. This will ensure that the UI on each device is updated whenever a key is updated
    /// on a different one.
    /// - Parameter notification: Notification coming in from iCloud that is from the
    ///     NSUbiquitousKeyValueStore
    /// - Important: If any of the key names are changed within the computed settings properties then that change
    /// must be reflected in the settingsKeys array within this method in order for changes to be properly synced
    /// between devices.
    @objc func handleKeyValueStoreChanges(_ notification: Notification) {
        let settingsKeys: Set<String> = [
            "showOnboardingScreen",
            "purchaseStatus",
            "primaryNotificationDays",
            "secondaryNotificationDays",
            "showExpiringCesNotifications",
            "showRenewalEndingNotifications",
            "showRenewalLateFeeNotifications",
            "showDAINotifications",
            "showAllLiveEventAlerts",
            "showCredentialReinstatementAlerts",
            "firstLiveEventAlert",
            "secondLiveEventAlert",
            "tagBadgeCountOf"
        ]
        
        guard let userInfo = notification.userInfo, let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String], settingsKeys.contains(where: { changedKeys.contains($0) }) else {return}
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }//: handleKeyValueStoreChanges()
    
    
}//: DATACONTROLLER

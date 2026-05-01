//
//  iCloudStatus.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import Foundation


struct CurrentSettingsState: Codable {
    var currentiCloudStatus: iCloudStatus = .initialStatus
    var userCloudBooleanPrefs: [UserCloudPrefKey : Bool] = [
        .certsInCloud: true,
        .audioInCloud: true,
        .autoDownloadCerts: true,
        .autoDownloadAudio: true,
        .autoTranscription: true
    ]
    
    // SmartSync settings
    var smartSyncWindowForCerts: Double = 6.0
    var smartSyncAllowanceUsed: Double = 0.0
    
    // CE-Related
    /// Property within CurrentSettingsState intended to keep track of the ending date of all renewal periods
    /// for every credential stored within the app.
    ///
    /// - Important: The dictionary key is a UUID value which needs to be the credentialID property, corresponding to the
    /// proper credential object. The value for each key entry is an array of Dates, which should only be the periodEnd value for each
    /// renewal period for that specific credential.
    var allRenewalPeriodEndDates: [UUID : [Date]] = [:]
    
    // In-App Purchases
    var appPurchaseStateString: String = ""
    var credentialSelectionNeeded: Bool = false
    
    // CKRecordZone related
    var cloudZonesCreated: Bool = false
    var lastTimeZonesVerified: Date? = nil
    
    // CKDatabase Subscription
    var cloudDbSubscriptionCreated: Bool = false
    
    // iCloud Server Tokens
    // Using the Data value type because iCloud server tokens use
    // NSCoding
    var databaseChangeToken: Data? = nil
    var certZoneChangeToken: Data? = nil
    var audioZoneChangeToken: Data? = nil
    
    // iCloud user ID (only in encoded form due to CKRecord.ID conforming
    // to NSCoding (and not Encodable or Decodable)
    var codedUserID: Data? = nil
    
    // For CE CACHE CORE Users ONLY
    let settingsCreatedOn: Date
    var userNeedsToAcknowledgeTransition: Bool = true
    var renewalWarningStartDate: Date? = nil
    var currentRenewalEndDate: Date? = nil
    
    // MARK: - INIT
    init() {
        settingsCreatedOn = Date()
    }//: INIT
    
}//: STRUCT

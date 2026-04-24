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
    
    var smartSyncWindowForCerts: Double = 6.0
    var appPurchaseStateString: String = ""
    
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
    
}//: STRUCT

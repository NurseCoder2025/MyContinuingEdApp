//
//  MediaBrain.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import CloudKit
import CoreData
import Foundation


final class CloudMediaBrain: ObservableObject {
    // MARK: - PROPERTIES
    
    let settings = AppSettingsCache.shared
    let fileSystem = FileManager.default
    let netManager = NetworkManager.shared
    
    let cloudDB: CKDatabase = CKContainer.default().privateCloudDatabase
    let certZone = CKRecordZone(zoneName: String.certificateZoneId)
    let audioZone = CKRecordZone(zoneName: String.audioReflectionZoneId)
    
    private(set) var zonesCreated: Bool = false
    @Published var userErrorMessage: String = ""
    @Published var criticalCloudAlertNotice: String = ""
    
    // MARK: - OBJECT SINGELTON
    static let shared = CloudMediaBrain()
    
    // MARK: - COMPUTED PROPERTIES
    
    var iCloudIsAccessible: Bool {
        return settings.iCloudState.iCloudIsAvailable
    }//: okToRunOnlineMethods
    
    var userIsAProUser: Bool {
        let purchased = settings.getCurrentPurchaseLevel()
        return purchased == .proSubscription || purchased == .proLifetime
    }//: userIsAProUser
    
    var userIsAPaidSupporter: Bool {
        let subLevel = settings.getCurrentPurchaseLevel()
        return subLevel == .proSubscription || subLevel == .basicUnlock || subLevel == .proLifetime
    }//: userIsASubscriber
    
    var deviceIsOnline: Bool {
        return NetworkManager.shared.isConnected
    }//: deviceIsOnline
    
    var userWantsCertsInCloud: Bool {
        settings.shouldStoreMediaInCloud(forMedia: .certificate)
    }//: userWantsCertsInCloud
    
    var userWantsAudioReflectionsInCloud: Bool {
        settings.shouldStoreMediaInCloud(forMedia: .audioReflection)
    }//: userWantsAudioReflectionsInCloud
    
    // MARK: - PRELIM CHECKS
    
    func getAnyPrelimCloudSyncRelatedIssues() -> Set<CloudPrelimCheckError> {
        var errorsToReturn: Set<CloudPrelimCheckError> = []
        
        // Check #1: Is the device currently online?
        let internetCheck = deviceIsOnline
        
        // Check #2: Is iCloud available and ready to use?
        let cloudCheck = settings.iCloudState.iCloudIsAvailable
        
        // Check #2: Can the user utilize iCloud for media files?
        let userEligibilityCheck = userIsAPaidSupporter
        
        // Check #3: Does the user prefer to store files on iCloud or locally?
        let currentCloudPrefs = settings.userCloudBooleanPrefs
        let userWantsCertsInCloud = currentCloudPrefs[.certsInCloud] ?? true
        let userWantsAudioInCloud = currentCloudPrefs[.audioInCloud] ?? true
        let userWantsCertsAutoDownloaded = currentCloudPrefs[.autoDownloadCerts] ?? true
        let userWantsAudioAutoDownloaded = currentCloudPrefs[.autoDownloadAudio] ?? true
        
        if !internetCheck {
            errorsToReturn.insert(CloudPrelimCheckError.deviceOffline)
        }//: IF (!internetCheck)
        
        if !cloudCheck {
            errorsToReturn.insert(CloudPrelimCheckError.iCloudAccessIssue)
        }//: IF (!cloudCheck)
        
        if !userEligibilityCheck {
            errorsToReturn.insert(CloudPrelimCheckError.userNeedsToUpgrade)
        }//: IF (!userEligibilityCheck)
        
        if !userWantsCertsInCloud {
            errorsToReturn.insert(CloudPrelimCheckError.certsLocalOnly)
        }//: IF (!userWantsCertsInCloud)
        
        if !userWantsAudioInCloud {
            errorsToReturn.insert(CloudPrelimCheckError.audioLocalOnly)
        }//: IF (!userWantsAudioInCloud)
        
        if !userWantsCertsAutoDownloaded {
            errorsToReturn.insert(CloudPrelimCheckError.certsManDownload)
        }//: IF (!userWantsCertsAutoDownloaded)
        
        if !userWantsAudioAutoDownloaded {
            errorsToReturn.insert(CloudPrelimCheckError.audioManDownload)
        }//: IF (!userWantsAudioAutoDownloaded)
        
        return errorsToReturn
    }//: getAnyPrelimCloudSyncRelatedIssues()
    
    
    // MARK: - PROPERTY METHODS
    
    func updateZonesCreated() {
        zonesCreated.toggle()
    }//: updateZonesCreated()
    
    
    // MARK: - INIT
    
    private init() {
        if !iCloudIsAccessible {
            userErrorMessage = settings.iCloudState.userMessage
        }//:IF
    }//: INIT
    
}//: CloudMediaBrain

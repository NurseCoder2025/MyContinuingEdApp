//
//  AppSettingsCache.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/14/26.
//

import CloudKit
import Foundation

/// Class intended to save whatever the current user's current iCloud status is to the local device so
/// other objects can check without having to go through DataController.
///
/// This object has an instance in DataController called cloudState and is used in the
/// various iCloud methods for writing the current iCloud status to the local device as well as updating it
/// should notifications come in that the iCloud identity has changed or something similar.
///
/// Create an instance of this class whenever an object needs to know if an iCloud related function can
/// be executed or not, and use the iCloudState computed property for getting the current value.
final class AppSettingsCache: @unchecked Sendable {
    // MARK: - PROPERTIES
    let iCloudStateURL: URL = URL.applicationSupportDirectory.appending(path: "AppSettingsCache.json", directoryHint: .notDirectory)
    
    private let queue = DispatchQueue(label: "com.CeCache.settingsCache", qos: .utility)
    private var _currentState: CurrentSettingsState = .init() {
        willSet {
            dispatchPrecondition(condition: .onQueue(queue))
        }
    }//: _currentState
    
    // class singleton
    static let shared = AppSettingsCache()
    
    // MARK: - GETTER/SETTER PROPERTIES
    
    // MARK: ICLOUD
    var iCloudState: iCloudStatus {
        get {
            queue.sync { _currentState.currentiCloudStatus }
        }
        set {
            queue.async { self._currentState.currentiCloudStatus = newValue}
        }
    }//: iCloudState
    var userICloudIdData: Data? {
        get {
            queue.sync { _currentState.codedUserID }
        }
        set {
            queue.async { self._currentState.codedUserID = newValue}
        }
    }//: userICloudIdData
    
    // MARK: USER PREFS
    var userCloudBooleanPrefs: [UserCloudPrefKey: Bool] {
        get {
            queue.sync { _currentState.userCloudBooleanPrefs }
        }
        set {
            queue.async { self._currentState.userCloudBooleanPrefs = newValue}
        }
    }//: userCloudPrefs
    var smartSyncCertWindow: Double {
        get {
            queue.sync {_currentState.smartSyncWindowForCerts}
        }
        set {
            queue.async { self._currentState.smartSyncWindowForCerts = newValue}
        }
    }//: smartSyncCertWindow
    
    // MARK: STORE KIT
    var appPurchaseLevel: String {
        get {
            queue.sync { _currentState.appPurchaseStateString }
        }
        set {
            queue.async { self._currentState.appPurchaseStateString = newValue }
        }
    }//: appPurchaseLevel
    
    // MARK: CLOUD KIT
    var zonesCreated: Bool {
        get {
            queue.sync { _currentState.cloudZonesCreated }
        }
        set {
            queue.async { self._currentState.cloudZonesCreated = newValue}
        }
    }//: zonesCreated
    var zoneVerificationDate: Date? {
        get {
            queue.sync { _currentState.lastTimeZonesVerified }
        }
        set {
            queue.async { self._currentState.lastTimeZonesVerified = newValue}
        }
    }//: zoneVerificationDate
    var appHasCloudDatabaseSubscriptionSetup: Bool {
        get {
            queue.sync { _currentState.cloudDbSubscriptionCreated }
        }
        set {
            queue.async { self._currentState.cloudDbSubscriptionCreated = newValue}
        }
    }//:appHasCloudDatabaseSubscriptionSetup
    
    // MARK: TOKENS
    var databaseToken: Data? {
        get {
            queue.sync { _currentState.databaseChangeToken }
        }
        set {
            queue.async { self._currentState.databaseChangeToken = newValue}
        }
    }//: databaseToken
    var certZoneToken: Data? {
        get {
            queue.sync { _currentState.certZoneChangeToken }
        }
        set {
            queue.async { self._currentState.certZoneChangeToken = newValue}
        }
    }//: certZoneToken
    var audioZoneToken: Data? {
        get {
            queue.sync { _currentState.audioZoneChangeToken }
        }
        set {
            queue.async { self._currentState.audioZoneChangeToken = newValue}
        }
    }//: audioZoneToken
    
    // MARK: - LIST SAVING/LOADING
    
    func encodeCurrentState() {
        queue.async {
            let encoder = JSONEncoder()
            do {
                let encodedState = try encoder.encode(self._currentState)
                _ = try encodedState.write(to: self.iCloudStateURL)
            } catch {
                NSLog(">>> ICloudStateManager error: encodeCurrentState()")
                NSLog(">>> Either the JSON encoder threw an error while trying to encode the currentState property or an error was thrown while trying to save it to disk.")
                NSLog(">>> Error: \(error.localizedDescription)")
            }//: DO-CATCH
        }//: queue(async)
    }//: encodeCurrentState()
    
    func decodeCurrentState() {
        queue.sync {
            let decoder = JSONDecoder()
            do {
                let fileToDecode = try Data(contentsOf: iCloudStateURL)
                let decodedFile = try decoder.decode(CurrentSettingsState.self, from: fileToDecode)
                _currentState = decodedFile
            } catch {
                NSLog(">>> ICloudStateManager error: decodeCurrentState()")
                NSLog(">>> Either the JSON decoder threw an error while trying to decode the saved iCloudState.json file or an error was thrown while trying to open the file on disk.")
                NSLog(">>> Error: \(error.localizedDescription)")
                _currentState.currentiCloudStatus = .unableToCheck
            }//: DO-CATCH
        }//: queue(sync)
    }//: decodeCurrentState()
    
    // MARK: - GENERAL METHODS
    
    func getCurrentPurchaseLevel() -> PurchaseStatus {
        let levelString = appPurchaseLevel
        if levelString == PurchaseStatus.free.id {
            return PurchaseStatus.free
        } else if levelString == PurchaseStatus.basicUnlock.id {
            return PurchaseStatus.basicUnlock
        } else if levelString == PurchaseStatus.proSubscription.id {
            return PurchaseStatus.proSubscription
        } else if levelString == PurchaseStatus.proLifetime.id {
            return PurchaseStatus.proLifetime
        } else {
            return PurchaseStatus.free
        }//: IF ELSE
    }//: getPurchaseLevel()
    
    // MARK: - PREF BOOLEAN VALUES
    
    func shouldAutoDownloadMedia(forType type: MediaClass) -> Bool {
        switch type {
        case .certificate:
           return userCloudBooleanPrefs[.autoDownloadCerts] ?? true
        case .audioReflection:
            return userCloudBooleanPrefs[.autoDownloadAudio] ?? true
        }//: SWITCH
    }//: shouldAutoDownlaodMedia(forType)
    
    func shouldStoreMediaInCloud(forMedia type: MediaClass) -> Bool {
        switch type {
        case .certificate:
            return userCloudBooleanPrefs[.certsInCloud] ?? true
        case .audioReflection:
            return userCloudBooleanPrefs[.audioInCloud] ?? true
        }//: SWITCH
    }//: shouldStoreMediaInCloud(forMedia)
    
    func shouldAutoTranscribeAudio() -> Bool {
        return userCloudBooleanPrefs[.autoTranscription] ?? true
    }//: shouldAutoTranscribeAudio()
    
    // MARK: - TOKEN METHODS
    
    func saveDatabaseToken(_ token: CKServerChangeToken) {
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: token,
                requiringSecureCoding: true
            )//: archivedData
            databaseToken = data
            encodeCurrentState()
        } catch {
            NSLog(">>> AppSettingsCache error: saveDatabaseToken")
            NSLog(">>> Failed to save the database token because: \(error.localizedDescription)")
        }//: DO-CATCH
    }//: saveDatabaseToken
    
    func loadDatabaseToken() -> CKServerChangeToken? {
        guard let savedToken = databaseToken else { return nil }
        
        do {
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClass: CKServerChangeToken.self,
                from: savedToken
            )//: unarchivedObject
        } catch {
            NSLog(">>> AppSettingsCache error: saveDatabaseToken")
            NSLog(">>> Failed to load the database token because: \(error.localizedDescription)")
            return nil
        }//: DO-CATCH
    }//: loadDatabaseToken()
    
    func saveZoneToken(
        _ token: CKServerChangeToken,
        to zoneID: CKRecordZone.ID
    ) {
        guard zoneID.zoneName == String.certificateZoneId || zoneID.zoneName == String.audioReflectionZoneId else { return } //: GUARD
        
        do {
            let encodedToken = try NSKeyedArchiver.archivedData(
                withRootObject: token,
                requiringSecureCoding: true
            )//: archivedData
            
            if zoneID.zoneName == String.certificateZoneId {
                certZoneToken = encodedToken
                encodeCurrentState()
            } else if zoneID.zoneName == String.audioReflectionZoneId {
                audioZoneToken = encodedToken
                encodeCurrentState()
            }//: IF ELSE
            
        } catch {
            NSLog(">>> AppSettingsCache error: saveDatabaseToken")
            NSLog(">>> Failed to save the \(zoneID.zoneName) token because: \(error.localizedDescription)")
        }//: DO-CATCH
        
    }//: saveZoneToken
    
    func loadZoneToken(forZone zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
        let zName = zoneID.zoneName
        guard zName == String.certificateZoneId || zName == String.audioReflectionZoneId else {
            return nil
        }//: GUARD
        var encodedToken: Data = Data()
        
        if zName == String.certificateZoneId,
           let savedCertToken = certZoneToken {
            encodedToken = savedCertToken
        } else if zName == String.audioReflectionZoneId,
                  let savedAudioToken = audioZoneToken {
            encodedToken = savedAudioToken
        }//: IF LET ELSE
        
        do {
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClass: CKServerChangeToken.self,
                from: encodedToken
            )//: unarchivedObject
        } catch {
            NSLog(">>> AppSettingsCache error: loadZoneToken")
            NSLog(">>> Failed to load the \(zName) token because: \(error.localizedDescription)")
            return nil
        }//: DO-CATCH
        
    }//: loadZoneToken
    
    func clearAllTokens() {
        queue.async {
            self.databaseToken = nil
            self.certZoneToken = nil
            self.audioZoneToken = nil
            self.encodeCurrentState()
        }//: async
    }//: clearAllTokens()
    
    // MARK: - INIT
    
    // Using a private init in order to force the use of the singleton object
    private init() {
        if let _ = (try? Data(contentsOf: iCloudStateURL)) {
            decodeCurrentState()
        }//: IF LET
    }//: INIT
    
}//: CLASS


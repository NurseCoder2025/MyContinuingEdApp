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
    
    var iCloudState: iCloudStatus {
        get {
            queue.sync { _currentState.currentiCloudStatus }
        }
        set {
            queue.async { self._currentState.currentiCloudStatus = newValue}
        }
    }//: iCloudState
    
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
    
    var appPurchaseLevel: String {
        get {
            queue.sync { _currentState.appPurchaseStateString }
        }
        set {
            queue.async { self._currentState.appPurchaseStateString = newValue }
        }
    }//: appPurchaseLevel
    
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
    
    var userICloudIdData: Data? {
        get {
            queue.sync { _currentState.codedUserID }
        }
        set {
            queue.async { self._currentState.codedUserID = newValue}
        }
    }//: userICloudIdData
    
    var appHasCloudDatabaseSubscriptionSetup: Bool {
        get {
            queue.sync { _currentState.cloudDbSubscriptionCreated }
        }
        set {
            queue.async { self._currentState.cloudDbSubscriptionCreated = newValue}
        }
    }//:appHasCloudDatabaseSubscriptionSetup
    
    // MARK: - METHODS
    
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
    
    
    // MARK: - INIT
    
    // Using a private init in order to force the use of the singleton object
    private init() {
        if let _ = (try? Data(contentsOf: iCloudStateURL)) {
            decodeCurrentState()
        }//: IF LET
    }//: INIT
    
}//: CLASS


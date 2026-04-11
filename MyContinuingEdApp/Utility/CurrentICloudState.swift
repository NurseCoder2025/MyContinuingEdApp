//
//  iCloudStatus.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import Foundation


struct CurrentICloudState: Codable {
    var currentStatus: iCloudStatus = .initialStatus
    
    var userCloudPreferences: [UserCloudPrefKey : Bool] = [
        .certsInCloud: true,
        .audioInCloud: true,
        .autoDownloadCerts: true,
        .autoDownloadAudio: true
    ]
}//: STRUCT


/// Class intended to save whatever the current user's current iCloud status is to the local device so
/// other objects can check without having to go through DataController.
///
/// This object has an instance in DataController called cloudState and is used in the
/// various iCloud methods for writing the current iCloud status to the local device as well as updating it
/// should notifications come in that the iCloud identity has changed or something similar.
///
/// Create an instance of this class whenever an object needs to know if an iCloud related function can
/// be executed or not, and use the iCloudState computed property for getting the current value.
final class ICloudStateManager: @unchecked Sendable {
    // MARK: - PROPERTIES
    let iCloudStateURL: URL = URL.applicationSupportDirectory.appending(path: "iCloudState.json", directoryHint: .notDirectory)
    
    private let queue = DispatchQueue(label: "com.CeCache.icloudstate", qos: .utility)
    private var _currentState: CurrentICloudState = .init()
    
    // MARK: - COMPUTED PROPERTIES
    
    var iCloudState: iCloudStatus {
        get {
            queue.sync { _currentState.currentStatus }
        }
        set {
            queue.async { self._currentState.currentStatus = newValue}
        }
    }//: iCloudState
    
    var userCloudPrefs: [UserCloudPrefKey: Bool] {
        get {
            queue.sync { _currentState.userCloudPreferences }
        }
        set {
            queue.async { self._currentState.userCloudPreferences = newValue}
        }
    }//: userCloudPrefs
    
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
                self._currentState.currentStatus = .unableToCheck
            }//: DO-CATCH
        }//: queue(async)
    }//: encodeCurrentState()
    
    func decodeCurrentState() {
        queue.sync {
            let decoder = JSONDecoder()
            do {
                let fileToDecode = try Data(contentsOf: iCloudStateURL)
                let decodedFile = try decoder.decode(CurrentICloudState.self, from: fileToDecode)
                _currentState = decodedFile
            } catch {
                NSLog(">>> ICloudStateManager error: decodeCurrentState()")
                NSLog(">>> Either the JSON decoder threw an error while trying to decode the saved iCloudState.json file or an error was thrown while trying to open the file on disk.")
                NSLog(">>> Error: \(error.localizedDescription)")
                _currentState.currentStatus = .unableToCheck
            }//: DO-CATCH
        }//: queue(sync)
    }//: decodeCurrentState()
    
    // MARK: - INIT
    
    init() {
        
        if let savedFile = (try? Data(contentsOf: iCloudStateURL)) {
            decodeCurrentState()
        }//: IF LET
        
    }//: INIT
    
}//: CLASS

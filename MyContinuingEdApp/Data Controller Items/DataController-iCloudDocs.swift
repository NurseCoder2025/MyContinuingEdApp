//
//  DataController-iCloudDocs.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/4/26.
//

import CloudKit
import Foundation
import UIKit

extension DataController {
    // MARK: - COMPUTED PROPERTIES
    
    /// Computed property in DataController for determining that the iCloud service is
    /// available (w/ sync enabld)  and that a user is logged in.  Returns nil if either are false.
    var isICloudAvailable: Bool {
        return fileSystem.ubiquityIdentityToken != nil
    }//: isICloudAvailable
    
    
    // MARK: - METHODS
    
    /// Method for updating iCloud Document related properties in DataController whenever a user logs in/out of their
    /// iCloud account and/or disables/enables iCloud Drive syncing.
    /// - Parameter notification: Notification object from the system
    ///
    /// Method calls the fetchUserRecordID method on the defaultICloudContainer property in DataController for  determining
    /// if a different Apple Account is now signed in, if a new Account has been signed in for the first time, if the system can't
    /// authenticate into the user's account due to there not being one or iCloud Drive is disabled by the user. The
    /// certificateAudioStorage property is also updated by this method, depending on what the situation with iCloud is.
    @objc func handleUbiquityIdChange(_ notification: Notification) {
        // Whenever the user logs in/out of iCloud, or changes data sync
        // setting
        defaultICloudContainer.fetchUserRecordID { (recordID, error) in
            self.decodeICloudUserIDFile()
            if let newID = recordID,
                let savedID = self.userICloudID,
                error == nil {
                    self.compareAppleAccountIDs(oldID: savedID, newID: newID)
            } else if let newID = recordID, error == nil {
                self.userICloudID = newID
                self.iCloudAvailability = .loggedIn
                self.certificateAudioStorage = .cloud
                self.userCloudDriveURL = self.fileSystem.url(forUbiquityContainerIdentifier: nil)
                self.encodeICloudUserIDFile()
            } else if recordID == nil, error == nil {
                self.iCloudAvailability = .needSyncingAccount
                self.certificateAudioStorage = .local
            } else if let someError = error {
                switch someError {
                case CKError.notAuthenticated:
                    self.iCloudAvailability = .cantLogin
                default:
                    self.iCloudAvailability = .unableToCheck
                }//: SWITCH
                self.certificateAudioStorage = .local
            }
        }//: FetchUserRecordID
        
        objectWillChange.send()
    }//: handleUbiquityIdChange
    
    
    /// Async method for determining the iCloud status for a user on a given device.  This method
    /// first tries to run the accountStatus() method on the defaultICloudContainer and, if successful,
    /// sets the userICloudID property if nil or sets the iCloudAvailability property to the applicable
    /// value.
    ///
    /// - Important: This method should only be called upon the app's initial load as the
    /// methods being called upon may take time.  Other methods are used for updating the user's
    /// iCloud status while the app is running.
    ///
    ///  If the user's iCloud account can be successfully verified,
    ///  then the method will check to see if
    ///  the same Apple  Account is being used (if the userICloudID property has a value) and will
    ///  assign the default ubiquity container's URL to the userCloudDriveURL property.
    ///
    /// - Note: The StorageToUse enum is used to set the certificateAudioStorage property, which
    /// will determine where any new CE certificates and/or audio reflections are saved to.
    func assessUserICloudStatus() async {
        do {
            let currentStatus = try await defaultICloudContainer.accountStatus()
            
            switch currentStatus {
            case .available:
                do {
                    // The following code checks to see if the Apple Account
                    // being used to sign-in for iCloud has changed from
                    // what was previously saved.
                   let obtainedID = try await defaultICloudContainer.userRecordID()
                   decodeICloudUserIDFile()
                    
                    if let savedID = userICloudID {
                        compareAppleAccountIDs(oldID: savedID, newID: obtainedID)
                    } else {
                        userICloudID = obtainedID
                        iCloudAvailability = .loggedIn
                        encodeICloudUserIDFile()
                    }
                } catch {
                    // Per Apple's documentation, the userRecordID() method
                    // throws a CKError.Code.notAuthorized value only when
                    // the user either does not have an iCloud account, the
                    // account is restricted, or the user has disabled iCloud
                    // (turned off syncing). However, the accountStatus
                    // method called earlier already checks for the
                    // presence or absence of an iCloud account as well as
                    // for any restrictions, so if an error is thrown here
                    // it is most likely due to the user disabling the sync.
                    iCloudAvailability = .loggedInDisabled
                }//: DO-CATCH
                certificateAudioStorage = .cloud
                userCloudDriveURL = fileSystem.url(forUbiquityContainerIdentifier: nil)
            case .noAccount:
                iCloudAvailability = .noAccount
                certificateAudioStorage = .local
            case .restricted:
                iCloudAvailability = .iCloudRestricted
                certificateAudioStorage = .local
            default:
                iCloudAvailability = .unableToCheck
                certificateAudioStorage = .local
            }
        } catch {
            iCloudAvailability = .unableToCheck
            certificateAudioStorage = .local
            print("Could not determine the user's iCloud status.  Error: \(error.localizedDescription)")
        }
        
        objectWillChange.send()
    }//: assessUserICloudStatus()
    
    
    // MARK: - SUPPORTING (PRIVATE) METHODS
    
    /// Private method that writes the obtained userICloudID property to local disk for long-term
    /// storage via the NSCoding protocol.
    ///
    /// - Important: There are two constants used for creating the key and URL for saving
    /// the file:  the key is set by the String.userIDKey and the URL is set by the URL's
    /// localICloudUserFile property.  See the respective extensions for details.
    private func encodeICloudUserIDFile() {
        if let userID = userICloudID {
            let coder = NSKeyedArchiver(requiringSecureCoding: false)
            coder.encode(userID, forKey: String.userIDKey)
            coder.finishEncoding()
            
            let data = coder.encodedData
            try? data.write(to: URL.localICloudUserFile)
        }//: IF LET
    }//: encodeICloudUserIDFile()
    
    /// Private DataController method that loads the encoded user iCloud record (CKRecord.ID) data
    /// from the URL.localICloudUserFile and places it into memory via the userICloudID property.
    ///
    /// - Note: This only will set a value if data has been previously saved.  The method
    /// will simply return in the case of first-time app runs on a user's device.  If the decoding of the
    /// data from that file throws an error then the method will just return with no changes made to the
    /// userICloudID property.
    private func decodeICloudUserIDFile() {
        if let savedUserInfo = try? Data(contentsOf: URL.localICloudUserFile) {
            do {
                let loader = try NSKeyedUnarchiver(forReadingFrom: savedUserInfo)
                loader.requiresSecureCoding = false
                if let decodedData = loader.decodeObject(forKey: String.userIDKey) {
                    userICloudID = decodedData as? CKRecord.ID
                }
            } catch {
                return
            }//: DO - CATCH
        }//: IF LET
    }//: decodeICloudUserIDFile()
    
    
    /// Private method that compares two different iCloud Container record ID properties to see if they are equal or not. If they
    /// are, then the iCloudAvailability property is set to the iCloudStatus.loggedIn enum value; otherwise, it is set to
    /// iCloudStatus.loggedINDifferentAppleID.
    /// - Parameters:
    ///   - firstID: Previous iCloud Container user ID
    ///   - secondID: New iCloud Container user ID
    private func compareAppleAccountIDs(oldID: CKRecord.ID, newID: CKRecord.ID) {
        if oldID.isEqual(newID) {
            iCloudAvailability = .loggedIn
            certificateAudioStorage = .cloud
        } else {
            userCloudDriveURL = fileSystem.url(forUbiquityContainerIdentifier: nil)
            userICloudID = newID
            iCloudAvailability = .loggedINDifferentAppleID
            encodeICloudUserIDFile()
        }
    }//: compareAppleAccountIDs()
    
    
}//: EXTENSION

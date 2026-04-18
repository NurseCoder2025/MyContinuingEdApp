//
//  String+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/17/26.
//

import Foundation


extension String {
    // MARK: - iCLOUD
    static let appContainerName: String = "iCloud.com.pixelcraftlabsltd.CeCache"
    
    // MARK: - CLOUD KIT
    
    // MARK: CKRecord KEYS
    /// Constant for use in CloudKit methods. Value is "relativePath".
    static let relPathKey: String = "relativePath"
    
    /// Constant for use in CloudKit methods. Value is "mediaType".
    static let mediaKey: String = "mediaType"
    
    /// Constant for use in CloudKit methods. Value is "assignedObjectId".
    static let assignedObjectKey: String = "assignedObjectId"
    
    /// Constant for use in CloudKit methods. Value is "assignedObjectUUIDString".
    static let objectIdStringKey: String = "assignedObjectUUIDString"
    
    /// Constant for use in CloudKit methods. Value is "mediaData".
    static let mediaDataKey: String = "mediaData"
    
    static let originalAudioTranscriptionKey: String = "audioTranscription"
    static let recordTimeStampKey: String = "recordTimeStamp"
    
    
    // MARK: CKRecordZone IDs
    static let certificateZoneId: String = "userCertificates"
    static let audioReflectionZoneId: String = "userAudioReflections"
    
    
    // MARK: CKQuerySubscription-related constants
    // *** DO NOT DELETE ***
    static let certAddedQuerySubID: String = "new-cert-added"
    static let audioAddedQuerySubID: String = "new-audio-added"
    
    static let certChangedQuerySubID: String = "cert-changed"
    static let audioChangedQuerySubID: String = "audio-changed"
    
    static let certDeletedQuerySubID: String = "cert-deleted"
    static let audioDeletedQuerySubID: String = "audio-deleted"
    
    // MARK: - CORE DATA
    
    static let mediaIdPlaceholder: String = "Placeholder ID"
    
    // MARK: - File EXTENSIONS
    /// Static constant in the String struct (via extension) that sets the value for
    /// the CE certificate file package (UI Document) as "cert".
    static let certFileExtension: String = "cert"
    
    /// Static constant in the String struct (via extension) that sets the value for
    /// the audio reflection file package (UI Document) as "audio"
    static let audioReflectionExtension: String = "refl"
    
    static let audioFormatExtension: String = "m4a"
    
    static let certImageFormatExtension: String = "png"
    
    // MARK: - DATA KEYS
    
    static let userIDKey: String = "iCloud.user"
    
    // MARK: - NSQueryMetadata Keys
    
    static let resultURL: String = "NSMetadataItemURLKey"
    
    // MARK: - URL values
    
    /// String constant property that is used for the filename and extension for saving the user's
    /// iCloud user id info (CKRecord.ID object) on the local device for long-term storage and
    /// access.
    ///
    /// This property is used within the private DataController methods encodeICloudUserIDFile and
    /// decodeICloudUserIDFile.
    static let iCloudUserID: String = "iCloudUserID.json"
    
    // MARK: - OBSERVER NAMES
    // TODO: Replace String constant with static Notification.Name value
    static let cloudStoragePreferenceChanged: String = "certificateMediaStoragePreferenceChanged"
    
    // TODO: Replace String constant with static Notification.Name value
    static let cloudAudioMediaPreferenceChanged: String = "audioMediaStoragePrefChanged"
    
    
    // MARK: Prompt Notifications
    // TODO: Replace String constant with static Notification.Name value
    static let promptCatsLoaded: String = "reflectionPromptCategoriesLoaded"
    
    // MARK: - NOTIFICATION RELATED
    
    static let userInfoNotificationKey: String = "notification"
    
}//: EXTENSION


// MARK: - STRING METHODS
extension String {
    
    /// String method for limiting the length of any given string by a specified number of characters.
    /// - Parameter length: Maximum allowed length of the string
    /// - Returns: String of the specified length or less
    ///
    /// - Note: This method applies the trimmingCharacters(in: .whitespacesAndNewlines) method
    /// along with the dropLast method to the String this method is being called upon
    func trimWordsTo(length: Int) -> String {
        let stringLength = self.count
        if stringLength > length {
            let trimmedWords = String(self.trimmingCharacters(in: .whitespacesAndNewlines).dropLast(stringLength - length))
            return trimmedWords
        } else {
            return self
        }
    }//: trimWordTo(length:)
    
}//: EXTENSION


// MARK: - COMPUTED PROPERTIES
extension String {
    
    /// Computed String property that returns the number of bytes that a
    /// given String takes up, based on UTF8 encoding.
    var sizeInBytes: Int {
        return lengthOfBytes(using: .utf8)
    }//: sizeInBytes
    
    /// Computed String property that returns the number of kilobytes that a
    /// given String takes up, based on UTF8 encoding.
    var sizeInKB: Double {
        return Double(sizeInBytes) / 1024.0
    }//: sizeInKB
    
    /// Computed String property that returns the number of megabytes that a
    /// given String takes up, based on UTF8 encoding.
    var sizeInMB: Double {
        return Double(sizeInBytes) / (1024 * 1024)
    }//: sizeInMB
    
}//: EXTENSION

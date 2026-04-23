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
    static let localMediaDeletionErrorKey: String = "fileDeletionErrorNotice"
    static let localMediaFileLocKey: String = "localMediaFileURL"
    static let recordNotDeletedKey: String = "CKRecord.ID-notDeleted"
    static let cloudDeletionErrorKey: String = "cloudDeletionError"
    
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
    
    func convertToASCIIonly() -> String {
        return self.folding(
            options: .diacriticInsensitive,
            locale: .current
        ).components(
            separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-")).inverted
        ).joined(separator: "_")
    }//: convertToASCIIonly
    
}//: EXTENSION

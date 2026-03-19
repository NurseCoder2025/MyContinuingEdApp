//
//  String+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/17/26.
//

import Foundation


extension String {
    // MARK: - File EXTENSIONS
    /// Static constant in the String struct (via extension) that sets the value for
    /// the CE certificate file package (UI Document) as "cert".
    static let certFileExtension: String = "cert"
    
    /// Static constant in the String struct (via extension) that sets the value for
    /// the audio reflection file package (UI Document) as "audio"
    static let audioReflectionExtension: String = "refl"
    
    static let audioFormatExtension: String = ".m4a"
    
    // MARK: - DATA KEYS
    /// Static constant in the String struct (via extension) that represents a String dictionary key
    /// for the FileWrapper directory objects created for the CertificateDocument (UIDocument) that
    /// correspond to the CertificateMetadata object.
    static let certMetaDataKey: String = "certificate.meta"
    
    /// Static constant in the String struct (via extension) that represents a String dictionary key
    /// for the FileWrapper directory objects created for the CertificateDocument (UIDocument) that
    /// correspond to the CertificateData object.
    static let certBinaryDataKey: String = "certificate.data"
    
    static let userIDKey: String = "iCloud.user"
    
    static let audioReflectionMetaKey: String = "audioReflection.meta"
    static let audioReflectionDataKey: String = "audioReflection.data"
    static let audioReflectionRecordingKey: String = "audioReflection.recordingInfo"
    
    // MARK: - NSQueryMetadata Keys
    
    static let resultURL: String = "NSMetadataItemURLKey"
    
    // MARK: - URL values
    
    /// String constant property that is used for the filename and extension for the JSON file that will contain all
    /// CertificateCoordinator objects.  Value: "CertificateCoordinatorList.json".
    static let certCoordinatorListFile: String = "CertificateCoordinatorList.json"
    
    static let audioCoordinatorListFile: String = "AudioReflectionsCoordinatorList.json"
    
    
    /// String constant property that is used for the filename and extension for saving the user's
    /// iCloud user id info (CKRecord.ID object) on the local device for long-term storage and
    /// access.
    ///
    /// This property is used within the private DataController methods encodeICloudUserIDFile and
    /// decodeICloudUserIDFile.
    static let iCloudUserID: String = "iCloudUserID.json"
    
    // MARK: - OBSERVER NAMES
    static let cloudStoragePreferenceChanged: String = "certificateMediaStoragePreferenceChanged"
    static let cloudAudioMediaPreferenceChanged: String = "audioMediaStoragePrefChanged"
    
    // MARK: Certificate Notifications
    static let certCoordinatorListSyncCompleted: String = "certCoordinatorListSynced"
    static let certLoadingDoneNotification: String = "certificateFinishedLoading"
    static let certDeletionCompletedNotification: String = "certificateDeletionCompleted"
    static let certSaveCompletedNotification: String = "certificateSaveCompleted"
    static let certGettingRawDataDone: String = "certificateRawDataLoaded"
    
    // MARK: Audio Reflection Notifications
    static let audioCoordinatorListSyncCompleted: String = "audioCoordinatorListSynced"
    static let audioLoadingDoneNotification: String = "audioReflectionFinishedLoading"
    static let audioDeletionCompletedNotification: String = "audioReflectionDeletionCompleted"
    static let audioSaveCompletedNotification: String = "audioReflectionSaveCompleted"
    static let audioGettingRawDataDone: String = "audioReflectionRawDataLoaded"
    
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

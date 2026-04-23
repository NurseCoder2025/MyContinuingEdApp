//
//  String+Exentions_CloudKit.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/18/26.
//

import Foundation


extension String {
    
    // MARK: CKRecord TYPE
    static let mediaRecType: String = "MediaFile"
    
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

    
    
    // MARK: CKRecordZone IDs
    static let certificateZoneId: String = "userCertificates"
    static let audioReflectionZoneId: String = "userAudioReflections"
    
    
    // MARK: CKQuerySubscription-related constants
    // *** DO NOT DELETE ***
    static let mediaFileAddedQuerySubID: String = "new-media-file-added"
    static let mediaFileUpdatedQuerySubID: String = "media-file-updated"
    static let mediaFileDeletedQuerySubID: String = "media-file-deleted"
    // *** DO NOT DELETE ***
    
    // TODO: Remove the media-specific query sub ID constants:
    static let certAddedQuerySubID: String = "new-cert-added"
    static let audioAddedQuerySubID: String = "new-audio-added"
    
    static let certChangedQuerySubID: String = "cert-changed"
    static let audioChangedQuerySubID: String = "audio-changed"
    
    static let certDeletedQuerySubID: String = "cert-deleted"
    static let audioDeletedQuerySubID: String = "audio-deleted"
    
    // MARK: Master MEDIA LIST
    static let emptyRecName: String = "Non-Existent_Record_\(UUID().uuidString)"
    static let masterMediaListFileKey: String = "allMedia"
    
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

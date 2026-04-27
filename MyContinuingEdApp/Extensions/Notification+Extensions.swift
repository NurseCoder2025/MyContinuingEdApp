//
//  Notification+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/16/26.
//

import Foundation

// File for storing all notification names in

extension Notification.Name {
    
    static let cloudDBChangeNotification = Notification.Name("cloudDatabaseChanged")
    
    // Notfications for indicating that a locally-initiated deletion
    // of a CKRecord completed successfully
    static let cloudRecordDeletedSuccessfully = Notification.Name("cloudRecordDeletedSuccessfully")
    static let cloudRecordDeletionFailed = Notification.Name("cloudRecordDeletionFailed")
    
    // Notifications for when local media files are deleted
    static let localCertFileDeleted = Notification.Name("localCertFileDeleted")
    static let localAudioReflFileDeleted = Notification.Name("localAudioReflectionDeleted")
    static let localMediaFileDeletionError = Notification.Name("localMediaFileDeletionError")
    
    // Notifications when batch iCloud media files are deleted
    static let uploadedCertsDeleted = Notification.Name("uploadedCertsDeleted")
    
    static let cloudCertStoragePrefChanged = Notification.Name("certificateMediaStoragePreferenceChanged")
    
    static let cloudAudioStoragePrefChanged = Notification.Name("audioMediaStoragePrefChanged")
    
    static let promptCategoriesLoaded = Notification.Name("reflectionPromptCategoriesLoaded")
    
    
    
}//: EXTENSION

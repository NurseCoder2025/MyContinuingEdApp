//
//  Notification+Extensions.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/16/26.
//

import Foundation

// File for storing all notification names in

extension Notification.Name {
    
    static let cloudKitRecordChanged = Notification.Name("cloudKitRecordChanged")
    static let cloudKitRecordAdded = Notification.Name("cloudKitRecordAdded")
    static let cloudKitRecordDeleted = Notification.Name("cloudKitRecordDeleted")
    static let cloudKitUknownRecChange = Notification.Name("unknownCloudKitRecChange")
    
    static let cloudCertStoragePrefChanged = Notification.Name("certificateMediaStoragePreferenceChanged")
    
    static let cloudAudioStoragePrefChanged = Notification.Name("audioMediaStoragePrefChanged")
    
    static let promptCategoriesLoaded = Notification.Name("reflectionPromptCategoriesLoaded")
    
    
    
}//: EXTENSION

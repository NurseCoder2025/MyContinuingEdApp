//
//  MediaBrain.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import CloudKit
import Foundation


final class CloudMediaBrain: ObservableObject {
    // MARK: - PROPERTIES
    
    let cloudState = ICloudStateManager()
    
    let cloudDB: CKDatabase = CKContainer.default().privateCloudDatabase
    let certZone = CKRecordZone(zoneName: String.certificateZoneId)
    let audioZone = CKRecordZone(zoneName: String.audioReflectionZoneId)
    
    
    
    // MARK: - RECORD ZONE HANDLING
    
    // MARK: - SAVING
    
    // MARK: - CHANGING
    
    // MARK: - DELETING
    
    
    // MARK: - INIT
    
    
}//: CloudMediaBrain

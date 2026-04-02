//
//  CertificateModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/1/26.
//

import CloudKit
import Foundation


struct CertificateModel: MediaModel {
    // MARK: - PROPERTIES
    let id: UUID
    var relativePath: String
    var mediaType: MediaType
    var saveLocation: String
    var appVersion: Double
    var assignedObjectId: UUID
    
    var cloudRecord: CKRecord
    
    // MARK: - PROTOCOL CONFROMANCE
    
    static func ==(lhs: CertificateModel, rhs: CertificateModel) -> Bool {
        if lhs.relativePath == rhs.relativePath, lhs.mediaType == rhs.mediaType, lhs.saveLocation == rhs.saveLocation, lhs.appVersion == rhs.appVersion, lhs.assignedObjectId == rhs.assignedObjectId {
            return true
        } else {
            return false
        }
    }//: ==
    
    // MARK: - INITS
    init(
        id: UUID = UUID(),
        relativePath: String,
        mediaType: MediaType = .image,
        savedAt location: String,
        appVersion: Double = 1.0,
        assignedObjectId: UUID,
        cloudRecord: CKRecord,
    ) {
        self.id = id
        self.relativePath = relativePath
        self.mediaType = mediaType
        self.saveLocation = ""
        self.appVersion = appVersion
        self.assignedObjectId = assignedObjectId
        self.cloudRecord = cloudRecord
        
    }//: INIT
    
    
}//: CertificateModel

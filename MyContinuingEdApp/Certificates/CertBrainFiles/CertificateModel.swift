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
    var mediaType: String
    var saveLocation: String
    var appVersion: Double
    var assignedObjectId: UUID
    
    var cloudRecord: CKRecord?
    
    // ** Important **
    // Per the MediaModel protocol, there is a computed property
    // called 'objectIdString' that will return the string value of
    // the assignedObjectId property.
    //
    // Also, there is a resolveURL(basePath) method that creates a
    // complete URL when needed, using the relativePath string and
    // URL for the basePath parameter.
    
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
        mediaType: String = MediaType.image.rawValue,
        savedAt location: String = SaveLocation.local.rawValue,
        appVersion: Double = 1.0,
        assignedObjectId: UUID,
        cloudRecord: CKRecord? = nil,
    ) {
        self.id = id
        self.relativePath = relativePath
        self.mediaType = mediaType
        self.saveLocation = location
        self.appVersion = appVersion
        self.assignedObjectId = assignedObjectId
        self.cloudRecord = cloudRecord
        
    }//: INIT
    
    
}//: CertificateModel

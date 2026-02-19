//
//  CertificateCoordinator.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/18/26.
//

import Foundation


/// Data model object for helping with syncing CE certificate files along with the
/// CoreData entity object that it is assigned to.
///
/// - Parameters:
///     - fileURL: the url where the actual ce certificate data is saved to
///     - mediaMetaData: the meta data object model for the certificate
///
/// This object is intended to facilitate the syncing of CE certificate files with CoreData in
/// that whenever a CE certificate is added to a completed CeActivity, this coordinator
/// object is created along with the corresponding UI Document for the url where the
/// data will be saved.  Whenever a CeActivity is deleted from CoreData, then this
/// object should be used to find the right file for deletion (using the coordinator's
/// assignedObjectID property (which is set by the corresponding property in the meta data
/// object) and then using the fileURL property to remove the file.
struct CertificateCoordinator: MediaCoordinator {
    // MARK: - PROPERTIES
    var fileURL: URL
    let mediaMetadata: any MediaMetadata
    
    // MARK: - CONFORMANCE
    static func ==(lhs: CertificateCoordinator, rhs: CertificateCoordinator) -> Bool {
        lhs.id == rhs.id
    }//: ==
    
    // MARK: - INIT
    init(file fileURL: URL, metaData mediaMetadata: any MediaMetadata) {
        self.fileURL = fileURL
        self.mediaMetadata = mediaMetadata
    }//:INIT
    
}//: CertificateCoordinator

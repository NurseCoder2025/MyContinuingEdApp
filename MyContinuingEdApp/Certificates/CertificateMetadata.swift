//
//  CECertificate.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/4/26.
//

import Foundation


/// Data model object for holding meta data for a CE certificate that is saved to disk by the
/// user for a given CeActivity.
///
/// - Parameters:
///     - whereSaved: SaveLocation enum value (either .local or .cloud)
///     - assignedObjectID: the UUID for the CoreData CeActivity object the certificate
///     is associated with
///     - mediaAs: MediaType enum value (either .image or .pdf)
///     - versionNumber: Double representing the app version for future reference (default
///     value is set as 1.0)
///
///  This object is intended to be part of the CertificateDocument properties that is wrapped
///  and unwrapped in a FileWrapper for the url where the certificate data is saved.
///  - Important: The assignedObjectId value is used for matching the right CE certificate
///  UI Document with the activity it is associated with.  It is also used for setting the
///  CertificateCoordinator's assignedObjectId property as well.
struct CertificateMetadata: MediaMetadata {
    // MARK: - PROPERTIES
    internal var whereSaved: SaveLocation = .local
    let assignedObjectId: UUID
    var mediaAs: MediaType = .image
    var isExampleOnly: Bool = false
    
    // MARK: - METHODS
    
    mutating func markSavedOniCloud() {
        whereSaved = .cloud
    }//: markSaveOniCloud()
    
    mutating func markSavedOnDevice() {
        whereSaved = .local
    }//: markSavedOnDevice()
    
    // MARK: - EXAMPLE
    static let example = CertificateMetadata(forCeId: UUID(), exampleOnly: true)
    
    // MARK: - INIT
    init(
        saved whereSaved: SaveLocation = .local,
        forCeId assignedObjectId: UUID,
        as mediaAs: MediaType = .image,
        exampleOnly: Bool = false
    ) {
        self.whereSaved = whereSaved
        self.assignedObjectId = assignedObjectId
        self.mediaAs = mediaAs
        self.isExampleOnly = exampleOnly
    }//: INIT
    
}//: CertificateMetadata





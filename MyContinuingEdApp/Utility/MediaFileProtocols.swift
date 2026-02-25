//
//  MediaFileProtocols.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/13/26.
//

import Foundation


// MARK: - MediaMetadata

/// The MediaMetadata holds required properties and other protocol conformances for any media
/// metadata files created within this app.
///
/// In order to conform, an object must:
///     - Conform to Identifiable, Codable & Hashable protocols
///     - Contain the following properties (getters only):
///          - versionNumber: Int (to allow for data structure changes later on) [default in extension]
///          - whereSaved: SaveLocation (enum) - specifying whether object is local or on the cloud
///          - assignedObjectId: UUID (for whatever CoreData object it is associated with)
///          - mediaAs: MediaType (enum)
///
///  - Note: A default value of 1.0 is set for the versionNumber property via a protocol extension as well
///  as the id property for Identifiable conformance (UUID value).
protocol MediaMetadata: Identifiable, Codable, Hashable {
    var id: UUID {get}
    var versionNumber: Double {get}
    var whereSaved: SaveLocation {get set}
    var assignedObjectId: UUID {get}
    var mediaAs: MediaType {get set}
    
}//: PROTOCOL


extension MediaMetadata {
    var id: UUID { return UUID() }
    var versionNumber: Double{ return 1.0 }
}//: EXTENSION

// MARK: - Media Coordination

/// Protocol for ensuring that any objects used as a media coordinator (linking a media file to a CoreData
/// entity object like CeActivity) have the properties needed to function properly.
///
/// Conformance to this protocol requires the following:
///     - Required properties:
///         - id: UUID (for Identifiable conformance)
///         - fileURL: URL (get & set)
///         - assignedObjectID: UUID (get)
///         - mediaMetadata: any object conforming to the MediaMetadata protocol
///         - fileVersion: a NSFileVersion class instance for the fileURL being represented
///
///  - Note: Default values are set for the id propetry (as a new UUID value) & the assignedObjectID
///  property (from the mediaMetadata object's assignedObjectID property) via protocol extension.  Also,
///  a custom hash function sets the hash value as the fileURL property as all urls should be unique and
///  this will prevent potential conflicts where two coordinators have the same URL.
protocol MediaCoordinator: Identifiable, Hashable, Codable {
    var id: UUID {get}
    var fileURL: URL {get set}
    var assignedObjectID: UUID {get}
    var mediaMetadata: any MediaMetadata {get}
    var fileVersion: MediaFileVersion {get set}
}//: PROTOCOL

extension MediaCoordinator {
    var id: UUID { return UUID() }
    var assignedObjectID: UUID {mediaMetadata.assignedObjectId}
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileURL)
    }//: hash
}//: EXTENSION

// MARK: - CE Certificate Media Types

/// Custom protocol to enable functions and computed properties to handle binary data that is for either
/// a CE certificate object saved as an image file OR as a pdf.
///
/// The only requirement for this protcol is a property "certificateType", which is of the CertType enum data
/// type.  Currently, the only two objects assigned to this protocol are UIImage and PDFDocument, and the
/// certificateType values in each of those cases are .image and .pdf, respectively.
protocol Certificate {
    var certificateType: CertType {get}
}//: PROTOCOL

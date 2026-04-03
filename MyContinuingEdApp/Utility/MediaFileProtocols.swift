//
//  MediaFileProtocols.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/13/26.
//

import CloudKit
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
    var assignedObjectId: UUID {get}
    var mediaAs: MediaType { get set }
    var isExampleOnly: Bool { get set }
    var fileVersion: MediaFileVersion {get set}
}//: PROTOCOL


extension MediaMetadata {
    var id: UUID { return UUID() }
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
    // MARK: Properties
    var id: UUID {get}
    var fileURL: URL {get set}
    var whereSaved: SaveLocation {get set}
    var assignedObjectID: UUID {get}
    var mediaMetadata: any MediaMetadata {get}
   
    // MARK: Methods
    mutating func markSavedOniCloud()
    mutating func markSavedOnDevice()
}//: PROTOCOL

extension MediaCoordinator {
    var assignedObjectID: UUID {mediaMetadata.assignedObjectId}
    
    mutating func markSavedOniCloud() {whereSaved = .cloud}//: markSavedOniCloud
    mutating func markSavedOnDevice() {whereSaved = .local}//: markSavedOnDevice
    
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


// MARK: - CloudKit Media Models

/// Protocol for defining the minimum requirements for the data models of any media files used in this
/// app such as images, PDFs, and audio.
///
/// One of the required methods for this protocol, resolveURL(basePath),  has a defined default
/// implementation within the MedialModel extension. It serves to convert a relative path for any stored
/// media file into an absolute URL that can be used by the app to locate the file.
///
///  This protocol also defines a required objectIdString property, but has a defined default implmentation
///  where a computed property of the same name returns the uuidString from the assignedObjectId value
///  that was passed in during initialization.
protocol MediaModel: Identifiable, Equatable, Hashable {
    var id: UUID { get }
    var relativePath: String { get set }
    var mediaType: String { get set }
    var saveLocation: String { get set }
    var appVersion: Double { get }
    var assignedObjectId: UUID { get }
    var cloudRecord: CKRecord? { get set }
    var objectIdString: String { get }

    
    func resolveURL(basePath: URL) -> URL
    mutating func setSaveLocationTypeString(for location: SaveLocation)
}//: MedialModel


extension MediaModel {
    
    /// Computed property for any object conforming to MediaModel protocol. It returns
    /// a String version of the UUID argument passed in during initialization.
    ///
    /// This property is necessary for using CKQuery to lookup individual media items
    /// as it only supports a limited number of data types for the NSPredicate it takes.
    var objectIdString: String {
        assignedObjectId.uuidString
    }//: objectIdString
    
    /// Method required as part of the MediaModel protocol that converts a relative path into an
    /// absolute URL for locating a saved media (image, PDF, audio) file.
    /// - Parameter basePath: the top-level URL for where a media file is stored
    /// - Returns: An absolute URL using the base path along with a URL with the relative path
    /// added to it
    ///
    /// An example of a base path would be the documentsDirectory or iCloud ubiquity container URL  for
    /// the app.
    func resolveURL(basePath: URL) -> URL {
        basePath.appending(path: relativePath, directoryHint: .notDirectory)
    }//: resolveURL(basePath)
    
    mutating func setSaveLocationTypeString(for location: SaveLocation) {
        saveLocation = location.rawValue
    }//: setSaveLocationTypeString
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(assignedObjectId)
        hasher.combine(appVersion)
        hasher.combine(relativePath)
        hasher.combine(mediaType)
    }//: hash
}//: EXTENSION (MediaModel)

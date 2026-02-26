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
    var fileVersion: MediaFileVersion
    
    // MARK: - CONFORMANCE
    
    /// Custom conformance method for the CertificateCoordinator struct that determines whether two coordinator
    /// objects are the same (equal).
    /// - Parameters:
    ///   - lhs: CertificateCoordinator object to be compared
    ///   - rhs: CertificateCoordinator object to be compared
    /// - Returns: true if conditions are met; otherwise false
    ///
    ///  Two CertificateCoordinators are considered to be equal IF the following conditions are met:
    ///     - Conditions:
    ///         - Both have the samed CeActivity object assigned to them
    ///         - Both have the same media type in the metadata (image or pdf)
    ///         - Both have the same fileURL value
    ///         - Both have the same fileVersion object
    ///
    ///  If the mediaMetaData property for either argument cannot be downcast as a CertificateMetaData object,
    ///  then the method compares two coordinators on the basis of their id properties.
    static func ==(lhs: CertificateCoordinator, rhs: CertificateCoordinator) -> Bool {
        if let leftMeta = lhs.mediaMetadata as? CertificateMetadata,
            let rightMeta = rhs.mediaMetadata as? CertificateMetadata {
            
            let leftObject = leftMeta.assignedObjectId
            let rightObject = rightMeta.assignedObjectId
            let leftMediaType = leftMeta.mediaAs
            let rightMediaType = rightMeta.mediaAs
            
            let leftURL = lhs.fileURL
            let leftVersion = lhs.fileVersion
            let rightURL = rhs.fileURL
            let rightVersion = rhs.fileVersion
            
            if leftObject == rightObject,
                leftMediaType == rightMediaType,
                leftURL == rightURL,
                leftVersion == rightVersion
            {
                return true
            } else {
                return false
            }
        } else {
            return lhs.id == rhs.id
        }
    }//: ==
    
    enum CertificateKeys: CodingKey { case fileURL, mediaMetaData, fileVersion }
    
   func encode(to encoder: Encoder) throws {
       var container = encoder.container(keyedBy: CertificateKeys.self)
       try container.encode(fileURL, forKey: .fileURL)
       try container.encode(mediaMetadata, forKey: .mediaMetaData)
       try container.encode(fileVersion, forKey: .fileVersion)
    }//: encode
    
    // MARK: - INIT
    
    /// Primary initializer for creating CertificateCoordinator objects
    /// - Parameters:
    ///   - fileURL: URL for where a specific CE certificate has been saved
    ///   - mediaMetadata: CertificateMetadata object for the saved certificate
    ///   - fileVersion: MediaFileVersion object for the saved certificate
    init(
        file fileURL: URL,
        metaData mediaMetadata: any MediaMetadata,
        version fileVersion: MediaFileVersion
    ) {
        self.fileURL = fileURL
        self.mediaMetadata = mediaMetadata
        self.fileVersion = fileVersion
    }//:INIT
    
    /// Initializer for decoding an existing CertificateCoordinator object from file
    /// - Parameter decoder: a JSON decoder that will decode the saved object
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CertificateKeys.self)
        self.fileURL = try container.decode(URL.self, forKey: .fileURL)
        self.mediaMetadata = try container.decode(CertificateMetadata.self, forKey: .mediaMetaData)
        self.fileVersion = try container.decode(MediaFileVersion.self, forKey: .fileVersion)
    }//: INIT (from decoder)
    
}//: CertificateCoordinator

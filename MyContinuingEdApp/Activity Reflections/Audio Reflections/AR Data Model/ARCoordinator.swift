//
//  ARCoordinator.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/12/26.
//

import Foundation

/// Data model object for connecting audio reflection files with a specific ReflectionResponse
/// object so that the audio data can be deleted along with the ReflectionResponse if the user
/// deletes either the specific respsonse or the CeActivity to which any reflections are associated
/// with.
struct ARCoordinator: MediaCoordinator {
    // MARK: - PROPERTIES
    let id: UUID
    var fileURL: URL
    var whereSaved: SaveLocation
    var mediaMetadata: any MediaMetadata
    
    // Per MediaCoordinator protocol, the assignedObjectID property is
    // also available since it's value was set to be what is in
    // the metadata object by the protocol extension.
    
    // MARK: - CONFORMANCE
    
    /// Method for conforming the ARCoordinator object to Equatable.
    /// - Parameters:
    ///   - lhs: ARCoordinator object to be compared
    ///   - rhs: Second ARCoordinator object to be compared
    /// - Returns: True if conditions for equality are met, false if otherwise
    ///
    /// The custom conformance for this object is based on two key values: first, the
    /// CoreData ReflectionResponse ID property, and, second, the URL for the saved
    /// audio data.  If both of those are equivalent, then the two objects can be considered
    /// to be the same.
    static func ==(lhs: ARCoordinator, rhs: ARCoordinator) -> Bool {
        if let leftMeta = lhs.mediaMetadata as? ARMetadata,
            let rightMeta = rhs.mediaMetadata as? ARMetadata {
            
            let leftObject = leftMeta.assignedObjectId
            let rightObject = rightMeta.assignedObjectId
            
            let leftURL = lhs.fileURL
            let rightURL = rhs.fileURL
            
            if leftObject == rightObject, leftURL == rightURL {
                return true
            } else {
                return false
            }
        } else {
            return lhs.id == rhs.id
        }//: IF ELSE
    }//: ==()
    
    enum ARKeys: CodingKey { case id, fileURL, whereSaved, mediaMetadata} //: ARKeys
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ARKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fileURL, forKey: .fileURL)
        try container.encode(whereSaved, forKey: .whereSaved)
        try container.encode(mediaMetadata, forKey: .mediaMetadata)
    }//: encode(to)
    
    // MARK: - INITS
    
    /// Primary initializer method for the ARCoordinator object when creating the object
    /// for the first time.
    /// - Parameters:
    ///   - id: UUID (generated automatically)
    ///   - fileURL: URL representing the location where the audio reflection file is stored
    ///   - whereSaved: SaveLocation enum value indicating whether the fileURL is on
    ///   the device or iCloud
    ///   - mediaMetadata: ARMetdata object
    ///
    /// - Important: If loading previously saved objects from disk, use the second init(from decoder)
    /// method to load previously written coordinators.
    init(
        id: UUID = UUID(),
        fileURL: URL,
        mediaMetadata: any MediaMetadata
    ) {
        self.id = id
        self.fileURL = fileURL
        self.mediaMetadata = mediaMetadata
        
        let fileSystem = FileManager()
        self.whereSaved = (try? fileSystem.identifyFileURLLocation(for: fileURL)) ?? .unknown
        
    }//: INIT
    
    /// Secondary initializer method for the ARCoordinator object for loading previously
    /// saved coordinator objects for audio reflections.
    /// - Parameter decoder: JSON decoder object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ARKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.fileURL = try container.decode(URL.self, forKey: .fileURL)
        self.whereSaved = try container.decode(SaveLocation.self, forKey: .whereSaved)
        self.mediaMetadata = try container.decode(ARMetadata.self, forKey: .mediaMetadata)
    }//: INIT (from decoder)
    
}//: ARCoordinator

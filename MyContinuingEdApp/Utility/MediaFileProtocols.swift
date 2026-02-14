//
//  MediaFileProtocols.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 2/13/26.
//

import Foundation


/// The MediaObjectModel holds required properties and other protocol conformances for any media files
/// being modeled and saved within this app.
///
/// In order to conform, an object must:
///     - Conform to Identifiable, Codable & Hashable protocols
///     - Contain the following properties (getters only):
///          - assignedObjectId: UUID (for whatever CoreData object it is associated with)
///          - fileExtension: String (i.e. jpg, PDF, m4a)
///          - fileName: String (can be computed, but must be a getter only)
public protocol MediaObjectModel: Identifiable, Codable, Hashable {
    var assignedObjectId: UUID {get}
    var fileExtension: String {get}
    var fileName: String {get}
    
}//: PROTOCOL

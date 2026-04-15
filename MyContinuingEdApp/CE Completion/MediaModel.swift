//
//  MediaModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import Foundation


struct MediaModel {
    // MARK: - PROPERTIES
    let assignedObjectId: UUID
    let ckRecType: CkRecordType
    let mediaType: MediaType
    let savedAt: URL
    
    // MARK: - METHODS
    // The following methods are needed for passing in a String value into a
    // CKRecord, as it doesn't recognize enum types as such.
    
    func getMediaTypeName() -> String { mediaType.rawValue }//: getMediaTypeName()
    
    func getRecTypeName() -> String { ckRecType.rawValue }//: getRecTypeName()
    
    func createAssignedObjIdString() -> String { assignedObjectId.uuidString }
    
}//: MediaModel

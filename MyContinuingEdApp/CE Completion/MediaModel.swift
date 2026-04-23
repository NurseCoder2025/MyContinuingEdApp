//
//  MediaModel.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/10/26.
//

import CoreData
import Foundation


struct MediaModel {
    // MARK: - PROPERTIES
    let assignedObjectId: UUID
    let ckRecType: CkRecordType
    let mediaType: MediaType
    let mediaDataSavedAt: URL
    let relPathForCKRecordID: String
    
    // Audio reflections ONLY
    var transcription: String = ""
    let transcriptionSavedAt: URL = URL.tempTranscriptionFile
    
    // MARK: - COMPUTED PROPERTIES
    
    var designatedClass: MediaClass {
        switch ckRecType {
        case .certificate:
            return MediaClass.certificate
        case .audioReflection:
            return MediaClass.audioReflection
        }//: SWITCH
    }//: designatedClass
    
    
    // MARK: - METHODS
    // The following methods are needed for passing in a String value into a
    // CKRecord, as it doesn't recognize enum types as such.
    
    func getMediaTypeName() -> String { mediaType.rawValue }//: getMediaTypeName()
    
    func getRecTypeName() -> String { ckRecType.rawValue }//: getRecTypeName()
    
    func createAssignedObjIdString() -> String { assignedObjectId.uuidString }
    
}//: MediaModel

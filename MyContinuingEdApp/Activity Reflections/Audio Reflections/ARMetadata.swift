//
//  ARMetadata.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/12/26.
//

import Foundation

struct ARMetadata: MediaMetadata {
    // MARK: - PROPERTIES
    var versionNumber: Double
    let assignedObjectId: UUID
    var mediaAs: MediaType
    var isExampleOnly: Bool = false
    var fileVersion: MediaFileVersion
    var promptQuestion: String = ""
    
    // MARK: - EXAMPLE
    static let example: ARMetadata = ARMetadata(
        forResponseId: UUID(),
        as: .audio,
        isExampleOnly: true,
        fileVersion: .example
    )//: example
    
    // MARK: - INIT
    init(
        forResponseId assignedObjectId: UUID,
        as mediaAs: MediaType = .audio,
        isExampleOnly: Bool = false,
        fileVersion: MediaFileVersion,
        prompt: String = ""
    ) {
        self.assignedObjectId = assignedObjectId
        self.mediaAs = mediaAs
        self.isExampleOnly = isExampleOnly
        self.fileVersion = fileVersion
        self.promptQuestion = prompt
        
        let versionNum = fileVersion.version
        self.versionNumber = versionNum
    }//: INIT
}//: ARMetadata

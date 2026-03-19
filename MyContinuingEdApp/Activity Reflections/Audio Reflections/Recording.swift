//
//  Recording.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/17/26.
//

import Foundation


struct Recording: Codable, Identifiable, Hashable {
    // MARK: - PROPERTIES
    let id: UUID
    var fileName: String
    var recordingDate: Date
    var transcriptionFileName: String
    var transcription: String
    var isExampleOnly: Bool
    
    // MARK: - EXAMPLE
    static let example = Recording(
        fileName: "sampleReflection.m4a",
        recordingDate: Date.now,
        transcriptionFilename: "exampleTranscription.txt",
        transcription: "Example transcription text...",
        isExample: true
    )
    
    // MARK: - INIT
    init(
        id: UUID = UUID(),
        fileName: String,
        recordingDate: Date = Date.now,
        transcriptionFilename: String,
        transcription: String,
        isExample: Bool = false
    ) {
        self.id = id
        self.fileName = fileName
        self.recordingDate = recordingDate
        self.transcriptionFileName = transcriptionFilename
        self.transcription = transcription
        self.isExampleOnly = isExample
    }//: INIT
    
}//: STRUCT

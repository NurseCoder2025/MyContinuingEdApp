//
//  AudioInfo-CoreDataHelper.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/22/26.
//

import CloudKit
import CoreData
import Foundation

extension AudioInfo {
    
    // MARK: - UI HELPERs
    
    var audioRelativePath: String {
        get {
            relativePath ?? ""
        }
        set {
            relativePath = newValue
        }
    }//: audioRelativePath
    
    var audioTranscription: String {
        get {
            transcription ?? ""
        }
        set {
            transcription = newValue
        }
    }//: audioTranscription
    
    var audioCKRecordID: CKRecord.ID {
        get {
            guard let record = ckRecordID as? CKRecord.ID else {
                return CKRecord.ID(recordName: String.mediaIdPlaceholder)
            }//: GUARD
            return record
        }
        set {
            ckRecordID = newValue as NSObject
        }
    }//: audioCKRecordID
    
    // MARK: - COMPUTED PROPERTIES
    
    var questionText: String {
        if let prompt = getAssignedPrompt(),
        let specificQuestion = prompt.question {
            return specificQuestion
        } else {
            return ""
        }//: IF LET ELSE
    }//: questionText
    
    var questionCat: String {
        if let prompt = getAssignedPrompt(),
        let cat = prompt.promptCategory {
            return cat.categoryName ?? ""
        } else {
            return ""
        }//: IF LET ELSE
    }//: questionCat
    
    var fileSizeInMegabytes: Double {
        fileSize / 1_024_000.0
    }//: fileSizeInMegabytes
    
    // MARK: - RELATIONSHIPS
    
    // Question associated with the audio data
    func getAssignedPrompt() -> ReflectionPrompt? {
        if let assignedResponse = response,
           let assignedPrompt = assignedResponse.question {
            return assignedPrompt
        } else {
            return nil
        }//: IF ELSE
    }//: getAssignedPrompt()
    
    // The overall reflection object (one per CeActivity) that can contain
    // many different responses (question + answer)
    func getAssignedReflection() -> ActivityReflection? {
        if let assignedResponse = response,
        let assignedReflection = assignedResponse.reflection {
            return assignedReflection
        } else {
            return nil
        }//: IF ELSE
    }//: getAssignedReflection()
    
    func getAssignedCeActivity() -> CeActivity? {
        if let reflection = getAssignedReflection(),
        let activity = reflection.ceToReflectUpon {
            return activity
        } else {
            return nil
        }//: IF LET ELSE
    }//: getAssignedCeActivity()
    
    // MARK: - PROTOCOL CONFORMANCE
    
    func resolveURL(basePath: URL) -> URL? {
        guard basePath.hasDirectoryPath else {return nil}
        guard let pathSaved = relativePath else {return nil}
        return basePath.appending(path: pathSaved, directoryHint: .notDirectory)
    }//: resolveURL(basePath)
    
    func returnCDSelf() -> NSManagedObject {
        return self
    }//: returnCDSelf
    
    // MARK: - CLOUD KIT
    
    func createMediaModelForAudioInfo() -> MediaModel? {
        guard let audioID = audioInfoID, let filePath = relativePath else { return nil }
        let mediaType = MediaType.audio
        let audioSavedLocation = resolveURL(basePath: URL.localAudioReflectionsFolder)
        
        if let audioURL = audioSavedLocation {
            return MediaModel(
                assignedObjectId: audioID,
                ckRecType: .audioReflection,
                mediaType: mediaType,
                mediaDataSavedAt: audioURL,
                relPathForCKRecordID: filePath,
                transcription: audioTranscription
            )//: MediaModel
        } else {
            return nil
        }//: IF LET ELSE (audioURL = audioSavedLocation)
    }//: createMediaModelForAudioInfo()
    
}//: EXTENSION


// MARK: - ADDITIONAL PROTOCOlS

extension AudioInfo: RepresentsDeletableMediaFile {
    
    
    
}//: EXTENSION

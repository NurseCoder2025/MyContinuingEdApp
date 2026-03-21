//
//  ARDocument.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 3/12/26.
//

import CloudKit
import Foundation
import UIKit

final class ARDocument: UIDocument {
    // MARK: - PROPERTIES
    
    var fileWrapper: FileWrapper?
    var fileMetadata: ARMetadata?
    var fileRecordingInfo: Recording?
    var rawAudioData: Data?
    
    // MARK: - COMPUTED PROPERTIES
    
    lazy var audioMetadata: ARMetadata = {
        guard
            let existingData = fileWrapper,
            let metaData = decodeAudioReflectObjsFromWrapper(.audioReflectionMetaKey) as? ARMetadata else {
            if let newMeta = fileMetadata {
                return newMeta
            } else {
                return ARMetadata.example
            }//: IF LET ELSE
        }//: GUARD
        
        return metaData
    }()//: audioMetadata
    
    lazy var audioBinaryData: AudioReflectionData = {
        guard
            let existingData = fileWrapper,
            let audioBinary = decodeAudioReflectObjsFromWrapper(.audioReflectionDataKey) as? AudioReflectionData else {
           return AudioReflectionData(containing: rawAudioData)
        }//: GUARD
        
        return audioBinary
    }()//: audioBinaryData
    
    lazy var audioRecordingInfo: Recording = {
        guard
            let existingData = fileWrapper,
            let recordingInfo = decodeAudioReflectObjsFromWrapper(.audioReflectionRecordingKey) as? Recording else {
            return Recording.example
        }
        
        return recordingInfo
    }()//: audioRecordingInfo
    
    // MARK: - UI Document Overrides
    
    /// UIDocument method customized for the ARDocument subclass that writes new audio reflection
    /// data into a FileWrapper directory object and returns it so that it can be stored within the fileWrapper
    /// property for future read/write.
    /// - Parameter typeName: String value representing the file type
    /// - Returns: A FileWrapper with directory object (dictionary with the audio reflection keys and
    /// corresponding data objects (metadata and the binary data)
    override func contents(forType typeName: String) throws -> Any {
        if let metaWrapper = encodeToJSONForWrapper(toEncode: audioMetadata),
           let dataToWrap = rawAudioData,
           let audioDataWrapper = encodeToJSONForWrapper(toEncode: AudioReflectionData(containing: dataToWrap)),
           let recordingWrapper = encodeToJSONForWrapper(toEncode: fileRecordingInfo)
        {
            let wrappers: [String: FileWrapper] = [
                .audioReflectionMetaKey: metaWrapper,
                .audioReflectionDataKey: audioDataWrapper,
                .audioReflectionRecordingKey: recordingWrapper
            ]
            
            let wrapperDictionary = FileWrapper(directoryWithFileWrappers: wrappers)
            fileMetadata = nil
            rawAudioData = nil
            fileRecordingInfo = nil
            return wrapperDictionary
        } else {
            NSLog(">>>Error: Failed to create a FileWrapper directory object with binary data, metadata object, and recording info for an audio reflection.")
            NSLog(">>>Was audio binary data used to create document: \(rawAudioData != nil)")
            throw FileIOError.writeFailed
        }//: IF ELSE
    }//: contents(forType)
    
    /// UIDocument class method with custom implementation (via override) that sets the value of the
    /// optional fileWrapper property for ARDocument provided the fromContents argument can be
    /// downcast as a FileWrapper object.
    /// - Parameters:
    ///   - contents: FileWrapper object
    ///   - typeName: String representing the file extension for this type of document)
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let fileWrapper = contents as? FileWrapper else {
            NSLog(">>>Error: Failed to downcast the fromContents argument to a FileWrapper object.")
            throw FileIOError.loadingError
        }//: GUARD
        
        self.fileWrapper = fileWrapper
    }//: load(fromContents, ofType)
    
    // MARK: - PRIVATE METHODS
    
    /// Private method used for returning audio reflection objects (metadata, recording info, and audio data) to the
    /// computed properties within ARDocument.
    /// - Parameter wrapper: String value that is the name of the wrapper to be decoded
    /// - Returns: A decoded ARMetadata, Recording, or AudioReflectionData object if those keys were
    /// used; otherwise, the contents of a FileWrapper for a regular file
    ///
    /// - Important: The wrapper keys are stored as static constants for the String data type
    private func decodeAudioReflectObjsFromWrapper(_ wrapper: String) -> Any? {
        guard
            let allWrappers = fileWrapper,
            let specifiedWrapper = allWrappers.fileWrappers?[wrapper],
            let data = specifiedWrapper.regularFileContents
        else { return nil }
        
        let decoder = JSONDecoder()
        if wrapper == .audioReflectionMetaKey {
            return try? decoder.decode(ARMetadata.self, from: data)
        } else if wrapper == .audioReflectionDataKey {
            return try? decoder.decode(AudioReflectionData.self, from: data)
        } else if wrapper == .audioReflectionRecordingKey {
            return try? decoder.decode(Recording.self, from: data)
        } else {
            return data
        }
    }//: decodeAudioReflectObjsFromWrapper(wrapper)
    
    // MARK: - INITS
    
    /// Primary initializer for accessing and updating the data for any exisiting AudioReflection
    /// file.
    /// - Parameter audioURL: URL for where the document was saved to
    init(audioURL: URL) {
        super.init(fileURL: audioURL)
    }//: INIT
    
    /// Initalizer for creating a brand new AudioReflection document for the very first time.
    /// - Parameters:
    ///   - audioURL: URL for the document to be created and saved to
    ///   - metaData: ARMetadata object containing metadata for the audio
    ///   - withData: binary data (Data) of the audio to be saved
    init(audioURL: URL, metaData: ARMetadata, withData: Data, recordingInfo: Recording) {
        super.init(fileURL: audioURL)
        self.fileMetadata = metaData
        self.rawAudioData = withData
        self.fileRecordingInfo = recordingInfo
    }//: INIT
    
}//: ARDocument

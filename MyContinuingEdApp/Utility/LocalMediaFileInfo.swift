//
//  LocalMediaFileInfo.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/22/26.
//

import CloudKit
import Foundation


final class LocalMediaFileInfo: NSObject, NSSecureCoding, Identifiable {
   // MARK: - PROPERTIES
    private(set) var id: CKRecord.ID
    var mediaURL: URL?
    var errorMessage: String = ""
    private var needsManualDownload: Bool = false
    private var needsManualDeletion: Bool = false
    
    static var supportsSecureCoding: Bool = true
    
    // MARK: - COMPUTED PROPERTIES
    
    var hasError: Bool {
        errorMessage.isNotEmpty
    }//: hasError
    var shouldReDownload: Bool {
        get {
            needsManualDownload
        }
        set {
            needsManualDownload = newValue
        }
    }//: shouldReDownload
    var shouldDelete: Bool {
        get {
            needsManualDeletion
        }
        set {
            needsManualDeletion = newValue
        }
    }//: shouldDelete
    
    // MARK: - METHODS
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(mediaURL, forKey: "url")
        coder.encode(errorMessage, forKey: "error")
        coder.encode(needsManualDeletion, forKey: "manDeletion")
        coder.encode(needsManualDownload, forKey: "manDownload")
    }//: encode(coder)
    
    
    // MARK: - INIT
    
    init(
        id: CKRecord.ID,
        mediaURL: URL?,
        errorMessage: String = "",
        manualDownload: Bool = false,
        manualDeletion: Bool = false
    ) {
        self.id = id
        self.mediaURL = mediaURL
        self.errorMessage = errorMessage
        self.needsManualDeletion = manualDeletion
        self.needsManualDownload = manualDownload
    }//: INIT
    
    init?(coder decoder: NSCoder) {
        if let recKey = decoder.decodeObject(forKey: "id") as? CKRecord.ID {
            self.id = recKey
        } else {
            self.id = CKRecord.ID(recordName: String.emptyRecName)
        }//: IF LET ELSE (recKey)
        
        if let savedURL = decoder.decodeObject(forKey: "url") as? URL {
            self.mediaURL = savedURL
        }//: IF LET (savedURL)
        
        if let savedError = decoder.decodeObject(forKey: "error") as? String {
            self.errorMessage = savedError
        } else {
            self.errorMessage = ""
        }//: IF LET (savedError)
        
        if let savedDownloadFlag = decoder.decodeObject(forKey: "manDownload") as? Bool {
            self.needsManualDownload = savedDownloadFlag
        }//: IF LET (savedDownloadFlag)
        
        if let savedDeletionFlag = decoder.decodeObject(forKey: "manDeletion") as? Bool {
            self.needsManualDeletion = savedDeletionFlag
        }//: IF LET
        
    }//: INIT
    
}//: CLASS

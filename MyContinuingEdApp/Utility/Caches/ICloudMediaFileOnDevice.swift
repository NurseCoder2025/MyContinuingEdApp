//
//  LocalMediaFileInfo.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/22/26.
//

import CloudKit
import Foundation


final class ICloudMediaFileOnDevice: NSObject, NSSecureCoding, Identifiable {
   // MARK: - PROPERTIES
    private(set) var id: CKRecord.ID
    private(set) var recType: CkRecordType
    private(set) var keepOnDevice: Bool
    
    var mediaURL: URL?
    var errorMessage: String = ""
    private var needsManualDownload: Bool = false
    private var needsManualDeletion: Bool = false
    
    static var supportsSecureCoding: Bool = true
    
    // MARK: - KEYS
    enum RecordKey: String, CodingKey {
        case id, recType, uploadedBy, url, error, manDeletion, manDownload
    }//: CodingKeys
    
    let idKey = RecordKey.id.rawValue
    let typeKey = RecordKey.recType.rawValue
    let uploadKey = RecordKey.uploadedBy.rawValue
    let urlKey = RecordKey.url.rawValue
    let errorKey = RecordKey.error.rawValue
    let deletionKey = RecordKey.manDeletion.rawValue
    let downloadKey = RecordKey.manDownload.rawValue
    
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
        coder.encode(id, forKey: idKey)
        coder.encode(recType, forKey: typeKey)
        coder.encode(keepOnDevice, forKey: uploadKey)
        coder.encode(mediaURL, forKey: urlKey)
        coder.encode(errorMessage, forKey: errorKey)
        coder.encode(needsManualDeletion, forKey: deletionKey)
        coder.encode(needsManualDownload, forKey: downloadKey)
    }//: encode(coder)
    
    
    // MARK: - INIT
    
    init(
        id: CKRecord.ID,
        recType: CkRecordType,
        keepOnDevice: Bool,
        mediaURL: URL?,
        errorMessage: String = "",
        manualDownload: Bool = false,
        manualDeletion: Bool = false
    ) {
        self.id = id
        self.recType = recType
        self.keepOnDevice = keepOnDevice
        self.mediaURL = mediaURL
        self.errorMessage = errorMessage
        self.needsManualDeletion = manualDeletion
        self.needsManualDownload = manualDownload
    }//: INIT
    
    init?(coder decoder: NSCoder) {
        if let recKey = decoder.decodeObject(forKey: idKey) as? CKRecord.ID {
            self.id = recKey
        } else {
            self.id = CKRecord.ID(recordName: String.emptyRecName)
        }//: IF LET ELSE (recKey)
        
        if let recTypeKey = decoder.decodeObject(forKey: typeKey) as? CkRecordType {
            self.recType = recTypeKey
        }//: IF LET (recTypeKey)
        
        if let uploadedByKey = decoder.decodeObject(forKey: uploadKey) as? Bool {
            self.keepOnDevice = uploadedByKey
        }//: IF LET (uploadedByKey)
        
        if let savedURL = decoder.decodeObject(forKey: urlKey) as? URL {
            self.mediaURL = savedURL
        }//: IF LET (savedURL)
        
        if let savedError = decoder.decodeObject(forKey: errorKey) as? String {
            self.errorMessage = savedError
        } else {
            self.errorMessage = ""
        }//: IF LET (savedError)
        
        if let savedDownloadFlag = decoder.decodeObject(forKey: downloadKey) as? Bool {
            self.needsManualDownload = savedDownloadFlag
        }//: IF LET (savedDownloadFlag)
        
        if let savedDeletionFlag = decoder.decodeObject(forKey: deletionKey) as? Bool {
            self.needsManualDeletion = savedDeletionFlag
        }//: IF LET
        
    }//: INIT
    
}//: CLASS

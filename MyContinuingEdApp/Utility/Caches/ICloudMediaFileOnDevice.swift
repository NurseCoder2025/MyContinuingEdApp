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
    private var originatedOnDevice: Bool
    
    var mediaURL: URL?
    var errorMessage: String = ""
    private var needsManualDownload: Bool = false
    private var needsAutoDownloadRetry: Bool = false
    private var needsManualDeletion: Bool = false
    private var needsUploadRetry: Bool = false
    
    static var supportsSecureCoding: Bool = true
    
    // MARK: - KEYS
    enum RecordKey: String, CodingKey {
        case id, recType, origin, url, error, manDeletion, manDownload, downloadRetry, uploadRetry
    }//: CodingKeys
    
    private let idKey = RecordKey.id.rawValue
    private let typeKey = RecordKey.recType.rawValue
    private let originKey = RecordKey.origin.rawValue
    private let urlKey = RecordKey.url.rawValue
    private let errorKey = RecordKey.error.rawValue
    private let deletionKey = RecordKey.manDeletion.rawValue
    private let downloadKey = RecordKey.manDownload.rawValue
    private let retryKey = RecordKey.downloadRetry.rawValue
    private let reUploadKey = RecordKey.uploadRetry.rawValue
    
    // MARK: - COMPUTED PROPERTIES
    
    var hasError: Bool { errorMessage.isNotEmpty }//: hasError
    
    // MARK: GETTERS & SETTERS
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
    var willRetryAutoDownload: Bool {
        get {
            needsAutoDownloadRetry
        }
        set {
            needsAutoDownloadRetry = newValue
        }
    }//: willRetryAutoDownload
    var fileOriginatedOnThisDevice: Bool { originatedOnDevice }//: fileOriginatedOnThisDevice
    var shouldRetryUpload: Bool {
        get {
            needsUploadRetry
        }
        set {
            needsUploadRetry = newValue
        }
    }//: shouldRetryUpload
    
    
    // MARK: - METHODS
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: idKey)
        coder.encode(recType, forKey: typeKey)
        coder.encode(originatedOnDevice, forKey: originKey)
        coder.encode(mediaURL, forKey: urlKey)
        coder.encode(errorMessage, forKey: errorKey)
        coder.encode(needsManualDeletion, forKey: deletionKey)
        coder.encode(needsManualDownload, forKey: downloadKey)
        coder.encode(needsAutoDownloadRetry, forKey: retryKey)
        coder.encode(needsUploadRetry, forKey: reUploadKey)
    }//: encode(coder)
    
    func updateRecType(to: CkRecordType) { recType = to } //: updateRecType(to)
    func changeFileOrigination(to: Bool) { originatedOnDevice = to }//: changeFileOrigination()
    
    
    // MARK: - INIT
    
    init(
        id: CKRecord.ID,
        recType: CkRecordType,
        originatedOnDevice: Bool,
        mediaURL: URL?,
        errorMessage: String = "",
        manualDownload: Bool = false,
        manualDeletion: Bool = false,
        retryUpload: Bool = false
    ) {
        self.id = id
        self.recType = recType
        self.originatedOnDevice = originatedOnDevice
        self.mediaURL = mediaURL
        self.errorMessage = errorMessage
        self.needsManualDeletion = manualDeletion
        self.needsManualDownload = manualDownload
        self.needsAutoDownloadRetry = retryUpload
    }//: INIT
    
    init?(coder decoder: NSCoder) {
        if let recKey = decoder.decodeObject(forKey: idKey) as? CKRecord.ID {
            self.id = recKey
        } else {
            self.id = CKRecord.ID(recordName: String.emptyRecName)
        }//: IF LET ELSE (recKey)
        
        if let recTypeKey = decoder.decodeObject(forKey: typeKey) as? CkRecordType {
            self.recType = recTypeKey
        } else {
            self.recType = .certificate
        }//: IF LET (recTypeKey)
        
        if let uploadedByKey = decoder.decodeObject(forKey: originKey) as? Bool {
            self.originatedOnDevice = uploadedByKey
        } else {
            self.originatedOnDevice = false
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
        
        if let savedDownloadRetryFlag = decoder.decodeObject(forKey: retryKey) as? Bool {
            self.needsAutoDownloadRetry = savedDownloadRetryFlag
        }//: IF LET (savedDownloadRetryFlag)
        
        if let uploadAfterErrorFlag = decoder.decodeObject(forKey: reUploadKey) as? Bool {
            self.needsUploadRetry = uploadAfterErrorFlag
        }//: IF lET (uploadAfterErrorFlag)
        
    }//: INIT
    
}//: CLASS

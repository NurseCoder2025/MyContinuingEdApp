//
//  MasterMediaList.swift
//  MyContinuingEdApp
//
//  Created by Ilum on 4/22/26.
//

import CloudKit
import Foundation


final class MasterMediaList: @unchecked Sendable {
    // MARK: - PROPERTIES
    private var _allLocalMedia = Set<LocalMediaFileInfo>() {
        willSet {
            dispatchPrecondition(condition: .onQueue(queue))
        }
    }//: _allLocalMedia
    
    private let listLocation: URL = URL.applicationSupportDirectory.appending(component: "MasterMediaList.archive", directoryHint: .notDirectory)
    
    private let queue = DispatchQueue(label: "com.CeCache.masterMediaList", qos: .utility)
    
    
    // MARK: - SINGLETON
    
    static let shared = MasterMediaList()
    
    // MARK: - GETTERS
    
    var currentLocalMediaFiles: [LocalMediaFileInfo] {
        queue.sync { Array(_allLocalMedia) }
    }//: localMediaList
    
    var localMediaErrors: [LocalMediaFileInfo] {
        queue.sync {
            return _allLocalMedia.filter { $0.hasError }
        }//: sync
    }//: localMediaErrors
    
    // MARK: - METHODS
    
    func addMediaRecord(fromRec record: CKRecord.ID, savedAt: URL)  {
        guard doesNOThaveRecord(withID: record) else { return }
        queue.async {
            let newItem = LocalMediaFileInfo(id: record, mediaURL: savedAt)
            self._allLocalMedia.insert(newItem)
        }//: async
    }//: addMediaRecord(fromRec, savedAt)
    
    func addMediaRecWithError(
        fromRec record: CKRecord.ID,
        message: String,
        downloadFlag: Bool? = nil,
        deletionFlag: Bool? = nil
    ) {
        guard doesNOThaveRecord(withID: record) else {
            queue.async {
                if let existingRec = self.getLocalMediaRecord(using: record) {
                    existingRec.errorMessage = message
                    
                    if let needsDownload = downloadFlag {
                        existingRec.shouldReDownload = needsDownload
                    }//: IF LET
                    
                    if let needsDeletion = deletionFlag {
                        existingRec.shouldDelete = needsDeletion
                    }//: IF LET
                    
                }//: IF LET
            }//: async
            return
        }//: GUARD
        queue.async {
            let newItem = LocalMediaFileInfo(id: record, mediaURL: nil, errorMessage: message)
            
            if let needsDownload = downloadFlag {
                newItem.shouldReDownload = needsDownload
            }//: IF LET
            
            if let needsDeletion = deletionFlag {
                newItem.shouldDelete = needsDeletion
            }//: IF LET
            
            self._allLocalMedia.insert(newItem)
        }//: async
    }//: addMediaRecWithError(fromRec, message)
    
    func updateMediaRecWithError(
        fromRec record: CKRecord.ID,
        message: String,
        downloadFlag: Bool? = nil,
        deleteFlag: Bool? = nil
    ) {
        guard hasRecord(withID: record) else { return }
        
        queue.async {
            if let itemToUpdate = self.getLocalMediaRecord(using: record) {
                itemToUpdate.errorMessage = message
                if let setDownloadFlag = downloadFlag {
                    itemToUpdate.shouldReDownload = setDownloadFlag
                }//: IF LET (setDownloadFlag)
                
                if let setDeletionFlag = deleteFlag {
                    itemToUpdate.shouldDelete = setDeletionFlag
                }//: IF LET
            }//: IF LET
        }//: async
    }//: updateMediaRecWithError(fromRec, message)
    
    func getLocalMediaRecord(using record: CKRecord.ID) -> LocalMediaFileInfo?  {
        queue.sync {
            return _allLocalMedia.filter({$0.id == record}).first
        }//: sync
    }//: getLocalMediaRecord(using)
    
    func removeMediaUrl(forRec: CKRecord.ID)  {
        queue.async {
            if let itemWithNoMedia = self._allLocalMedia.filter({$0.id == forRec}).first {
                itemWithNoMedia.mediaURL = nil
            }//: IF LET
        }//: async
    }//: removeMediaUrl(forRec)
    
    func changeMediaUrl(forRec: CKRecord.ID, to newURL: URL)  {
        guard let itemToUpdate = _allLocalMedia.filter({$0.id == forRec}).first else { return }
        queue.async {
            itemToUpdate.mediaURL = newURL
        }//: async
    }//: changeMediaUrl(forRec, to newURL)
    
    func removeMediaRecord(withID: CKRecord.ID) {
        if let memberToRemove = _allLocalMedia.filter({$0.id == withID}).first {
            queue.async {
                self._allLocalMedia.remove(memberToRemove)
            }//: async
        }//: IF LET
    }//: removeExistingItem
    
    func hasRecord(withID recID: CKRecord.ID) -> Bool {
        queue.sync { _allLocalMedia.contains(where: {$0.id == recID}) }
    }//: hasRecord(recID)
    
    func doesNOThaveRecord(withID recID: CKRecord.ID) -> Bool {
        queue.sync { !_allLocalMedia.contains(where: {$0.id == recID}) }
    }//: doesNOThaveRecord(withID)
    
    
    // MARK: DISK READING/WRITING
    func saveList(repeatCount: Int = 0)  {
        queue.async {
            Task{
                let archiver = NSKeyedArchiver(requiringSecureCoding: true)
                archiver.encode(self._allLocalMedia, forKey: String.masterMediaListFileKey)
                archiver.finishEncoding()
                let encodedData = archiver.encodedData
                do {
                    _ = try encodedData.write(to: self.listLocation)
                } catch {
                    if repeatCount < 3 {
                        try? await Task.sleep(for: .seconds(0.1))
                        self.saveList(repeatCount: repeatCount + 1)
                    } else {
                        NSLog(">>> MasterMediaList error: saveList()")
                        NSLog(">>> Unable to write the encoded data to disk after 3 failed attempts because:")
                        NSLog("\(error.localizedDescription)")
                    }//: IF ELSE
                }//: DO-CATCH
            }//: TASK
        }//: async
    }//: saveList()
    
    func decodeCurrentList() {
        queue.sync {
            if let savedList = try? Data(contentsOf: listLocation) {
                do {
                    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: savedList)
                    unarchiver.requiresSecureCoding = true
                    if let decodedMedia: Set<LocalMediaFileInfo> = unarchiver.decodeObject(forKey: String.masterMediaListFileKey) as? Set<LocalMediaFileInfo> {
                        _allLocalMedia = decodedMedia
                    }//: IF LET (decodedMedia)
                } catch {
                    NSLog(">>> MasterMediaList error: init")
                    NSLog(">>> The NSKeyedUnarchiver(forReadingFrom) method threw an error while being initialized.")
                    NSLog(">>> Error details: \(error.localizedDescription)")
                }//: DO-CATCH
            }//: IF LET
        }//: SYNC
    }//: decodeCurrentList()
    

    // MARK: - INITS
    
    private init() {
        if let _ = (try? Data(contentsOf: listLocation)) {
            decodeCurrentList()
        }//: IF LET
    }//: INIT
     
}//: MasterMediaList

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
    private var _allLocalMedia = [LocalMediaFileInfo]() {
        willSet {
            dispatchPrecondition(condition: .onQueue(queue))
        }
    }//: _allLocalMedia
    
    let listLocation: URL = URL.applicationSupportDirectory.appending(component: "MasterMediaList.archive", directoryHint: .notDirectory)
    
    private let queue = DispatchQueue(label: "com.CeCache.masterMediaList", qos: .utility)
    
    
    // MARK: - SINGLETON
    
    static let shared = MasterMediaList()
    
    // MARK: - GETTERS
    
    var currentLocalMediaFiles: [LocalMediaFileInfo] {
        queue.sync { _allLocalMedia }
    }//: localMediaList
    
    // MARK: - METHODS
    
    func addMediaRecord(fromRec: CKRecord.ID, savedAt: URL)  {
        let newItem = LocalMediaFileInfo(id: fromRec, mediaURL: savedAt)
        _allLocalMedia.append(newItem)
    }//: addMediaRecord(fromRec, savedAt)
    
    func removeMediaUrl(forRec: CKRecord.ID)  {
        if let itemWithNoMedia = _allLocalMedia.filter({$0.id == forRec}).first {
            itemWithNoMedia.mediaURL = nil
        }//: IF LET
    }//: removeMediaUrl(forRec)
    
    func changeMediaUrl(forRec: CKRecord.ID, to newURL: URL)  {
        guard let itemToUpdate = _allLocalMedia.filter({$0.id == forRec}).first else { return }
            itemToUpdate.mediaURL = newURL
    }//: changeMediaUrl(forRec, to newURL)
    
    func removeMediaRecord(withID: CKRecord.ID) {
        _allLocalMedia.removeAll(where: {$0.id == withID})
    }//: removeExistingItem
    
    
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
    
    func decodeCurrentState() {
        queue.sync {
            if let savedList = try? Data(contentsOf: listLocation) {
                do {
                    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: savedList)
                    unarchiver.requiresSecureCoding = true
                    if let decodedMedia: [LocalMediaFileInfo] = unarchiver.decodeObject(forKey: String.masterMediaListFileKey) as? [LocalMediaFileInfo] {
                        _allLocalMedia = decodedMedia
                    }
                } catch {
                    NSLog(">>> MasterMediaList error: init")
                    NSLog(">>> The NSKeyedUnarchiver(forReadingFrom) method threw an error while being initialized.")
                    NSLog(">>> Error details: \(error.localizedDescription)")
                }//: DO-CATCH
            }//: IF LET
        }//: SYNC
    }//: decodeCurrentState()
    

    // MARK: - INITS
    
    private init() {
        if let _ = (try? Data(contentsOf: listLocation)) {
            decodeCurrentState()
        }//: IF LET
    }//: INIT
     
}//: MasterMediaList
